#!/usr/bin/env python3
"""
OSM Algeria Extractor
=====================
Extrait les établissements d'OpenStreetMap pour l'Algérie et génère :
  - output/establishments.geojson  → données brutes (pour la carte)
  - output/import.sql              → SQL prêt à importer dans la DB

Usage:
  pip install -r requirements.txt
  python osm_extract.py

Options via variables d'environnement :
  OVERPASS_URL  (défaut : https://overpass-api.de/api/interpreter)
  MIN_NAME_LEN  (défaut : 2, ignore les noms trop courts)
"""

import json
import os
import re
import sys
import time
import unicodedata
import uuid
from datetime import datetime

import requests

# ============================================================
# CONFIGURATION
# ============================================================

OVERPASS_URL = os.getenv("OVERPASS_URL", "https://overpass-api.de/api/interpreter")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "output")
MIN_NAME_LEN = int(os.getenv("MIN_NAME_LEN", "2"))
REQUEST_TIMEOUT = 180   # secondes par requête Overpass
RETRY_DELAY    = 60     # secondes avant retry sur erreur 429 / 5xx
MAX_RETRIES    = 3

os.makedirs(OUTPUT_DIR, exist_ok=True)


# ============================================================
# 58 WILAYAS ALGÉRIENNES : code → {name_fr, name_ar, variants}
# ============================================================

WILAYAS = {
    "01": {"name": "Adrar",            "name_ar": "أدرار",         "variants": ["adrar"]},
    "02": {"name": "Chlef",            "name_ar": "الشلف",          "variants": ["chlef", "ech cheliff", "el asnam"]},
    "03": {"name": "Laghouat",         "name_ar": "الأغواط",        "variants": ["laghouat", "el aghouat"]},
    "04": {"name": "Oum El Bouaghi",   "name_ar": "أم البواقي",     "variants": ["oum el bouaghi", "oum el baoughi"]},
    "05": {"name": "Batna",            "name_ar": "باتنة",           "variants": ["batna"]},
    "06": {"name": "Béjaïa",           "name_ar": "بجاية",           "variants": ["bejaia", "béjaïa", "bejaia", "bgayet"]},
    "07": {"name": "Biskra",           "name_ar": "بسكرة",           "variants": ["biskra"]},
    "08": {"name": "Béchar",           "name_ar": "بشار",            "variants": ["bechar", "béchar"]},
    "09": {"name": "Blida",            "name_ar": "البليدة",         "variants": ["blida", "el boulaida"]},
    "10": {"name": "Bouira",           "name_ar": "البويرة",         "variants": ["bouira"]},
    "11": {"name": "Tamanrasset",      "name_ar": "تمنراست",         "variants": ["tamanrasset", "tamanghasset"]},
    "12": {"name": "Tébessa",          "name_ar": "تبسة",            "variants": ["tebessa", "tébessa"]},
    "13": {"name": "Tlemcen",          "name_ar": "تلمسان",          "variants": ["tlemcen", "tilimsen"]},
    "14": {"name": "Tiaret",           "name_ar": "تيارت",           "variants": ["tiaret"]},
    "15": {"name": "Tizi Ouzou",       "name_ar": "تيزي وزو",        "variants": ["tizi ouzou", "tizi-ouzou"]},
    "16": {"name": "Alger",            "name_ar": "الجزائر",         "variants": ["alger", "algiers", "el djazair", "el djazaïr"]},
    "17": {"name": "Djelfa",           "name_ar": "الجلفة",          "variants": ["djelfa"]},
    "18": {"name": "Jijel",            "name_ar": "جيجل",            "variants": ["jijel"]},
    "19": {"name": "Sétif",            "name_ar": "سطيف",            "variants": ["setif", "sétif"]},
    "20": {"name": "Saïda",            "name_ar": "سعيدة",           "variants": ["saida", "saïda"]},
    "21": {"name": "Skikda",           "name_ar": "سكيكدة",          "variants": ["skikda", "philippeville"]},
    "22": {"name": "Sidi Bel Abbès",   "name_ar": "سيدي بلعباس",    "variants": ["sidi bel abbes", "sidi bel abbès"]},
    "23": {"name": "Annaba",           "name_ar": "عنابة",           "variants": ["annaba", "bone", "bône"]},
    "24": {"name": "Guelma",           "name_ar": "قالمة",           "variants": ["guelma"]},
    "25": {"name": "Constantine",      "name_ar": "قسنطينة",         "variants": ["constantine", "qacentina"]},
    "26": {"name": "Médéa",            "name_ar": "المدية",          "variants": ["medea", "médéa"]},
    "27": {"name": "Mostaganem",       "name_ar": "مستغانم",         "variants": ["mostaganem"]},
    "28": {"name": "M'Sila",           "name_ar": "المسيلة",         "variants": ["msila", "m'sila", "m sila"]},
    "29": {"name": "Mascara",          "name_ar": "معسكر",           "variants": ["mascara"]},
    "30": {"name": "Ouargla",          "name_ar": "ورقلة",           "variants": ["ouargla", "wargla"]},
    "31": {"name": "Oran",             "name_ar": "وهران",           "variants": ["oran", "wahran"]},
    "32": {"name": "El Bayadh",        "name_ar": "البيض",           "variants": ["el bayadh"]},
    "33": {"name": "Illizi",           "name_ar": "إليزي",           "variants": ["illizi"]},
    "34": {"name": "Bordj Bou Arréridj","name_ar": "برج بوعريريج",  "variants": ["bordj bou arreridj", "bordj bou arréridj", "bba"]},
    "35": {"name": "Boumerdès",        "name_ar": "بومرداس",         "variants": ["boumerdes", "boumerdès"]},
    "36": {"name": "El Tarf",          "name_ar": "الطارف",          "variants": ["el tarf"]},
    "37": {"name": "Tindouf",          "name_ar": "تندوف",           "variants": ["tindouf"]},
    "38": {"name": "Tissemsilt",       "name_ar": "تيسمسيلت",        "variants": ["tissemsilt"]},
    "39": {"name": "El Oued",          "name_ar": "الوادي",          "variants": ["el oued", "eloued"]},
    "40": {"name": "Khenchela",        "name_ar": "خنشلة",           "variants": ["khenchela"]},
    "41": {"name": "Souk Ahras",       "name_ar": "سوق أهراس",       "variants": ["souk ahras"]},
    "42": {"name": "Tipaza",           "name_ar": "تيبازة",          "variants": ["tipaza", "tipasa"]},
    "43": {"name": "Mila",             "name_ar": "ميلة",            "variants": ["mila"]},
    "44": {"name": "Aïn Defla",        "name_ar": "عين الدفلى",      "variants": ["ain defla", "aïn defla"]},
    "45": {"name": "Naâma",            "name_ar": "النعامة",         "variants": ["naama", "naâma"]},
    "46": {"name": "Aïn Témouchent",   "name_ar": "عين تموشنت",      "variants": ["ain temouchent", "aïn témouchent"]},
    "47": {"name": "Ghardaïa",         "name_ar": "غرداية",          "variants": ["ghardaia", "ghardaïa"]},
    "48": {"name": "Relizane",         "name_ar": "غليزان",          "variants": ["relizane"]},
    "49": {"name": "Timimoun",         "name_ar": "تيميمون",         "variants": ["timimoun"]},
    "50": {"name": "Bordj Badji Mokhtar","name_ar":"برج باجي مختار", "variants": ["bordj badji mokhtar", "bbm"]},
    "51": {"name": "Ouled Djellal",    "name_ar": "أولاد جلال",      "variants": ["ouled djellal"]},
    "52": {"name": "Béni Abbès",       "name_ar": "بني عباس",        "variants": ["beni abbes", "béni abbès"]},
    "53": {"name": "In Salah",         "name_ar": "عين صالح",        "variants": ["in salah"]},
    "54": {"name": "In Guezzam",       "name_ar": "عين قزام",        "variants": ["in guezzam"]},
    "55": {"name": "Touggourt",        "name_ar": "تقرت",            "variants": ["touggourt"]},
    "56": {"name": "Djanet",           "name_ar": "جانت",            "variants": ["djanet"]},
    "57": {"name": "El M'Ghair",       "name_ar": "المغير",          "variants": ["el m'ghair", "el mghair"]},
    "58": {"name": "El Meniaa",        "name_ar": "المنيعة",         "variants": ["el meniaa", "el ménéa"]},
}

