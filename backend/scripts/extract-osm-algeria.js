#!/usr/bin/env node
/**
 * extract-osm-algeria.js
 *
 * Extrait les établissements OSM d'Algérie via l'API Overpass
 * et génère un fichier JSON prêt à importer dans la base de données.
 *
 * Usage :
 *   node scripts/extract-osm-algeria.js
 *   node scripts/extract-osm-algeria.js --wilaya="Alger"
 *   node scripts/extract-osm-algeria.js --category="sante"
 *
 * Sortie : scripts/osm-output.json
 */

"use strict";

const https = require("https");
const fs = require("fs");
const path = require("path");

// ── Configuration ─────────────────────────────────────────────────────────────

const OUTPUT_FILE = path.join(__dirname, "osm-output.json");
const OVERPASS_URL = "https://overpass-api.de/api/interpreter";

// Filtre optionnel via args
const args = process.argv.slice(2);
const argWilaya = args.find((a) => a.startsWith("--wilaya="))?.split("=")[1];
const argCategory = args.find((a) => a.startsWith("--category="))?.split("=")[1];

// ── Mapping OSM tags → catégories app ─────────────────────────────────────────

const CATEGORIES = {
  restaurants: {
    slug: "restaurants",
    osmFilters: [
      'amenity=restaurant',
      'amenity=fast_food',
      'amenity=cafe',
      'amenity=bar',
      'amenity=food_court',
      'amenity=ice_cream',
      'amenity=pizzeria',
      'shop=bakery',
      'shop=pastry',
    ],
  },
  "beaute-bien-etre": {
    slug: "beaute-bien-etre",
    osmFilters: [
      'shop=beauty',
      'shop=hairdresser',
      'shop=cosmetics',
      'amenity=spa',
      'shop=perfumery',
      'shop=massage',
      'shop=tattoo',
    ],
  },
  sante: {
    slug: "sante",
    osmFilters: [
      'amenity=hospital',
      'amenity=clinic',
      'amenity=pharmacy',
      'amenity=doctors',
      'amenity=dentist',
      'amenity=optician',
      'amenity=veterinary',
      'healthcare=laboratory',
    ],
  },
  automobile: {
    slug: "automobile",
    osmFilters: [
      'shop=car_repair',
      'shop=car',
      'shop=car_parts',
      'amenity=fuel',
      'shop=tyres',
      'amenity=car_wash',
      'shop=motorcycle_repair',
      'shop=motorcycle',
    ],
  },
  hebergement: {
    slug: "hebergement",
    osmFilters: [
      'tourism=hotel',
      'tourism=hostel',
      'tourism=guest_house',
      'tourism=apartment',
      'tourism=motel',
    ],
  },
  "activites-loisirs": {
    slug: "activites-loisirs",
    osmFilters: [
      'leisure=fitness_centre',
      'amenity=gym',
      'amenity=swimming_pool',
      'leisure=sports_centre',
      'amenity=cinema',
      'amenity=theatre',
      'leisure=bowling_alley',
      'leisure=stadium',
      'amenity=nightclub',
      'leisure=water_park',
    ],
  },
  "maison-services": {
    slug: "maison-services",
    osmFilters: [
      'shop=furniture',
      'shop=hardware',
      'shop=doityourself',
      'amenity=post_office',
      'shop=electrical',
      'shop=appliance',
      'shop=interior_decoration',
    ],
  },
  commerces: {
    slug: "commerces",
    osmFilters: [
      'shop=supermarket',
      'shop=mall',
      'shop=clothes',
      'shop=shoes',
      'shop=butcher',
      'shop=greengrocer',
      'shop=convenience',
      'shop=department_store',
      'shop=electronics',
      'shop=mobile_phone',
    ],
  },
  "voyages-tourisme": {
    slug: "voyages-tourisme",
    osmFilters: [
      'tourism=museum',
      'tourism=attraction',
      'tourism=gallery',
      'amenity=travel_agency',
      'tourism=viewpoint',
      'tourism=zoo',
      'tourism=theme_park',
    ],
  },
  "services-professionnels": {
    slug: "services-professionnels",
    osmFilters: [
      'amenity=bank',
      'amenity=bureau_de_change',
      'office=lawyer',
      'office=notary',
      'office=accountant',
      'office=insurance',
      'amenity=police',
      'amenity=townhall',
      'office=telecommunication',
    ],
  },
};

// ── Wilayas d'Algérie (pour filtrage optionnel) ────────────────────────────────

const WILAYAS = {
  "Alger": "36.5,2.9,36.9,3.4",
  "Oran": "35.5,-0.8,35.8,-0.5",
  "Constantine": "36.2,6.5,36.5,6.7",
  "Annaba": "36.7,7.6,36.9,7.8",
  "Blida": "36.3,2.6,36.5,2.9",
  "Tlemcen": "34.8,-1.4,34.9,-1.3",
  "Sétif": "36.1,5.3,36.3,5.5",
  "Béjaïa": "36.7,5.0,36.9,5.2",
  "Tizi Ouzou": "36.6,4.0,36.8,4.2",
  "Batna": "35.5,6.1,35.7,6.3",
};

