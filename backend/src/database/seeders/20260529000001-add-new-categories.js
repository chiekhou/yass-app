"use strict";
const { v4: uuidv4 } = require("uuid");

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const now = new Date();

    // ── 1. Nouvelles catégories ──────────────────────────────────────────
    const newCategories = [
      { name: "Vie nocturne",                        name_ar: "الحياة الليلية",          name_en: "Nightlife",                    slug: "vie-nocturne",                    icon: "nightlife",          color: "#8E44AD", order: 13 },
      { name: "Shopping",                            name_ar: "تسوق",                    name_en: "Shopping",                     slug: "shopping",                        icon: "shopping_bag",       color: "#E91E63", order: 14 },
      { name: "Alimentation",                        name_ar: "الغذاء",                  name_en: "Food & Grocery",               slug: "alimentation",                    icon: "local_grocery_store",color: "#FF9800", order: 15 },
      { name: "Salons de beauté & Spas",             name_ar: "صالونات التجميل والسبا",   name_en: "Beauty Salons & Spas",         slug: "salons-beaute-spas",              icon: "spa",                color: "#F06292", order: 16 },
      { name: "Maison & Travaux",                    name_ar: "المنزل والأشغال",          name_en: "Home & Works",                 slug: "maison-travaux",                  icon: "home_repair_service",color: "#795548", order: 17 },
      { name: "Services locaux",                     name_ar: "الخدمات المحلية",          name_en: "Local Services",               slug: "services-locaux",                 icon: "handyman",           color: "#607D8B", order: 18 },
      { name: "Organisation d'événements",           name_ar: "تنظيم الفعاليات",          name_en: "Event Planning",               slug: "organisation-evenements",         icon: "celebration",        color: "#D35400", order: 19 },
      { name: "Art & loisirs",                       name_ar: "الفن والترفيه",            name_en: "Arts & Entertainment",         slug: "art-loisirs",                     icon: "palette",            color: "#009688", order: 20 },
      { name: "Sports et activités de loisirs",      name_ar: "الرياضة وأنشطة الترفيه",  name_en: "Sports & Leisure Activities",  slug: "sports-activites-loisirs",        icon: "sports_soccer",      color: "#4CAF50", order: 21 },
      { name: "Services destinés aux professionnels",name_ar: "خدمات للمهنيين",           name_en: "Professional Services",        slug: "services-destines-professionnels",icon: "business_center",    color: "#34495E", order: 22 },
      { name: "Hôtels & séjours",                   name_ar: "الفنادق والإقامة",          name_en: "Hotels & Stays",               slug: "hotels-sejours",                  icon: "hotel",              color: "#1ABC9C", order: 23 },
      { name: "Formation & Enseignement",            name_ar: "التكوين والتعليم",          name_en: "Training & Education",         slug: "formation-enseignement",          icon: "school",             color: "#3F51B5", order: 24 },
      { name: "Animaux de compagnie",                name_ar: "الحيوانات الأليفة",        name_en: "Pets",                         slug: "animaux-compagnie",               icon: "pets",               color: "#FF5722", order: 25 },
      { name: "Services financiers",                 name_ar: "الخدمات المالية",           name_en: "Financial Services",           slug: "services-financiers",             icon: "account_balance",    color: "#2196F3", order: 26 },
      { name: "Couleur locale",                      name_ar: "الثقافة المحلية",           name_en: "Local Color",                  slug: "couleur-locale",                  icon: "flag",               color: "#009688", order: 27 },
      { name: "Services publics et gouvernementaux", name_ar: "الخدمات العامة والحكومية", name_en: "Public & Government Services", slug: "services-publics-gouvernementaux",icon: "account_balance",    color: "#37474F", order: 28 },
      { name: "Média",                               name_ar: "الإعلام",                  name_en: "Media",                        slug: "media",                           icon: "newspaper",          color: "#455A64", order: 29 },
      { name: "Organisation religieuse",             name_ar: "المنظمات الدينية",          name_en: "Religious Organizations",      slug: "organisation-religieuse",         icon: "church",             color: "#6D4C41", order: 30 },
      { name: "Santé & Médical",                     name_ar: "الصحة والطب",              name_en: "Health & Medical",             slug: "sante-medical",                   icon: "local_hospital",     color: "#F44336", order: 31 },
    ];

    const categoriesToInsert = newCategories.map((c) => ({
      id: uuidv4(),
      name: c.name,
      name_ar: c.name_ar,
      name_en: c.name_en,
      slug: c.slug,
      description: c.name,
      description_ar: c.name_ar,
      icon: c.icon,
      color: c.color,
      is_active: true,
      order: c.order,
      created_at: now,
      updated_at: now,
    }));

    await queryInterface.bulkInsert("categories", categoriesToInsert, {
      ignoreDuplicates: true,
    });

    // ── 2. Charger toutes les catégories pour construire la map slug→id ──
    const allCategories = await queryInterface.sequelize.query(
      `SELECT id, slug FROM categories;`,
      { type: Sequelize.QueryTypes.SELECT }
    );
    const catMap = {};
    allCategories.forEach((c) => (catMap[c.slug] = c.id));

    // ── 3. Nouvelles sous-catégories ─────────────────────────────────────
    const newSubcategories = [

      // ==================== VIE NOCTURNE ====================
      { category: "vie-nocturne", name: "Bar",                        name_ar: "بار",                    slug: "bar",                        icon: "local_bar",         order: 1 },
      { category: "vie-nocturne", name: "Boîte de nuit",              name_ar: "ملهى ليلي",              slug: "boite-nuit",                  icon: "nightlife",         order: 2 },
      { category: "vie-nocturne", name: "Karaoké",                    name_ar: "كاراوكي",                slug: "karaoke",                     icon: "mic",               order: 3 },
      { category: "vie-nocturne", name: "Lounge & Rooftop",           name_ar: "لاونج وروفتوب",          slug: "lounge-rooftop",              icon: "roofing",           order: 4 },
      { category: "vie-nocturne", name: "Concert & Spectacle",        name_ar: "حفلات موسيقية",          slug: "concert-spectacle",           icon: "music_note",        order: 5 },
      { category: "vie-nocturne", name: "Salle de billard",           name_ar: "قاعة بلياردو",           slug: "salle-billard",               icon: "sports_billiards",  order: 6 },

      // ==================== SHOPPING ====================
      { category: "shopping", name: "Centre commercial",      name_ar: "مركز تجاري",     slug: "centre-commercial",    icon: "local_mall",      order: 1 },
      { category: "shopping", name: "Boutique de vêtements",  name_ar: "متجر ملابس",     slug: "boutique-vetements",   icon: "checkroom",       order: 2 },
      { category: "shopping", name: "Chaussures",             name_ar: "أحذية",           slug: "chaussures",           icon: "sports_handball", order: 3 },
      { category: "shopping", name: "Accessoires & Sacs",     name_ar: "اكسسوارات وحقائب",slug: "accessoires-sacs",    icon: "shopping_bag",    order: 4 },
      { category: "shopping", name: "Jouets & Jeux",          name_ar: "ألعاب",           slug: "jouets-jeux",          icon: "toys",            order: 5 },
      { category: "shopping", name: "Informatique & Tech",    name_ar: "إعلام آلي وتكنولوجيا",slug: "informatique-tech",icon: "computer",        order: 6 },
      { category: "shopping", name: "Mobilier & Décoration",  name_ar: "أثاث وديكور",    slug: "mobilier-decoration",  icon: "chair",           order: 7 },
      { category: "shopping", name: "Articles de sport",      name_ar: "مستلزمات رياضية", slug: "articles-sport",       icon: "sports",          order: 8 },
      { category: "shopping", name: "Parfumerie & Cosmétiques",name_ar: "عطور ومستحضرات",slug: "parfumerie-cosmetiques",icon: "sanitizer",      order: 9 },

      // ==================== ALIMENTATION ====================
      { category: "alimentation", name: "Supermarché",      name_ar: "سوبر ماركت",  slug: "supermarche-alim",    icon: "local_grocery_store", order: 1 },
      { category: "alimentation", name: "Épicerie",         name_ar: "بقالة",        slug: "epicerie-alim",       icon: "storefront",          order: 2 },
      { category: "alimentation", name: "Boulangerie",      name_ar: "مخبزة",        slug: "boulangerie-alim",    icon: "bakery_dining",       order: 3 },
      { category: "alimentation", name: "Boucherie",        name_ar: "جزارة",        slug: "boucherie-alim",      icon: "restaurant",          order: 4 },
      { category: "alimentation", name: "Poissonnerie",     name_ar: "محل سمك",      slug: "poissonnerie",        icon: "set_meal",            order: 5 },
      { category: "alimentation", name: "Fruits & Légumes", name_ar: "فواكه وخضار",  slug: "fruits-legumes",      icon: "eco",                 order: 6 },
      { category: "alimentation", name: "Marché",           name_ar: "سوق",          slug: "marche",              icon: "festival",            order: 7 },
      { category: "alimentation", name: "Fromagerie",       name_ar: "محل جبن",      slug: "fromagerie",          icon: "lunch_dining",        order: 8 },
      { category: "alimentation", name: "Bio & Diététique", name_ar: "منتجات بيو",   slug: "bio-dietetique",      icon: "grass",               order: 9 },

      // ==================== SALONS DE BEAUTÉ & SPAS ====================
      { category: "salons-beaute-spas", name: "Salon de coiffure homme",  name_ar: "صالون حلاقة رجال", slug: "coiffure-homme-sbs",  icon: "content_cut",              order: 1 },
      { category: "salons-beaute-spas", name: "Salon de coiffure femme",  name_ar: "صالون حلاقة نساء", slug: "coiffure-femme-sbs",  icon: "face_retouching_natural",  order: 2 },
      { category: "salons-beaute-spas", name: "Institut de beauté",       name_ar: "معهد تجميل",       slug: "institut-beaute-sbs", icon: "spa",                      order: 3 },
      { category: "salons-beaute-spas", name: "Spa & Hammam",             name_ar: "سبا وحمام",        slug: "spa-hammam-sbs",      icon: "hot_tub",                  order: 4 },
      { category: "salons-beaute-spas", name: "Manucure & Pédicure",      name_ar: "مانيكير وباديكير", slug: "manucure-pedicure-sbs",icon: "back_hand",               order: 5 },
      { category: "salons-beaute-spas", name: "Maquillage",               name_ar: "مكياج",            slug: "maquillage-sbs",      icon: "brush",                    order: 6 },
      { category: "salons-beaute-spas", name: "Massage",                  name_ar: "تدليك",            slug: "massage-sbs",         icon: "self_improvement",         order: 7 },
      { category: "salons-beaute-spas", name: "Épilation & Cire",         name_ar: "إزالة الشعر",      slug: "epilation-cire",      icon: "auto_fix_high",            order: 8 },
      { category: "salons-beaute-spas", name: "Tatouage & Piercing",      name_ar: "وشم وثقب",         slug: "tatouage-piercing",   icon: "draw",                     order: 9 },

      // ==================== MAISON & TRAVAUX ====================
      { category: "maison-travaux", name: "Plombier",            name_ar: "سباك",            slug: "plombier-mt",      icon: "plumbing",           order: 1 },
      { category: "maison-travaux", name: "Électricien",         name_ar: "كهربائي",         slug: "electricien-mt",   icon: "electrical_services",order: 2 },
      { category: "maison-travaux", name: "Menuisier",           name_ar: "نجار",            slug: "menuisier-mt",     icon: "carpenter",          order: 3 },
      { category: "maison-travaux", name: "Peintre",             name_ar: "دهان",            slug: "peintre-mt",       icon: "format_paint",       order: 4 },
      { category: "maison-travaux", name: "Maçon",               name_ar: "بناء",            slug: "macon",            icon: "foundation",         order: 5 },
      { category: "maison-travaux", name: "Carrelage",           name_ar: "بلاط",            slug: "carrelage",        icon: "grid_on",            order: 6 },
      { category: "maison-travaux", name: "Climatisation",       name_ar: "تكييف",           slug: "clim-mt",          icon: "ac_unit",            order: 7 },
      { category: "maison-travaux", name: "Service de ménage",   name_ar: "خدمة تنظيف",      slug: "menage-mt",        icon: "cleaning_services",  order: 8 },
      { category: "maison-travaux", name: "Déménagement",        name_ar: "نقل",             slug: "demenagement-mt",  icon: "local_shipping",     order: 9 },
      { category: "maison-travaux", name: "Jardinage",           name_ar: "بستنة",           slug: "jardinage-mt",     icon: "yard",               order: 10 },
      { category: "maison-travaux", name: "Vitrier",             name_ar: "زجاجي",           slug: "vitrier",          icon: "window",             order: 11 },
      { category: "maison-travaux", name: "Ferronnier",          name_ar: "حداد",            slug: "ferronnier",       icon: "hardware",           order: 12 },

      // ==================== SERVICES LOCAUX ====================
      { category: "services-locaux", name: "Laverie",               name_ar: "مغسلة",        slug: "laverie",           icon: "local_laundry_service",order: 1 },
      { category: "services-locaux", name: "Pressing",              name_ar: "كوي ملابس",    slug: "pressing",          icon: "dry_cleaning",        order: 2 },
      { category: "services-locaux", name: "Cordonnier",            name_ar: "إسكافي",       slug: "cordonnier",        icon: "construction",        order: 3 },
      { category: "services-locaux", name: "Couturier",             name_ar: "خياط",         slug: "couturier",         icon: "cut",                 order: 4 },
      { category: "services-locaux", name: "Réparation téléphone",  name_ar: "إصلاح هاتف",   slug: "reparation-tel",    icon: "phone_android",       order: 5 },
      { category: "services-locaux", name: "Serrurerie",            name_ar: "أقفال",        slug: "serrurerie",        icon: "lock",                order: 6 },
      { category: "services-locaux", name: "Photocopie & Impression",name_ar: "نسخ وطباعة", slug: "photocopie",        icon: "print",               order: 7 },
      { category: "services-locaux", name: "Transport",             name_ar: "نقل",          slug: "transport-local",   icon: "local_taxi",          order: 8 },

      // ==================== ORGANISATION D'ÉVÉNEMENTS ====================
      { category: "organisation-evenements", name: "Salle des fêtes",        name_ar: "قاعة حفلات",   slug: "salle-fetes-oe",    icon: "celebration",      order: 1 },
      { category: "organisation-evenements", name: "Traiteur",               name_ar: "تموين",        slug: "traiteur-oe",       icon: "restaurant_menu",  order: 2 },
      { category: "organisation-evenements", name: "Photographe & Vidéaste", name_ar: "مصور",         slug: "photo-video-oe",    icon: "photo_camera",     order: 3 },
      { category: "organisation-evenements", name: "Décoration",             name_ar: "ديكور",        slug: "deco-oe",           icon: "format_paint",     order: 4 },
      { category: "organisation-evenements", name: "DJ & Animation",         name_ar: "دي جي",        slug: "dj-oe",             icon: "music_note",       order: 5 },
      { category: "organisation-evenements", name: "Wedding planner",        name_ar: "منظم أعراس",   slug: "wedding-oe",        icon: "favorite",         order: 6 },
      { category: "organisation-evenements", name: "Location de matériel",   name_ar: "تأجير معدات",  slug: "location-mat-oe",   icon: "chair",            order: 7 },
      { category: "organisation-evenements", name: "Fleuriste",              name_ar: "بائع زهور",    slug: "fleuriste-oe",      icon: "local_florist",    order: 8 },

      // ==================== ART & LOISIRS ====================
      { category: "art-loisirs", name: "Galerie d'art",        name_ar: "معرض فني",       slug: "galerie-art",      icon: "palette",      order: 1 },
      { category: "art-loisirs", name: "Musée",                name_ar: "متحف",           slug: "musee",            icon: "museum",       order: 2 },
      { category: "art-loisirs", name: "Théâtre",              name_ar: "مسرح",           slug: "theatre",          icon: "theater_comedy",order: 3 },
      { category: "art-loisirs", name: "Cinéma",               name_ar: "سينما",          slug: "cinema-al",        icon: "movie",        order: 4 },
      { category: "art-loisirs", name: "Cours de musique",     name_ar: "دروس موسيقى",   slug: "cours-musique",    icon: "queue_music",  order: 5 },
      { category: "art-loisirs", name: "Cours de dessin",      name_ar: "دروس رسم",       slug: "cours-dessin",     icon: "draw",         order: 6 },
      { category: "art-loisirs", name: "Cours de danse",       name_ar: "دروس رقص",       slug: "cours-danse",      icon: "self_improvement",order: 7 },
      { category: "art-loisirs", name: "Atelier artisanal",    name_ar: "ورشة حرف",       slug: "atelier-artisanal",icon: "handyman",     order: 8 },
      { category: "art-loisirs", name: "Librairie",            name_ar: "مكتبة",          slug: "librairie-al",     icon: "menu_book",    order: 9 },

      // ==================== SPORTS ET ACTIVITÉS DE LOISIRS ====================
      { category: "sports-activites-loisirs", name: "Activités pour enfants",      name_ar: "أنشطة للأطفال",       slug: "activites-enfants",      icon: "child_care",         order: 1 },
      { category: "sports-activites-loisirs", name: "Aire de jeux",                name_ar: "ملعب أطفال",          slug: "aire-jeux",              icon: "sports",             order: 2 },
      { category: "sports-activites-loisirs", name: "Airsoft",                     name_ar: "إيرسوفت",             slug: "airsoft",                icon: "sports",             order: 3 },
      { category: "sports-activites-loisirs", name: "Aquarium",                    name_ar: "حوض مائي",            slug: "aquarium",               icon: "water",              order: 4 },
      { category: "sports-activites-loisirs", name: "Armureries",                  name_ar: "محلات الأسلحة",        slug: "armureries",             icon: "security",           order: 5 },
      { category: "sports-activites-loisirs", name: "Badminton",                   name_ar: "بادمنتون",             slug: "badminton",              icon: "sports_tennis",      order: 6 },
      { category: "sports-activites-loisirs", name: "Bateaux & Navigation",        name_ar: "قوارب وملاحة",        slug: "bateaux-navigation",     icon: "sailing",            order: 7 },
      { category: "sports-activites-loisirs", name: "Bobsleigh",                   name_ar: "بوبسليغ",             slug: "bobsleigh",              icon: "sports",             order: 8 },
      { category: "sports-activites-loisirs", name: "Bowling",                     name_ar: "بولينغ",              slug: "bowling",                icon: "sports_cricket",     order: 9 },
      { category: "sports-activites-loisirs", name: "Bubble football",             name_ar: "كرة القدم الفقاعية",  slug: "bubble-football",        icon: "sports_soccer",      order: 10 },
      { category: "sports-activites-loisirs", name: "Bungee Jumping",              name_ar: "قفز حر",              slug: "bungee-jumping",         icon: "paragliding",        order: 11 },
      { category: "sports-activites-loisirs", name: "Canyoning",                   name_ar: "كانيونيغ",            slug: "canyoning",              icon: "terrain",            order: 12 },
      { category: "sports-activites-loisirs", name: "Carrousels",                  name_ar: "أفلاك",               slug: "carrousels",             icon: "attractions",        order: 13 },
      { category: "sports-activites-loisirs", name: "Centre aéré",                 name_ar: "مركز ترفيهي",         slug: "centre-aere",            icon: "park",               order: 14 },
      { category: "sports-activites-loisirs", name: "Club d'escrime",              name_ar: "نادي مبارزة",         slug: "club-escrime",           icon: "sports",             order: 15 },
      { category: "sports-activites-loisirs", name: "Clubs de sport",              name_ar: "أندية رياضية",        slug: "clubs-sport",            icon: "sports",             order: 16 },
      { category: "sports-activites-loisirs", name: "Colonie de vacances",         name_ar: "مخيم صيفي",           slug: "colonie-vacances",       icon: "holiday_village",    order: 17 },
      { category: "sports-activites-loisirs", name: "Cours de spinning",           name_ar: "دروس سبينينغ",        slug: "cours-spinning",         icon: "fitness_center",     order: 18 },
      { category: "sports-activites-loisirs", name: "Courses et compétitions",     name_ar: "سباقات ومنافسات",     slug: "courses-competitions",   icon: "emoji_events",       order: 19 },
      { category: "sports-activites-loisirs", name: "Disc-Golf",                   name_ar: "دسك غولف",            slug: "disc-golf",              icon: "sports_golf",        order: 20 },
      { category: "sports-activites-loisirs", name: "Équipes sportives d'amateurs",name_ar: "فرق هواة",            slug: "equipes-amateurs",       icon: "groups",             order: 21 },
      { category: "sports-activites-loisirs", name: "Escalade",                    name_ar: "تسلق",                slug: "escalade",               icon: "landscape",          order: 22 },
      { category: "sports-activites-loisirs", name: "Escape Games",                name_ar: "ألعاب الهروب",        slug: "escape-games",           icon: "extension",          order: 23 },
      { category: "sports-activites-loisirs", name: "Équitation",                  name_ar: "ركوب الخيل",          slug: "equitation",             icon: "sports",             order: 24 },
      { category: "sports-activites-loisirs", name: "Fitness & Coaching",          name_ar: "لياقة بدنية وتدريب",  slug: "fitness-coaching",       icon: "fitness_center",     order: 25 },
      { category: "sports-activites-loisirs", name: "Flyboard",                    name_ar: "فلايبورد",            slug: "flyboard",               icon: "surfing",            order: 26 },
      { category: "sports-activites-loisirs", name: "Handball",                    name_ar: "كرة يد",              slug: "handball",               icon: "sports_handball",    order: 27 },
      { category: "sports-activites-loisirs", name: "Indoor Playcenter",           name_ar: "مركز ألعاب داخلي",   slug: "indoor-playcenter",      icon: "sports_esports",     order: 28 },
      { category: "sports-activites-loisirs", name: "Jet-ski",                     name_ar: "جيت سكي",             slug: "jet-ski",                icon: "surfing",            order: 29 },
      { category: "sports-activites-loisirs", name: "Karting",                     name_ar: "كارتينغ",             slug: "karting",                icon: "directions_car",     order: 30 },
      { category: "sports-activites-loisirs", name: "Kayak & Rafting",             name_ar: "كياك ورافتينغ",       slug: "kayak-rafting",          icon: "rowing",             order: 31 },
      { category: "sports-activites-loisirs", name: "Kitesurf",                    name_ar: "كايت سيرف",           slug: "kitesurf",               icon: "kitesurfing",        order: 32 },
      { category: "sports-activites-loisirs", name: "Lac",                         name_ar: "بحيرة",               slug: "lac",                    icon: "water",              order: 33 },
      { category: "sports-activites-loisirs", name: "Laser game",                  name_ar: "لعبة الليزر",         slug: "laser-game",             icon: "sports_esports",     order: 34 },
      { category: "sports-activites-loisirs", name: "Location de matériel de plage",name_ar: "تأجير معدات الشاطئ",slug: "location-materiel-plage",icon: "beach_access",       order: 35 },
      { category: "sports-activites-loisirs", name: "Location de scooter",         name_ar: "تأجير سكوتر",         slug: "location-scooter",       icon: "electric_scooter",   order: 36 },
      { category: "sports-activites-loisirs", name: "Location de vélos",           name_ar: "تأجير دراجات",        slug: "location-velos",         icon: "pedal_bike",         order: 37 },
      { category: "sports-activites-loisirs", name: "Mini Golf",                   name_ar: "غولف مصغر",           slug: "mini-golf",              icon: "sports_golf",        order: 38 },
      { category: "sports-activites-loisirs", name: "Montgolfières",               name_ar: "منطاد",               slug: "montgolfieres",          icon: "paragliding",        order: 39 },
      { category: "sports-activites-loisirs", name: "Naturiste",                   name_ar: "طبيعي",               slug: "naturiste",              icon: "nature",             order: 40 },
      { category: "sports-activites-loisirs", name: "Paddleboard",                 name_ar: "باديل بورد",          slug: "paddleboard",            icon: "surfing",            order: 41 },
      { category: "sports-activites-loisirs", name: "Paintball",                   name_ar: "بينتبول",             slug: "paintball",              icon: "sports",             order: 42 },
      { category: "sports-activites-loisirs", name: "Parachute ascensionnel",      name_ar: "مظلة صاعدة",          slug: "parachute-ascensionnel", icon: "paragliding",        order: 43 },
      { category: "sports-activites-loisirs", name: "Parachutisme",                name_ar: "قفز بالمظلة",         slug: "parachutisme",           icon: "paragliding",        order: 44 },
      { category: "sports-activites-loisirs", name: "Parapente",                   name_ar: "باراغلايدينغ",        slug: "parapente",              icon: "paragliding",        order: 45 },
      { category: "sports-activites-loisirs", name: "Parapente, deltaplane",       name_ar: "باراغلايدينغ، دلتابلان",slug: "parapente-deltaplane", icon: "paragliding",        order: 46 },
      { category: "sports-activites-loisirs", name: "Parcours accrobranche",       name_ar: "مسار أكروبرانش",      slug: "parcours-accrobranche",  icon: "forest",             order: 47 },
      { category: "sports-activites-loisirs", name: "Parcs aquatiques",            name_ar: "حدائق مائية",         slug: "parcs-aquatiques",       icon: "pool",               order: 48 },
      { category: "sports-activites-loisirs", name: "Parcs à trampolines",         name_ar: "حدائق الترامبولين",   slug: "parcs-trampolines",      icon: "attractions",        order: 49 },
      { category: "sports-activites-loisirs", name: "Parcs de loisirs",            name_ar: "حدائق الترفيه",       slug: "parcs-loisirs",          icon: "park",               order: 50 },
      { category: "sports-activites-loisirs", name: "Parcs d'attraction",          name_ar: "مدن ترفيهية",         slug: "parcs-attraction",       icon: "attractions",        order: 51 },
      { category: "sports-activites-loisirs", name: "Patinoire",                   name_ar: "حلقة تزلج",           slug: "patinoire",              icon: "sports",             order: 52 },
      { category: "sports-activites-loisirs", name: "Pétanque",                    name_ar: "بيتانك",              slug: "petanque",               icon: "sports",             order: 53 },
      { category: "sports-activites-loisirs", name: "Pêche",                       name_ar: "صيد السمك",           slug: "peche",                  icon: "phishing",           order: 54 },
      { category: "sports-activites-loisirs", name: "Salle de sport",              name_ar: "قاعة رياضة",          slug: "salle-sport-sal",        icon: "fitness_center",     order: 55 },
      { category: "sports-activites-loisirs", name: "Piscine",                     name_ar: "مسبح",                slug: "piscine-sal",            icon: "pool",               order: 56 },
      { category: "sports-activites-loisirs", name: "Plage privée",                name_ar: "شاطئ خاص",            slug: "plage-privee-sal",       icon: "beach_access",       order: 57 },
      { category: "sports-activites-loisirs", name: "Tennis",                      name_ar: "تنس",                 slug: "tennis",                 icon: "sports_tennis",      order: 58 },
      { category: "sports-activites-loisirs", name: "Yoga & Méditation",           name_ar: "يوغا وتأمل",          slug: "yoga-meditation",        icon: "self_improvement",   order: 59 },
      { category: "sports-activites-loisirs", name: "Ziplining",                   name_ar: "تيروليان",            slug: "ziplining",              icon: "paragliding",        order: 60 },

      // ==================== SERVICES DESTINÉS AUX PROFESSIONNELS ====================
      { category: "services-destines-professionnels", name: "Avocat",               name_ar: "محامي",        slug: "avocat-sdp",         icon: "gavel",                 order: 1 },
      { category: "services-destines-professionnels", name: "Notaire",              name_ar: "موثق",         slug: "notaire-sdp",        icon: "description",           order: 2 },
      { category: "services-destines-professionnels", name: "Comptable",            name_ar: "محاسب",        slug: "comptable-sdp",      icon: "calculate",             order: 3 },
      { category: "services-destines-professionnels", name: "Architecte",           name_ar: "مهندس",        slug: "architecte-sdp",     icon: "architecture",          order: 4 },
      { category: "services-destines-professionnels", name: "Imprimerie",           name_ar: "مطبعة",        slug: "imprimerie-sdp",     icon: "print",                 order: 5 },
      { category: "services-destines-professionnels", name: "Agence de pub",        name_ar: "وكالة إشهار", slug: "agence-pub",         icon: "campaign",              order: 6 },
      { category: "services-destines-professionnels", name: "Location bureaux",     name_ar: "تأجير مكاتب", slug: "location-bureaux",   icon: "business",              order: 7 },
      { category: "services-destines-professionnels", name: "Logistique",           name_ar: "لوجستيك",      slug: "logistique",         icon: "local_shipping",        order: 8 },

      // ==================== HÔTELS & SÉJOURS ====================
      { category: "hotels-sejours", name: "Hôtel",             name_ar: "فندق",         slug: "hotel-hs",           icon: "hotel",           order: 1 },
      { category: "hotels-sejours", name: "Appart-hôtel",      name_ar: "شقة فندقية",   slug: "appart-hotel-hs",    icon: "apartment",       order: 2 },
      { category: "hotels-sejours", name: "Maison d'hôtes",    name_ar: "دار ضيافة",    slug: "maison-hotes-hs",    icon: "cottage",         order: 3 },
      { category: "hotels-sejours", name: "Location vacances", name_ar: "إيجار عطلة",   slug: "location-vacances-hs",icon: "holiday_village",order: 4 },
      { category: "hotels-sejours", name: "Auberge de jeunesse",name_ar: "نزل الشباب",  slug: "auberge-jeunesse",   icon: "night_shelter",   order: 5 },
      { category: "hotels-sejours", name: "Camping",           name_ar: "تخييم",        slug: "camping",            icon: "cabin",           order: 6 },
      { category: "hotels-sejours", name: "Riad",              name_ar: "رياض",         slug: "riad",               icon: "villa",           order: 7 },
      { category: "hotels-sejours", name: "Villa & Chalet",    name_ar: "فيلا وشاليه",  slug: "villa-chalet",       icon: "house",           order: 8 },

      // ==================== FORMATION & ENSEIGNEMENT ====================
      { category: "formation-enseignement", name: "Auto-école",          name_ar: "مدرسة سياقة",   slug: "auto-ecole-fe",      icon: "directions_car",  order: 1 },
      { category: "formation-enseignement", name: "École de langues",    name_ar: "مدرسة لغات",    slug: "ecole-langues-fe",   icon: "translate",       order: 2 },
      { category: "formation-enseignement", name: "Centre de formation", name_ar: "مركز تكوين",    slug: "centre-formation-fe",icon: "school",          order: 3 },
      { category: "formation-enseignement", name: "Cours particuliers",  name_ar: "دروس خصوصية",   slug: "cours-particuliers-fe",icon: "person",         order: 4 },
      { category: "formation-enseignement", name: "École privée",        name_ar: "مدرسة خاصة",    slug: "ecole-privee-fe",    icon: "account_balance", order: 5 },
      { category: "formation-enseignement", name: "Université",          name_ar: "جامعة",          slug: "universite",         icon: "school",          order: 6 },
      { category: "formation-enseignement", name: "Formation en ligne",  name_ar: "تعلم عن بعد",   slug: "formation-en-ligne", icon: "laptop",          order: 7 },
      { category: "formation-enseignement", name: "Crèche & Garderie",   name_ar: "حضانة",          slug: "creche-fe",          icon: "child_friendly",  order: 8 },

      // ==================== ANIMAUX DE COMPAGNIE ====================
      { category: "animaux-compagnie", name: "Vétérinaire",        name_ar: "طبيب بيطري",   slug: "veterinaire",        icon: "pets",              order: 1 },
      { category: "animaux-compagnie", name: "Animalerie",         name_ar: "محل حيوانات",  slug: "animalerie",         icon: "storefront",        order: 2 },
      { category: "animaux-compagnie", name: "Toilettage",         name_ar: "تزيين الحيوان",slug: "toilettage",         icon: "content_cut",       order: 3 },
      { category: "animaux-compagnie", name: "Pension & Garderie", name_ar: "دار إيواء",    slug: "pension-animaux",    icon: "house",             order: 4 },
      { category: "animaux-compagnie", name: "Dressage",           name_ar: "تدريب",        slug: "dressage",           icon: "sports",            order: 5 },

      // ==================== SERVICES FINANCIERS ====================
      { category: "services-financiers", name: "Banque",             name_ar: "بنك",          slug: "banque",             icon: "account_balance",   order: 1 },
      { category: "services-financiers", name: "Assurance",          name_ar: "تأمين",        slug: "assurance-sf",       icon: "security",          order: 2 },
      { category: "services-financiers", name: "Transfert d'argent", name_ar: "تحويل أموال", slug: "transfert-argent",   icon: "payments",          order: 3 },
      { category: "services-financiers", name: "Bureau de change",   name_ar: "مكتب صرف",    slug: "bureau-change",      icon: "currency_exchange", order: 4 },
      { category: "services-financiers", name: "Courtier crédit",    name_ar: "وسيط قروض",   slug: "courtier-credit",    icon: "request_quote",     order: 5 },
      { category: "services-financiers", name: "Comptabilité",       name_ar: "محاسبة",       slug: "comptabilite-sf",    icon: "calculate",         order: 6 },

      // ==================== COULEUR LOCALE ====================
      { category: "couleur-locale", name: "Artisanat local",         name_ar: "صناعة محلية",  slug: "artisanat-local",    icon: "handyman",          order: 1 },
      { category: "couleur-locale", name: "Marché traditionnel",     name_ar: "سوق تقليدي",   slug: "marche-traditionnel",icon: "festival",          order: 2 },
      { category: "couleur-locale", name: "Cuisine traditionnelle",  name_ar: "مطبخ تقليدي",  slug: "cuisine-traditionnelle",icon: "restaurant",     order: 3 },
      { category: "couleur-locale", name: "Site historique",         name_ar: "موقع تاريخي",  slug: "site-historique",    icon: "account_balance",   order: 4 },
      { category: "couleur-locale", name: "Folklore & Fêtes",        name_ar: "تراث وأعياد",  slug: "folklore-fetes",     icon: "celebration",       order: 5 },

      // ==================== SERVICES PUBLICS ET GOUVERNEMENTAUX ====================
      { category: "services-publics-gouvernementaux", name: "Mairie & Administration",name_ar: "البلدية",      slug: "mairie",              icon: "account_balance",   order: 1 },
      { category: "services-publics-gouvernementaux", name: "Police",               name_ar: "شرطة",          slug: "police",              icon: "local_police",      order: 2 },
      { category: "services-publics-gouvernementaux", name: "Pompiers",             name_ar: "إطفاء",         slug: "pompiers",            icon: "fire_truck",        order: 3 },
      { category: "services-publics-gouvernementaux", name: "Poste",               name_ar: "بريد",           slug: "poste",               icon: "local_post_office", order: 4 },
      { category: "services-publics-gouvernementaux", name: "Ambassade & Consulat",name_ar: "سفارة وقنصلية", slug: "ambassade-consulat",  icon: "flag",              order: 5 },
      { category: "services-publics-gouvernementaux", name: "Service des impôts",  name_ar: "الضرائب",        slug: "service-impots",      icon: "receipt",           order: 6 },

      // ==================== MÉDIA ====================
      { category: "media", name: "Télévision",       name_ar: "تلفزيون",  slug: "television",    icon: "tv",            order: 1 },
      { category: "media", name: "Radio",             name_ar: "راديو",    slug: "radio",         icon: "radio",         order: 2 },
      { category: "media", name: "Journal & Presse",  name_ar: "صحافة",    slug: "journal-presse",icon: "newspaper",     order: 3 },
      { category: "media", name: "Agence de presse",  name_ar: "وكالة أنباء",slug: "agence-presse",icon: "campaign",     order: 4 },
      { category: "media", name: "Studio photo/vidéo",name_ar: "استوديو",  slug: "studio-photo",  icon: "photo_camera",  order: 5 },

      // ==================== ORGANISATION RELIGIEUSE ====================
      { category: "organisation-religieuse", name: "Mosquée",           name_ar: "مسجد",            slug: "mosquee",           icon: "mosque",    order: 1 },
      { category: "organisation-religieuse", name: "Église",            name_ar: "كنيسة",           slug: "eglise",            icon: "church",    order: 2 },
      { category: "organisation-religieuse", name: "Synagogue",         name_ar: "كنيس",            slug: "synagogue",         icon: "synagogue", order: 3 },
      { category: "organisation-religieuse", name: "Temple Hindou",     name_ar: "معبد هندوسي",     slug: "temple-hindou",     icon: "temple_hindu",order: 4 },
      { category: "organisation-religieuse", name: "Temple bouddhiste", name_ar: "معبد بوذي",       slug: "temple-bouddhiste", icon: "temple_buddhist",order: 5 },
      { category: "organisation-religieuse", name: "Temples sikh",      name_ar: "معبد سيخي",       slug: "temples-sikh",      icon: "temple_buddhist",order: 6 },

      // ==================== SANTÉ & MÉDICAL ====================
      { category: "sante-medical", name: "Médecin généraliste",  name_ar: "طبيب عام",         slug: "medecin-sm",       icon: "medical_services",  order: 1 },
      { category: "sante-medical", name: "Dentiste",             name_ar: "طبيب أسنان",       slug: "dentiste-sm",      icon: "dentistry",         order: 2 },
      { category: "sante-medical", name: "Pharmacie",            name_ar: "صيدلية",           slug: "pharmacie-sm",     icon: "local_pharmacy",    order: 3 },
      { category: "sante-medical", name: "Clinique",             name_ar: "عيادة",            slug: "clinique-sm",      icon: "local_hospital",    order: 4 },
      { category: "sante-medical", name: "Ophtalmologue",        name_ar: "طبيب عيون",        slug: "ophtalmologue-sm", icon: "visibility",        order: 5 },
      { category: "sante-medical", name: "Pédiatre",             name_ar: "طبيب أطفال",       slug: "pediatre-sm",      icon: "child_care",        order: 6 },
      { category: "sante-medical", name: "Laboratoire",          name_ar: "مختبر",            slug: "laboratoire-sm",   icon: "biotech",           order: 7 },
      { category: "sante-medical", name: "Kinésithérapeute",     name_ar: "علاج طبيعي",       slug: "kinesitherapeute-sm",icon: "physical_therapy",order: 8 },
      { category: "sante-medical", name: "Gynécologue",          name_ar: "طبيب نساء",        slug: "gynecologue-sm",   icon: "pregnant_woman",    order: 9 },
      { category: "sante-medical", name: "Psychiatre & Psychologue",name_ar: "طبيب نفسي",    slug: "psychiatre-sm",    icon: "psychology",        order: 10 },
      { category: "sante-medical", name: "Centre de dialyse",    name_ar: "مركز غسيل الكلى", slug: "dialyse",          icon: "healing",           order: 11 },
      { category: "sante-medical", name: "Urgences",             name_ar: "مستعجلات",         slug: "urgences",         icon: "emergency",         order: 12 },
    ];

    const subsToInsert = newSubcategories
      .filter((s) => catMap[s.category])
      .map((s) => ({
        id: uuidv4(),
        category_id: catMap[s.category],
        name: s.name,
        name_ar: s.name_ar,
        name_en: s.name,
        slug: s.slug,
        icon: s.icon,
        is_active: true,
        order: s.order,
        created_at: now,
        updated_at: now,
      }));

    await queryInterface.bulkInsert("subcategories", subsToInsert, {
      ignoreDuplicates: true,
    });
  },

  async down(queryInterface, Sequelize) {
    const slugsToDelete = [
      "vie-nocturne","shopping","alimentation","salons-beaute-spas",
      "maison-travaux","services-locaux","organisation-evenements","art-loisirs",
      "sports-activites-loisirs","services-destines-professionnels","hotels-sejours",
      "formation-enseignement","animaux-compagnie","services-financiers",
      "couleur-locale","services-publics-gouvernementaux","media",
      "organisation-religieuse","sante-medical",
    ];
    await queryInterface.bulkDelete(
      "categories",
      { slug: slugsToDelete },
      {}
    );
  },
};