def _normalize(s: str) -> str:
    """Normalise une chaîne pour la comparaison (lowercase, sans accents)."""
    s = s.lower().strip()
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"[^a-z0-9\s]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


# Lookup rapide : nom normalisé → code wilaya
_WILAYA_LOOKUP: dict[str, str] = {}
for _code, _w in WILAYAS.items():
    for _v in _w["variants"]:
        _WILAYA_LOOKUP[_normalize(_v)] = _code


# ============================================================
# MAPPING OSM TAGS → CATÉGORIES / SOUS-CATÉGORIES
# ============================================================
# Format : (tag_key, tag_value) → (category_slug, subcategory_slug | None)
# L'ordre compte : premier match gagne.

OSM_TAG_MAP: list[tuple[tuple[str, str], tuple[str, str | None]]] = [

    # ── RESTAURANTS ─────────────────────────────────────────
    (("amenity", "restaurant"),    ("restaurants", "restaurant-traditionnel")),
    (("amenity", "fast_food"),     ("restaurants", "fast-food")),
    (("amenity", "pizza"),         ("restaurants", "pizzeria")),
    (("amenity", "cafe"),          ("restaurants", "cafe-salon-the")),
    (("amenity", "bar"),           ("restaurants", "cafe-salon-the")),
    (("amenity", "pub"),           ("restaurants", "cafe-salon-the")),
    (("amenity", "ice_cream"),     ("restaurants", "patisserie")),
    (("amenity", "juice_bar"),     ("restaurants", "cafe-salon-the")),
    (("amenity", "food_court"),    ("restaurants", None)),
    (("shop",    "pastry"),        ("restaurants", "patisserie")),
    (("shop",    "confectionery"), ("restaurants", "patisserie")),
    (("shop",    "chocolate"),     ("restaurants", "patisserie")),

    # ── BEAUTÉ & BIEN-ÊTRE ───────────────────────────────────
    (("shop",    "hairdresser"),   ("beaute-bien-etre", "coiffure-homme")),
    (("amenity", "hairdresser"),   ("beaute-bien-etre", "coiffure-homme")),
    (("shop",    "beauty"),        ("beaute-bien-etre", "institut-beaute")),
    (("amenity", "beauty"),        ("beaute-bien-etre", "institut-beaute")),
    (("amenity", "spa"),           ("beaute-bien-etre", "spa-hammam")),
    (("leisure", "sauna"),         ("beaute-bien-etre", "spa-hammam")),
    (("shop",    "cosmetics"),     ("beaute-bien-etre", "institut-beaute")),
    (("amenity", "massage"),       ("beaute-bien-ete",  "massage")),

    # ── SANTÉ ────────────────────────────────────────────────
    (("amenity", "hospital"),      ("sante", "clinique")),
    (("amenity", "clinic"),        ("sante", "clinique")),
    (("amenity", "doctors"),       ("sante", "medecin-generaliste")),
    (("amenity", "pharmacy"),      ("sante", "pharmacie")),
    (("amenity", "dentist"),       ("sante", "dentiste")),
    (("amenity", "optician"),      ("sante", "ophtalmologue")),
    (("shop",    "optician"),      ("sante", "ophtalmologue")),
    (("healthcare", "laboratory"), ("sante", "laboratoire-analyses")),
    (("healthcare", "physiotherapist"), ("sante", "kinesitherapeute")),
    (("amenity", "nursing_home"),  ("sante", None)),
    (("amenity", "veterinary"),    ("sante", None)),

    # ── AUTOMOBILE ───────────────────────────────────────────
    (("amenity", "car_rental"),    ("automobile", "location-voitures")),
    (("shop",    "car_rental"),    ("automobile", "location-voitures")),
    (("amenity", "car_repair"),    ("automobile", "garage-mecanique")),
    (("shop",    "car_repair"),    ("automobile", "garage-mecanique")),
    (("amenity", "car_wash"),      ("automobile", "lavage-auto")),
    (("shop",    "car_parts"),     ("automobile", "pieces-detachees")),
    (("amenity", "fuel"),          ("automobile", "station-service")),
    (("shop",    "tyres"),         ("automobile", "pneus")),
    (("shop",    "car"),           ("automobile", None)),

    # ── HÉBERGEMENT ──────────────────────────────────────────
    (("tourism", "hotel"),         ("hebergement", "hotel")),
    (("amenity", "hotel"),         ("hebergement", "hotel")),
    (("tourism", "hostel"),        ("hebergement", "auberge")),
    (("tourism", "guest_house"),   ("hebergement", "maison-hotes")),
    (("tourism", "apartment"),     ("hebergement", "appart-hotel")),
    (("tourism", "chalet"),        ("hebergement", "location-vacances")),
    (("tourism", "motel"),         ("hebergement", "hotel")),
    (("tourism", "camp_site"),     ("hebergement", "location-vacances")),

    # ── ACTIVITÉS & LOISIRS ──────────────────────────────────
    (("leisure", "fitness_centre"),  ("activites-loisirs", "salle-sport")),
    (("leisure", "sports_centre"),   ("activites-loisirs", "salle-sport")),
    (("amenity", "gym"),             ("activites-loisirs", "salle-sport")),
    (("leisure", "swimming_pool"),   ("activites-loisirs", "piscine")),
    (("leisure", "sports_club"),     ("activites-loisirs", "club-football")),
    (("amenity", "cinema"),          ("activites-loisirs", "cinema")),
    (("leisure", "amusement_arcade"),("activites-loisirs", "salle-jeux")),
    (("leisure", "water_park"),      ("activites-loisirs", "parc-attractions")),
    (("leisure", "park"),            ("activites-loisirs", None)),
    (("leisure", "beach"),           ("activites-loisirs", "plage-privee")),
    (("leisure", "playground"),      ("activites-loisirs", None)),
    (("tourism", "theme_park"),      ("activites-loisirs", "parc-attractions")),
    (("tourism", "zoo"),             ("activites-loisirs", None)),

    # ── MAISON & SERVICES ────────────────────────────────────
    (("craft",   "plumber"),         ("maison-services", "plombier")),
    (("craft",   "electrician"),     ("maison-services", "electricien")),
    (("craft",   "carpenter"),       ("maison-services", "menuisier")),
    (("craft",   "painter"),         ("maison-services", "peintre")),
    (("craft",   "hvac"),            ("maison-services", "climatisation")),
    (("craft",   "cleaning"),        ("maison-services", "service-menage")),
    (("amenity", "moving_company"),  ("maison-services", "demenagement")),
    (("shop",    "hardware"),        ("maison-services", None)),
    (("shop",    "furniture"),       ("maison-services", None)),

    # ── COMMERCES ────────────────────────────────────────────
    (("shop", "supermarket"),        ("commerces", "supermarche")),
    (("shop", "convenience"),        ("commerces", "epicerie")),
    (("shop", "grocery"),            ("commerces", "epicerie")),
    (("shop", "bakery"),             ("commerces", "boulangerie")),
    (("shop", "butcher"),            ("commerces", "boucherie")),
    (("shop", "electronics"),        ("commerces", "electromenager")),
    (("shop", "clothes"),            ("commerces", "vetements")),
    (("shop", "fashion"),            ("commerces", "vetements")),
    (("shop", "jewelry"),            ("commerces", "bijouterie")),
    (("shop", "books"),              ("commerces", "librairie")),
    (("shop", "mall"),               ("commerces", None)),
    (("shop", "department_store"),   ("commerces", None)),
    (("shop", "mobile_phone"),       ("commerces", None)),
    (("shop", "florist"),            ("commerces", None)),
    (("shop", "pharmacy"),           ("sante",     "pharmacie")),  # double tag parfois

    # ── ÉDUCATION ────────────────────────────────────────────
    (("amenity", "driving_school"),  ("education", "auto-ecole")),
    (("amenity", "language_school"), ("education", "ecole-langues")),
    (("amenity", "school"),          ("education", "ecole-privee")),
    (("amenity", "university"),      ("education", None)),
    (("amenity", "college"),         ("education", "centre-formation")),
    (("amenity", "kindergarten"),    ("education", "creche-garderie")),
    (("amenity", "childcare"),       ("education", "creche-garderie")),
    (("amenity", "training"),        ("education", "centre-formation")),
    (("amenity", "tutoring"),        ("education", "cours-particuliers")),

    # ── SERVICES PROFESSIONNELS ──────────────────────────────
    (("amenity", "lawyer"),          ("services-professionnels", "avocat")),
    (("office",  "lawyer"),          ("services-professionnels", "avocat")),
    (("amenity", "notary"),          ("services-professionnels", "notaire")),
    (("office",  "notary"),          ("services-professionnels", "notaire")),
    (("office",  "accountant"),      ("services-professionnels", "comptable")),
    (("office",  "insurance"),       ("services-professionnels", "assurance")),
    (("shop",    "estate_agent"),    ("services-professionnels", "agence-immobiliere")),
    (("office",  "estate_agent"),    ("services-professionnels", "agence-immobiliere")),
    (("office",  "architect"),       ("services-professionnels", "architecte")),
    (("shop",    "printing"),        ("services-professionnels", "imprimerie")),
    (("office",  "company"),         ("services-professionnels", None)),
    (("office",  "government"),      ("services-professionnels", None)),

    # ── VOYAGE & TOURISME ────────────────────────────────────
    (("shop",    "travel_agency"),   ("voyage-tourisme", "agence-voyage")),
    (("tourism", "travel_agent"),    ("voyage-tourisme", "agence-voyage")),
    (("tourism", "attraction"),      ("voyage-tourisme", "excursions")),
    (("tourism", "museum"),          ("voyage-tourisme", None)),
    (("tourism", "artwork"),         ("voyage-tourisme", None)),
    (("tourism", "viewpoint"),       ("voyage-tourisme", None)),
    (("amenity", "bus_station"),     ("voyage-tourisme", "location-bus")),

    # ── ÉVÉNEMENTS ───────────────────────────────────────────
    (("amenity", "events_venue"),    ("evenements", "salle-fetes")),
    (("amenity", "wedding_venue"),   ("evenements", "salle-fetes")),
    (("amenity", "conference_centre"),("evenements", "salle-fetes")),
    (("amenity", "theatre"),         ("evenements", None)),
]