// ── Helpers ────────────────────────────────────────────────────────────────────

function httpsPost(url, body) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname,
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": Buffer.byteLength(body),
        "User-Agent": "YassApp-OSM-Extractor/1.0",
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`JSON parse error: ${e.message}`));
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`));
        }
      });
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function buildQuery(osmFilter, bbox) {
  const [tag, value] = osmFilter.split("=");
  const area = bbox
    ? `(${bbox})`
    : `(area["ISO3166-1"="DZ"])`;

  if (bbox) {
    return `
      [out:json][timeout:60];
      (
        node["${tag}"="${value}"](${bbox});
        way["${tag}"="${value}"](${bbox});
      );
      out center tags;
    `;
  }

  return `
    [out:json][timeout:120];
    area["ISO3166-1"="DZ"]->.searchArea;
    (
      node["${tag}"="${value}"](area.searchArea);
      way["${tag}"="${value}"](area.searchArea);
    );
    out center tags;
  `;
}

function parseElement(el, categorySlug) {
  const tags = el.tags || {};
  const lat = el.lat ?? el.center?.lat;
  const lon = el.lon ?? el.center?.lon;

  if (!lat || !lon) return null;

  const name =
    tags.name ||
    tags["name:fr"] ||
    tags["name:ar"] ||
    tags.official_name ||
    null;

  if (!name) return null;

  const address = [
    tags["addr:housenumber"],
    tags["addr:street"],
    tags["addr:suburb"],
    tags["addr:city"] || tags["addr:town"] || tags["addr:village"],
  ]
    .filter(Boolean)
    .join(", ");

  return {
    name: name.trim(),
    address: address || tags["addr:full"] || "",
    phone: tags.phone || tags["contact:phone"] || null,
    website: tags.website || tags["contact:website"] || null,
    latitude: lat,
    longitude: lon,
    category_slug: categorySlug,
    osm_id: `${el.type}/${el.id}`,
    osm_tags: {
      opening_hours: tags.opening_hours || null,
      cuisine: tags.cuisine || null,
      brand: tags.brand || null,
      operator: tags.operator || null,
      email: tags.email || tags["contact:email"] || null,
      facebook: tags["contact:facebook"] || null,
      wheelchair: tags.wheelchair || null,
      internet_access: tags.internet_access || null,
    },
  };
}

// ── Main ───────────────────────────────────────────────────────────────────────

async function main() {
  console.log("🇩🇿  Extraction OSM Algérie — début\n");

  const categoriesToProcess = argCategory
    ? { [argCategory]: CATEGORIES[argCategory] }
    : CATEGORIES;

  if (argCategory && !CATEGORIES[argCategory]) {
    console.error(`❌  Catégorie inconnue: "${argCategory}"`);
    console.error(`   Disponibles: ${Object.keys(CATEGORIES).join(", ")}`);
    process.exit(1);
  }

  const bbox = argWilaya ? WILAYAS[argWilaya] : null;
  if (argWilaya && !bbox) {
    console.warn(`⚠️  Wilaya inconnue: "${argWilaya}" — extraction nationale`);
  }

  const allResults = [];
  const seen = new Set(); // éviter les doublons par osm_id

  for (const [catKey, catDef] of Object.entries(categoriesToProcess)) {
    console.log(`\n📂  Catégorie: ${catKey}`);
    let catCount = 0;

    for (const osmFilter of catDef.osmFilters) {
      process.stdout.write(`   Requête [${osmFilter}]... `);

      try {
        const query = buildQuery(osmFilter, bbox);
        const body = `data=${encodeURIComponent(query)}`;
        const data = await httpsPost(OVERPASS_URL, body);

        const elements = data.elements || [];
        let added = 0;

        for (const el of elements) {
          const parsed = parseElement(el, catDef.slug);
          if (!parsed) continue;
          if (seen.has(parsed.osm_id)) continue;
          seen.add(parsed.osm_id);
          allResults.push(parsed);
          added++;
          catCount++;
        }

        console.log(`✅  ${added} lieux`);
      } catch (err) {
        console.log(`❌  ${err.message}`);
      }

      // Respecter le rate limit Overpass (1 req/s recommandé)
      await sleep(1200);
    }

    console.log(`   → Total catégorie: ${catCount} lieux`);
  }

  // ── Sauvegarde ──────────────────────────────────────────────────────────────
  const output = {
    extracted_at: new Date().toISOString(),
    total: allResults.length,
    filter_wilaya: argWilaya || "Algérie entière",
    filter_category: argCategory || "toutes",
    establishments: allResults,
  };

  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(output, null, 2), "utf8");

  console.log(`\n✅  Extraction terminée`);
  console.log(`   Total : ${allResults.length} établissements`);
  console.log(`   Fichier : ${OUTPUT_FILE}`);
  console.log(`\n   Prochaine étape :`);
  console.log(`   node scripts/import-osm.js\n`);
}

main().catch((err) => {
  console.error("❌  Erreur fatale:", err.message);
  process.exit(1);
});