# ── Cuisine → sous-catégorie (pour les restaurants) ─────────
CUISINE_SUBCAT = {
    "pizza":       "pizzeria",
    "seafood":     "restaurant-poisson",
    "fish":        "restaurant-poisson",
    "sushi":       "restaurant-asiatique",
    "chinese":     "restaurant-asiatique",
    "japanese":    "restaurant-asiatique",
    "thai":        "restaurant-asiatique",
    "asian":       "restaurant-asiatique",
    "kebab":       "fast-food",
    "burger":      "fast-food",
    "sandwich":    "fast-food",
    "algerian":    "restaurant-traditionnel",
    "regional":    "restaurant-traditionnel",
    "barbecue":    "grillades",
    "grill":       "grillades",
    "ice_cream":   "patisserie",
    "cake":        "patisserie",
    "coffee_shop": "cafe-salon-the",
    "tea":         "cafe-salon-the",
}


# ============================================================
# OVERPASS API : REQUÊTES SEGMENTÉES PAR TYPE
# ============================================================

def _build_query(amenity_filter: str) -> str:
    """Génère une requête Overpass pour l'Algérie."""
    return f"""
[out:json][timeout:{REQUEST_TIMEOUT}][maxsize:536870912];
area["ISO3166-1"="DZ"][admin_level=2]->.dz;
(
  node{amenity_filter}(area.dz);
  way{amenity_filter}(area.dz);
  relation{amenity_filter}(area.dz);
);
out center tags;
""".strip()


# Chaque tuple = (label, filtre Overpass)
OVERPASS_QUERIES: list[tuple[str, str]] = [
    ("restaurants",        '["amenity"~"^(restaurant|fast_food|cafe|bar|pub|ice_cream|juice_bar|food_court)$"]'),
    ("boulangeries",       '["shop"~"^(bakery|pastry|confectionery|chocolate)$"]'),
    ("beaute",             '["shop"~"^(hairdresser|beauty|cosmetics)$"]'),
    ("beaute_amenity",     '["amenity"~"^(hairdresser|beauty|spa|massage)$"]'),
    ("hammam",             '["leisure"="sauna"]'),
    ("sante",              '["amenity"~"^(hospital|clinic|doctors|pharmacy|dentist|optician|nursing_home|veterinary)$"]'),
    ("sante_shop",         '["shop"~"^(optician|pharmacy)$"]'),
    ("sante_hc",           '["healthcare"]'),
    ("automobile",         '["amenity"~"^(car_rental|car_repair|car_wash|fuel)$"]'),
    ("auto_shop",          '["shop"~"^(car_rental|car_repair|car_parts|tyres|car)$"]'),
    ("hebergement",        '["tourism"~"^(hotel|hostel|guest_house|apartment|chalet|motel|camp_site)$"]'),
    ("hebergement_amenity",'["amenity"="hotel"]'),
    ("loisirs",            '["leisure"~"^(fitness_centre|sports_centre|swimming_pool|sports_club|amusement_arcade|water_park|beach|playground|park)$"]'),
    ("cinema",             '["amenity"~"^(cinema|theatre|gym)$"]'),
    ("tourism_leisure",    '["tourism"~"^(theme_park|zoo|attraction|museum|artwork|viewpoint)$"]'),
    ("maison_craft",       '["craft"~"^(plumber|electrician|carpenter|painter|hvac|cleaning)$"]'),
    ("maison_shop",        '["shop"~"^(hardware|furniture)$"]'),
    ("commerces",          '["shop"~"^(supermarket|convenience|grocery|butcher|electronics|clothes|fashion|jewelry|books|mall|department_store|mobile_phone|florist)$"]'),
    ("education",          '["amenity"~"^(driving_school|language_school|school|university|college|kindergarten|childcare|training|tutoring)$"]'),
    ("services_office",    '["office"~"^(lawyer|notary|accountant|insurance|estate_agent|architect|company|government)$"]'),
    ("services_amenity",   '["amenity"~"^(lawyer|notary|moving_company|bus_station|events_venue|wedding_venue|conference_centre)$"]'),
    ("services_shop",      '["shop"~"^(estate_agent|printing|travel_agency)$"]'),
    ("tourisme_voyage",    '["shop"="travel_agency"]'),
    ("evenements",         '["amenity"~"^(events_venue|wedding_venue|conference_centre)$"]'),
]


def query_overpass(label: str, amenity_filter: str) -> list[dict]:
    """Envoie une requête Overpass et retourne la liste d'éléments."""
    query = _build_query(amenity_filter)
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            print(f"  [{label}] Requête Overpass... (tentative {attempt})")
            resp = requests.post(
                OVERPASS_URL,
                data={"data": query},
                timeout=REQUEST_TIMEOUT + 30,
            )
            if resp.status_code == 429 or resp.status_code >= 500:
                print(f"  [{label}] Erreur {resp.status_code}, attente {RETRY_DELAY}s...")
                time.sleep(RETRY_DELAY)
                continue
            resp.raise_for_status()
            data = resp.json()
            elements = data.get("elements", [])
            print(f"  [{label}] {len(elements)} éléments reçus.")
            return elements
        except requests.exceptions.Timeout:
            print(f"  [{label}] Timeout, attente {RETRY_DELAY}s...")
            time.sleep(RETRY_DELAY)
        except Exception as e:
            print(f"  [{label}] Erreur : {e}")
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_DELAY)
    print(f"  [{label}] Abandon après {MAX_RETRIES} tentatives.")
    return []


# ============================================================
# MAPPING OSM → STRUCTURE APP
# ============================================================

def map_category(tags: dict) -> tuple[str, str | None] | None:
    """Retourne (cat_slug, subcat_slug|None) ou None si non mappable."""
    for (key, val), (cat, subcat) in OSM_TAG_MAP:
        tag_val = tags.get(key, "")
        if tag_val == val:
            # Raffiner sous-catégorie restaurant avec cuisine=
            if cat == "restaurants" and subcat == "restaurant-traditionnel":
                cuisine = tags.get("cuisine", "").lower().split(";")[0].strip()
                if cuisine in CUISINE_SUBCAT:
                    subcat = CUISINE_SUBCAT[cuisine]
            return (cat, subcat)
    return None


def extract_name(tags: dict) -> str | None:
    """Extrait le nom (FR prioritaire, puis AR, puis international)."""
    for key in ("name:fr", "name", "name:ar", "name:en", "int_name"):
        v = tags.get(key, "").strip()
        if v and len(v) >= MIN_NAME_LEN:
            return v
    return None


def extract_name_ar(tags: dict) -> str | None:
    return tags.get("name:ar", "").strip() or None


def extract_wilaya_code(tags: dict) -> str | None:
    """Tente de retrouver le code wilaya depuis les tags OSM."""
    candidates = [
        tags.get("addr:state", ""),
        tags.get("addr:province", ""),
        tags.get("is_in:state", ""),
        tags.get("addr:state_code", ""),
        tags.get("is_in", ""),
    ]
    for raw in candidates:
        if not raw:
            continue
        norm = _normalize(raw)
        # Correspondance directe
        if norm in _WILAYA_LOOKUP:
            return _WILAYA_LOOKUP[norm]
        # Correspondance partielle (le champ peut contenir "Wilaya d'Alger, Algérie")
        for variant, code in _WILAYA_LOOKUP.items():
            if variant and variant in norm:
                return code
    return None


def extract_commune(tags: dict) -> str | None:
    for key in ("addr:city", "addr:suburb", "addr:district", "addr:village"):
        v = tags.get(key, "").strip()
        if v:
            return v
    return None


def extract_address(tags: dict, wilaya_code: str | None) -> str:
    """Construit une adresse lisible depuis les tags OSM."""
    parts = []
    if tags.get("addr:housenumber"):
        parts.append(tags["addr:housenumber"])
    if tags.get("addr:street"):
        parts.append(tags["addr:street"])
    if tags.get("addr:city") or tags.get("addr:suburb"):
        parts.append(tags.get("addr:city") or tags.get("addr:suburb", ""))
    if wilaya_code and wilaya_code in WILAYAS:
        parts.append(WILAYAS[wilaya_code]["name"])
    if not parts:
        parts.append("Algérie")
    return ", ".join(filter(None, parts))


def extract_phone(tags: dict) -> str | None:
    for key in ("phone", "contact:phone", "phone:mobile", "contact:mobile"):
        v = tags.get(key, "").strip()
        if v:
            return v[:20]
    return None


def extract_phone_secondary(tags: dict) -> str | None:
    """Retourne le 2ème numéro de téléphone si différent du principal."""
    primary = extract_phone(tags)
    for key in ("phone_2", "phone:mobile", "contact:mobile", "contact:phone_2"):
        v = tags.get(key, "").strip()
        if v and v != primary:
            return v[:20]
    return None


def extract_whatsapp(tags: dict) -> str | None:
    for key in ("contact:whatsapp", "whatsapp"):
        v = tags.get(key, "").strip()
        if v:
            return v[:20]
    return None


def extract_website(tags: dict) -> str | None:
    for key in ("website", "contact:website", "url"):
        v = tags.get(key, "").strip()
        if v and v.startswith("http"):
            return v[:500]
    return None


def extract_facebook(tags: dict) -> str | None:
    for key in ("contact:facebook", "facebook"):
        v = tags.get(key, "").strip()
        if v:
            # Normaliser en URL complète
            if v.startswith("http"):
                return v[:500]
            if "/" not in v:
                return f"https://facebook.com/{v}"[:500]
            return v[:500]
    return None


def extract_instagram(tags: dict) -> str | None:
    for key in ("contact:instagram", "instagram"):
        v = tags.get(key, "").strip()
        if v:
            # Retourner le username (sans @)
            v = v.lstrip("@").replace("https://instagram.com/", "").replace("https://www.instagram.com/", "").strip("/")
            return v[:255]
    return None


def extract_tiktok(tags: dict) -> str | None:
    for key in ("contact:tiktok", "tiktok"):
        v = tags.get(key, "").strip()
        if v:
            v = v.lstrip("@").replace("https://tiktok.com/@", "").replace("https://www.tiktok.com/@", "").strip("/")
            return v[:255]
    return None


def extract_description(tags: dict) -> str | None:
    for key in ("description", "description:fr", "note"):
        v = tags.get(key, "").strip()
        if v and len(v) > 10:
            return v[:2000]
    return None


def extract_address_ar(tags: dict) -> str | None:
    parts = []
    if tags.get("addr:housenumber"):
        parts.append(tags["addr:housenumber"])
    for key in ("addr:street:ar", "addr:street"):
        v = tags.get(key, "").strip()
        if v:
            parts.append(v)
            break
    for key in ("addr:city:ar", "addr:city"):
        v = tags.get(key, "").strip()
        if v:
            parts.append(v)
            break
    return ", ".join(filter(None, parts)) or None


def extract_amenities(tags: dict) -> list[str]:
    """Extrait les équipements depuis les tags OSM (wifi, parking, etc.)."""
    amenities = []
    checks = [
        ("internet_access",    ["wlan", "wifi", "yes"],      "WiFi"),
        ("wifi",               ["yes", "free"],               "WiFi"),
        ("internet_access:fee",["no"],                        "WiFi gratuit"),
        ("parking",            ["yes", "surface", "underground", "multi-storey"], "Parking"),
        ("amenity",            ["parking"],                   "Parking"),
        ("parking:fee",        ["no"],                        "Parking gratuit"),
        ("air_conditioning",   ["yes"],                       "Climatisation"),
        ("outdoor_seating",    ["yes"],                       "Terrasse"),
        ("wheelchair",         ["yes", "limited"],            "Accès PMR"),
        ("takeaway",           ["yes", "only"],               "Vente à emporter"),
        ("delivery",           ["yes"],                       "Livraison"),
        ("drive_through",      ["yes"],                       "Drive"),
        ("generator:source",   ["solar", "wind", "diesel"],   "Groupe électrogène"),
        ("toilets",            ["yes"],                       "Toilettes"),
        ("toilets:wheelchair", ["yes"],                       "Toilettes PMR"),
        ("baby_feeding_room",  ["yes"],                       "Salle d'allaitement"),
        ("smoking",            ["no"],                        "Non-fumeur"),
        ("smoking",            ["yes", "dedicated"],          "Espace fumeur"),
        ("capacity",           None,                          None),  # géré séparément
    ]
    seen = set()
    for tag_key, allowed_vals, label in checks:
        if label is None:
            continue
        val = tags.get(tag_key, "").lower().strip()
        if not val:
            continue
        if allowed_vals is None or val in allowed_vals:
            if label not in seen:
                amenities.append(label)
                seen.add(label)
    return amenities


def extract_services(tags: dict, category_slug: str) -> list[str]:
    """Extrait les services spécifiques selon la catégorie."""
    services = []
    seen = set()

    def add(s: str):
        if s not in seen:
            services.append(s)
            seen.add(s)

    # Services communs
    if tags.get("delivery") == "yes":
        add("Livraison")
    if tags.get("takeaway") in ("yes", "only"):
        add("Vente à emporter")
    if tags.get("reservation") == "yes":
        add("Réservation")

    # Restaurant
    if category_slug == "restaurants":
        if tags.get("cuisine"):
            add(f"Cuisine : {tags['cuisine'].split(';')[0].strip().capitalize()}")
        if tags.get("diet:vegetarian") == "yes":
            add("Menu végétarien")
        if tags.get("diet:halal") == "yes":
            add("Halal")
        if tags.get("capacity"):
            add(f"Capacité : {tags['capacity']} couverts")

    # Hébergement
    if category_slug == "hebergement":
        if tags.get("stars"):
            add(f"{tags['stars']} étoiles")
        if tags.get("rooms"):
            add(f"{tags['rooms']} chambres")
        if tags.get("swimming_pool") == "yes":
            add("Piscine")
        if tags.get("sauna") == "yes":
            add("Sauna")

    # Automobile
    if category_slug == "automobile":
        if tags.get("fuel:diesel") == "yes":
            add("Diesel")
        if tags.get("fuel:octane_95") == "yes":
            add("Sans plomb 95")
        if tags.get("fuel:lpg") == "yes":
            add("GPL")

    # Sport
    if category_slug == "activites-loisirs":
        if tags.get("sport"):
            for sp in tags["sport"].split(";"):
                add(sp.strip().capitalize())

    return services


def extract_price_range(tags: dict) -> str | None:
    """Tente de déduire la gamme de prix."""
    # Étoiles hôtel → prix
    stars = tags.get("stars", "")
    if stars.isdigit():
        n = int(stars)
        if n <= 2:
            return "$"
        elif n == 3:
            return "$$"
        elif n == 4:
            return "$$$"
        elif n >= 5:
            return "$$$$"
    # fee / charge=
    fee = tags.get("fee", tags.get("charge", "")).lower()
    if fee in ("yes", "expensive"):
        return "$$"
    if fee in ("no", "free"):
        return "$"
    return None


def extract_tags(tags: dict) -> list[str]:
    """Extrait des mots-clés utiles comme tags."""
    result = []
    if tags.get("cuisine"):
        result.extend([c.strip() for c in tags["cuisine"].split(";")][:3])
    if tags.get("sport"):
        result.extend([s.strip() for s in tags["sport"].split(";")][:3])
    if tags.get("brand"):
        result.append(tags["brand"].strip())
    if tags.get("operator"):
        result.append(tags["operator"].strip())
    return [t[:50] for t in result if t]


def extract_opening_hours(tags: dict) -> dict | None:
    """Convertit opening_hours OSM en JSON structuré."""
    raw = tags.get("opening_hours", "").strip()
    if not raw:
        return None
    # Essayer de parser les horaires simples (Mo-Fr 08:00-18:00)
    result = {"raw": raw}
    day_map = {
        "Mo": "lundi", "Tu": "mardi", "We": "mercredi",
        "Th": "jeudi", "Fr": "vendredi", "Sa": "samedi", "Su": "dimanche",
    }
    # Pattern : "Mo-Fr 09:00-18:00; Sa 09:00-13:00"
    segments = [s.strip() for s in raw.split(";")]
    parsed = {}
    for seg in segments:
        m = re.match(r"^([A-Z][a-z](?:-[A-Z][a-z])?)?\s*(\d{2}:\d{2}-\d{2}:\d{2})?", seg)
        if m and (m.group(1) or m.group(2)):
            days_part = m.group(1) or ""
            hours_part = m.group(2) or ""
            if "-" in days_part:
                start_d, end_d = days_part.split("-")
                day_keys = list(day_map.keys())
                if start_d in day_keys and end_d in day_keys:
                    i1, i2 = day_keys.index(start_d), day_keys.index(end_d)
                    for dk in day_keys[i1:i2+1]:
                        parsed[day_map[dk]] = hours_part
            elif days_part in day_map:
                parsed[day_map[days_part]] = hours_part
    if parsed:
        result["schedule"] = parsed
    return result


def make_slug(name: str, osm_id: int) -> str:
    """Génère un slug unique depuis le nom + ID OSM."""
    normalized = unicodedata.normalize("NFD", name.lower())
    normalized = "".join(c for c in normalized if unicodedata.category(c) != "Mn")
    normalized = re.sub(r"[^a-z0-9]+", "-", normalized).strip("-")
    normalized = re.sub(r"-+", "-", normalized)
    return f"{normalized}-{osm_id}"


def get_coords(element: dict) -> tuple[float | None, float | None]:
    """Retourne (lat, lon) pour un node ou un way/relation avec center."""
    if element["type"] == "node":
        return element.get("lat"), element.get("lon")
    center = element.get("center", {})
    return center.get("lat"), center.get("lon")


def process_element(element: dict) -> dict | None:
    """Transforme un élément OSM en structure établissement."""
    tags = element.get("tags", {})
    osm_id = element.get("id", 0)

    # Nom obligatoire
    name = extract_name(tags)
    if not name:
        return None

    # Catégorie obligatoire
    cat_result = map_category(tags)
    if not cat_result:
        return None
    cat_slug, subcat_slug = cat_result

    # Coordonnées
    lat, lon = get_coords(element)

    # Wilaya
    wilaya_code = extract_wilaya_code(tags)

    return {
        "osm_id":           osm_id,
        "osm_type":         element["type"],
        # Identité
        "name":             name,
        "name_ar":          extract_name_ar(tags),
        "slug":             make_slug(name, osm_id),
        "description":      extract_description(tags),
        # Adresse
        "address":          extract_address(tags, wilaya_code),
        "address_ar":       extract_address_ar(tags),
        # Géolocalisation
        "latitude":         lat,
        "longitude":        lon,
        # Contacts
        "phone":            extract_phone(tags),
        "phone_secondary":  extract_phone_secondary(tags),
        "whatsapp":         extract_whatsapp(tags),
        "email":            tags.get("email") or tags.get("contact:email"),
        "website":          extract_website(tags),
        "facebook":         extract_facebook(tags),
        "instagram":        extract_instagram(tags),
        "tiktok":           extract_tiktok(tags),
        "snapchat":         None,  # absent d'OSM
        # Horaires & infos
        "opening_hours":    extract_opening_hours(tags),
        "price_range":      extract_price_range(tags),
        # Listes
        "amenities":        extract_amenities(tags),
        "services":         extract_services(tags, cat_slug),
        "tags_list":        extract_tags(tags),
        # Images (absent d'OSM)
        "logo":             None,
        "cover_image":      None,
        "images":           [],
        # Catégorisation
        "category_slug":    cat_slug,
        "subcategory_slug": subcat_slug,
        "wilaya_code":      wilaya_code,
        "commune_name":     extract_commune(tags),
        # Debug
        "tags_raw":         tags,
    }


# ============================================================
# GÉNÉRATION GEOJSON
# ============================================================

def to_geojson(establishments: list[dict]) -> dict:
    features = []
    for e in establishments:
        if e["latitude"] is None or e["longitude"] is None:
            continue
        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [e["longitude"], e["latitude"]],
            },
            "properties": {
                "osm_id":          e["osm_id"],
                "name":            e["name"],
                "name_ar":         e["name_ar"],
                "description":     e["description"],
                "category":        e["category_slug"],
                "subcategory":     e["subcategory_slug"],
                "wilaya_code":     e["wilaya_code"],
                "commune":         e["commune_name"],
                "address":         e["address"],
                "address_ar":      e["address_ar"],
                "phone":           e["phone"],
                "phone_secondary": e["phone_secondary"],
                "whatsapp":        e["whatsapp"],
                "email":           e["email"],
                "website":         e["website"],
                "facebook":        e["facebook"],
                "instagram":       e["instagram"],
                "tiktok":          e["tiktok"],
                "opening_hours":   e["opening_hours"],
                "price_range":     e["price_range"],
                "amenities":       e["amenities"],
                "services":        e["services"],
                "tags":            e["tags_list"],
            },
        })
    return {"type": "FeatureCollection", "features": features}


# ============================================================
# GÉNÉRATION SQL
# ============================================================

def _sql_str(v) -> str:
    """Échappe une valeur pour SQL."""
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, (dict, list)):
        escaped = json.dumps(v, ensure_ascii=False).replace("'", "''")
        return f"'{escaped}'"
    escaped = str(v).replace("'", "''")
    return f"'{escaped}'"


def generate_sql(establishments: list[dict]) -> str:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    system_partner_id = str(uuid.uuid4())

    lines = [
        "-- ============================================================",
        "-- Import OSM Algérie — généré le " + now,
        "-- ============================================================",
        "",
        "BEGIN;",
        "",
        "-- Activer l'extension unaccent si elle n'existe pas",
        "CREATE EXTENSION IF NOT EXISTS unaccent;",
        "",
        "-- 1. Créer un partenaire système pour les données OSM",
        "--    (ignoré si l'email existe déjà)",
        "DO $$",
        "DECLARE",
        f"  v_user_id  UUID := '{str(uuid.uuid4())}';",
        f"  v_partner_id UUID := '{system_partner_id}';",
        "BEGIN",
        "  IF NOT EXISTS (SELECT 1 FROM users WHERE email = 'osm-import@system.local') THEN",
        "    INSERT INTO users (id, email, password, first_name, last_name, role, status, email_verified, created_at, updated_at)",
        "    VALUES (v_user_id, 'osm-import@system.local', 'DISABLED', 'OSM', 'Import', 'partner', 'active', TRUE, NOW(), NOW());",
        "",
        "    INSERT INTO partners (id, user_id, company_name, status, created_at, updated_at)",
        "    VALUES (v_partner_id, v_user_id, 'OSM Import Algeria', 'approved', NOW(), NOW());",
        "  END IF;",
        "END $$;",
        "",
        "-- 2. Récupérer l'ID du partenaire OSM",
        "DO $$",
        "DECLARE",
        "  v_partner_id UUID;",
        "BEGIN",
        "  SELECT p.id INTO v_partner_id",
        "  FROM partners p",
        "  JOIN users u ON u.id = p.user_id",
        "  WHERE u.email = 'osm-import@system.local'",
        "  LIMIT 1;",
        "",
        "  IF v_partner_id IS NULL THEN",
        "    RAISE EXCEPTION 'Partenaire OSM introuvable';",
        "  END IF;",
        "",
        "-- 3. Insertion des établissements",
        "--    On utilise INSERT ... ON CONFLICT DO NOTHING (basé sur le slug)",
    ]

    # Grouper par wilaya pour les commentaires
    by_wilaya: dict[str, int] = {}
    for e in establishments:
        k = e["wilaya_code"] or "??"
        by_wilaya[k] = by_wilaya.get(k, 0) + 1

    lines.append(f"--    Total : {len(establishments)} établissements")
    for code in sorted(by_wilaya):
        w_name = WILAYAS.get(code, {}).get("name", f"Wilaya {code}")
        lines.append(f"--      {code} {w_name} : {by_wilaya[code]}")
    lines.append("")

    for e in establishments:
        e_id = str(uuid.uuid4())

        # Sous-requêtes pour les FK
        cat_subq = f"(SELECT id FROM categories WHERE slug = {_sql_str(e['category_slug'])} LIMIT 1)"

        if e["subcategory_slug"]:
            subcat_subq = f"(SELECT id FROM subcategories WHERE slug = {_sql_str(e['subcategory_slug'])} LIMIT 1)"
        else:
            subcat_subq = "NULL"

        if e["wilaya_code"]:
            wilaya_subq = f"(SELECT id FROM wilayas WHERE code = {_sql_str(e['wilaya_code'])} LIMIT 1)"
        else:
            wilaya_subq = "NULL"

        if e["commune_name"]:
            # Recherche par nom (normalisé) dans la commune de la bonne wilaya
            commune_name_esc = e["commune_name"].replace("'", "''")
            commune_subq = (
                f"(SELECT c.id FROM communes c "
                f"JOIN wilayas w ON w.id = c.wilaya_id "
                f"WHERE w.code = {_sql_str(e['wilaya_code'])} "
                f"AND LOWER(UNACCENT(c.name)) = LOWER(UNACCENT('{commune_name_esc}')) "
                f"LIMIT 1)"
            ) if e["wilaya_code"] else "NULL"
        else:
            commune_subq = "NULL"

        lat  = _sql_str(e["latitude"])
        lon  = _sql_str(e["longitude"])
        oh   = _sql_str(e["opening_hours"]) if e["opening_hours"] else "NULL"
        amenities_json = _sql_str(e["amenities"]) if e["amenities"] else "'[]'"
        services_json  = _sql_str(e["services"])  if e["services"]  else "'[]'"
        tags_json      = _sql_str(e["tags_list"]) if e["tags_list"] else "'[]'"
        images_json    = "'[]'"

        lines.append(
            f"  INSERT INTO establishments ("
            f"id, partner_id, category_id, subcategory_id, wilaya_id, commune_id, "
            f"name, name_ar, slug, description, address, address_ar, "
            f"latitude, longitude, "
            f"phone, phone_secondary, whatsapp, email, website, facebook, instagram, tiktok, snapchat, "
            f"opening_hours, price_range, "
            f"amenities, services, tags, images, logo, cover_image, "
            f"status, is_verified, is_featured, "
            f"average_rating, total_reviews, total_views, total_favorites, "
            f"total_calls, total_whatsapp_clicks, total_contacts, "
            f"created_at, updated_at)"
        )
        lines.append(
            f"  VALUES ("
            f"'{e_id}', v_partner_id, {cat_subq}, {subcat_subq}, {wilaya_subq}, {commune_subq}, "
            f"{_sql_str(e['name'])}, {_sql_str(e['name_ar'])}, {_sql_str(e['slug'])}, "
            f"{_sql_str(e['description'])}, {_sql_str(e['address'])}, {_sql_str(e['address_ar'])}, "
            f"{lat}, {lon}, "
            f"{_sql_str(e['phone'])}, {_sql_str(e['phone_secondary'])}, {_sql_str(e['whatsapp'])}, "
            f"{_sql_str(e.get('email'))}, {_sql_str(e['website'])}, "
            f"{_sql_str(e['facebook'])}, {_sql_str(e['instagram'])}, {_sql_str(e['tiktok'])}, NULL, "
            f"{oh}, {_sql_str(e['price_range'])}, "
            f"{amenities_json}, {services_json}, {tags_json}, {images_json}, NULL, NULL, "
            f"'pending', FALSE, FALSE, "
            f"0, 0, 0, 0, 0, 0, 0, "
            f"NOW(), NOW()"
            f")"
        )
        lines.append(
            f"  ON CONFLICT (slug) DO NOTHING;"
        )
        lines.append("")

    lines += [
        "END $$;",
        "",
        "COMMIT;",
        "",
        f"-- Fin import : {len(establishments)} établissements traités.",
    ]

    return "\n".join(lines)


# ============================================================
# RÉSOLUTION GÉOGRAPHIQUE : WILAYA PAR COORDONNÉES
# ============================================================

BOUNDARIES_CACHE = os.path.join(OUTPUT_DIR, "wilaya_boundaries.json")

BOUNDARIES_QUERY = """
[out:json][timeout:300];
rel["admin_level"="4"]["boundary"="administrative"]["ISO3166-2"~"^DZ-"];
out geom;
""".strip()


def download_wilaya_boundaries() -> list[dict]:
    """
    Télécharge les frontières des 58 wilayas depuis Overpass.
    Met en cache dans output/wilaya_boundaries.json pour éviter de re-télécharger.
    """
    if os.path.exists(BOUNDARIES_CACHE):
        print(f"  Frontières en cache → {BOUNDARIES_CACHE}")
        with open(BOUNDARIES_CACHE, encoding="utf-8") as f:
            return json.load(f)

    print("  Téléchargement des frontières des wilayas depuis Overpass...")
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = requests.post(
                OVERPASS_URL,
                data={"data": BOUNDARIES_QUERY},
                timeout=REQUEST_TIMEOUT + 60,
            )
            if resp.status_code == 429 or resp.status_code >= 500:
                print(f"  Erreur {resp.status_code}, attente {RETRY_DELAY}s...")
                time.sleep(RETRY_DELAY)
                continue
            resp.raise_for_status()
            elements = resp.json().get("elements", [])
            print(f"  {len(elements)} relations de wilaya reçues.")
            with open(BOUNDARIES_CACHE, "w", encoding="utf-8") as f:
                json.dump(elements, f, ensure_ascii=False)
            return elements
        except requests.exceptions.Timeout:
            print(f"  Timeout, attente {RETRY_DELAY}s...")
            time.sleep(RETRY_DELAY)
        except Exception as e:
            print(f"  Erreur : {e}")
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_DELAY)
    print("  Impossible de télécharger les frontières.")
    return []


def _extract_wilaya_code_from_relation(tags: dict) -> str | None:
    """Extrait le code wilaya (01-58) depuis les tags d'une relation OSM."""
    # ISO3166-2 = "DZ-16" → "16"
    iso = tags.get("ISO3166-2", tags.get("iso3166-2", ""))
    if iso.upper().startswith("DZ-"):
        code = iso[3:].lstrip("0") or "0"
        code = code.zfill(2)
        if code in WILAYAS:
            return code

    # ref = "16" ou "016"
    ref = tags.get("ref", "").strip()
    if ref.isdigit():
        code = ref.zfill(2)
        if code in WILAYAS:
            return code

    # Correspondance par nom
    for key in ("name", "name:fr"):
        v = tags.get(key, "").strip()
        if v:
            norm = _normalize(v)
            if norm in _WILAYA_LOOKUP:
                return _WILAYA_LOOKUP[norm]
            for variant, wcode in _WILAYA_LOOKUP.items():
                if variant and variant in norm:
                    return wcode
    return None


def build_wilaya_index(elements: list[dict]) -> list[tuple[str, object]]:
    """
    Construit un index spatial : liste de (code_wilaya, shapely_geometry).
    Utilise shapely.ops.polygonize pour assembler les segments de chaque relation.
    """
    try:
        from shapely.geometry import Point, MultiPolygon
        from shapely.ops import polygonize, unary_union
    except ImportError:
        print("  ⚠ shapely non installé — résolution géographique désactivée.")
        print("    Installe-le avec : pip install shapely")
        return []

    index = []
    skipped = 0

    for rel in elements:
        if rel.get("type") != "relation":
            continue

        tags = rel.get("tags", {})
        code = _extract_wilaya_code_from_relation(tags)
        if not code:
            skipped += 1
            continue

        # Collecter tous les segments outer en LineString
        lines = []
        for member in rel.get("members", []):
            if member.get("role") not in ("outer", ""):
                continue
            geom = member.get("geometry", [])
            coords = [(pt["lon"], pt["lat"]) for pt in geom]
            if len(coords) >= 2:
                try:
                    from shapely.geometry import LineString
                    lines.append(LineString(coords))
                except Exception:
                    pass

        if not lines:
            skipped += 1
            continue

        # Assembler les lignes en polygones
        try:
            polys = list(polygonize(lines))
            if not polys:
                # Fallback : unary_union des lignes puis polygonize
                from shapely.ops import unary_union as uu
                merged = uu(lines)
                polys = list(polygonize(merged))

            if polys:
                geom = unary_union(polys)
                index.append((code, geom))
            else:
                skipped += 1
        except Exception:
            skipped += 1

    print(f"  Index spatial : {len(index)} wilayas chargées, {skipped} ignorées.")
    return index


def resolve_wilaya_by_coords(
    lat: float,
    lon: float,
    index: list[tuple[str, object]],
) -> str | None:
    """
    Retourne le code wilaya (ex: '16') pour un point (lat, lon)
    via test point-in-polygon sur l'index spatial.
    """
    if not index or lat is None or lon is None:
        return None
    try:
        from shapely.geometry import Point
        pt = Point(lon, lat)
        for code, geom in index:
            if geom.contains(pt):
                return code
    except Exception:
        pass
    return None


# ============================================================
# MAIN
# ============================================================

def main():
    print("=" * 60)
    print("  OSM Algeria Extractor")
    print("=" * 60)

    all_elements: list[dict] = []
    seen_ids: set[str] = set()

    # ── Étape 1 : Requêtes Overpass POI ──────────────────────
    print("\n[1/4] Extraction des POI depuis Overpass API...")
    for label, amenity_filter in OVERPASS_QUERIES:
        elements = query_overpass(label, amenity_filter)
        for el in elements:
            uid = f"{el['type']}-{el['id']}"
            if uid not in seen_ids:
                seen_ids.add(uid)
                all_elements.append(el)
        time.sleep(2)

    print(f"\n  Total brut : {len(all_elements)} éléments uniques")

    # ── Étape 2 : Transformation ─────────────────────────────
    print("\n[2/4] Transformation et mapping...")
    establishments: list[dict] = []
    skipped_no_name = 0
    skipped_no_cat  = 0

    for el in all_elements:
        result = process_element(el)
        if result is None:
            tags = el.get("tags", {})
            if not extract_name(tags):
                skipped_no_name += 1
            else:
                skipped_no_cat += 1
        else:
            establishments.append(result)

    print(f"  Établissements valides  : {len(establishments)}")
    print(f"  Ignorés (sans nom)      : {skipped_no_name}")
    print(f"  Ignorés (hors catégorie): {skipped_no_cat}")

    no_wilaya_before = sum(1 for e in establishments if not e["wilaya_code"])
    print(f"  Wilaya via addr:state   : {len(establishments) - no_wilaya_before}")
    print(f"  Sans wilaya (avant GEO) : {no_wilaya_before}")

    # ── Étape 3 : Résolution géographique ────────────────────
    print("\n[3/4] Résolution géographique des wilayas...")
    boundary_elements = download_wilaya_boundaries()
    wilaya_index = build_wilaya_index(boundary_elements)

    if wilaya_index:
        resolved = 0
        unresolved = 0
        for e in establishments:
            if e["wilaya_code"]:
                continue  # déjà résolu via addr:state
            if e["latitude"] is None or e["longitude"] is None:
                unresolved += 1
                continue
            code = resolve_wilaya_by_coords(e["latitude"], e["longitude"], wilaya_index)
            if code:
                e["wilaya_code"] = code
                # Compléter l'adresse avec le nom de la wilaya si manquante
                if not any(WILAYAS[code]["name"] in e["address"] for _ in [1]):
                    e["address"] = e["address"].rstrip(", Algérie").rstrip(", ") + f", {WILAYAS[code]['name']}"
                resolved += 1
            else:
                unresolved += 1

        no_wilaya_after = sum(1 for e in establishments if not e["wilaya_code"])
        print(f"  Résolus par GEO         : {resolved}")
        print(f"  Toujours sans wilaya    : {no_wilaya_after}")
    else:
        print("  Résolution géographique ignorée (shapely non disponible).")

    # Stats finales
    by_cat: dict[str, int] = {}
    by_wilaya: dict[str, int] = {}
    for e in establishments:
        by_cat[e["category_slug"]] = by_cat.get(e["category_slug"], 0) + 1
        if e["wilaya_code"]:
            by_wilaya[e["wilaya_code"]] = by_wilaya.get(e["wilaya_code"], 0) + 1

    print("\n  Répartition par catégorie :")
    for cat, n in sorted(by_cat.items(), key=lambda x: -x[1]):
        print(f"    {cat:<35} {n}")

    print("\n  Top 10 wilayas :")
    for code, n in sorted(by_wilaya.items(), key=lambda x: -x[1])[:10]:
        print(f"    {code} {WILAYAS.get(code, {}).get('name', '?'):<25} {n}")

    # ── Étape 4 : Sauvegarde ─────────────────────────────────
    print("\n[4/4] Sauvegarde des fichiers...")


    # GeoJSON
    geojson_path = os.path.join(OUTPUT_DIR, "establishments.geojson")
    with open(geojson_path, "w", encoding="utf-8") as f:
        json.dump(to_geojson(establishments), f, ensure_ascii=False, indent=2)
    print(f"  GeoJSON  → {geojson_path}")

    # JSON brut (pour debug / import personnalisé)
    json_path = os.path.join(OUTPUT_DIR, "establishments_raw.json")
    with open(json_path, "w", encoding="utf-8") as f:
        # Exclure tags_raw pour alléger
        clean = [{k: v for k, v in e.items() if k != "tags_raw"} for e in establishments]
        json.dump(clean, f, ensure_ascii=False, indent=2)
    print(f"  JSON brut → {json_path}")

    # SQL
    sql_path = os.path.join(OUTPUT_DIR, "import.sql")
    sql = generate_sql(establishments)
    with open(sql_path, "w", encoding="utf-8") as f:
        f.write(sql)
    print(f"  SQL      → {sql_path}")

    print("\n✓ Extraction terminée.")
    print(f"  {len(establishments)} établissements prêts à importer.")


if __name__ == "__main__":
    main()
