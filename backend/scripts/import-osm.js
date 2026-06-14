#!/usr/bin/env node
/**
 * import-osm.js
 *
 * Importe le fichier osm-output.json en base de données.
 * Les établissements sont créés avec status="pending" et doivent
 * être approuvés par l'admin avant d'apparaître dans l'app.
 *
 * Usage :
 *   node scripts/import-osm.js
 *   node scripts/import-osm.js --dry-run       (affiche sans insérer)
 *   node scripts/import-osm.js --approve        (status="active" directement)
 *   node scripts/import-osm.js --category=sante (filtre une catégorie)
 *   node scripts/import-osm.js --limit=100      (limite le nombre d'imports)
 */

"use strict";

require("dotenv").config({ path: require("path").join(__dirname, "../.env") });

const fs = require("fs");
const path = require("path");
const { v4: uuidv4 } = require("uuid");
const { Sequelize, DataTypes } = require("sequelize");

// ── Config ────────────────────────────────────────────────────────────────────

const INPUT_FILE = path.join(__dirname, "osm-output.json");

// ── Photos représentatives par catégorie ─────────────────────────────────────
// URLs Unsplash CDN stables (format : ?auto=format&fit=crop&w=800&q=80)
// Chaque catégorie dispose de N groupes de 3 photos → rotation par index
// pour que les établissements d'une même catégorie ne soient pas identiques.
// Remplacez ces URLs par vos propres photos hébergées en production.

const BASE = "https://images.unsplash.com";

const CATEGORY_PHOTOS = {
  restaurants: [
    [
      { url: `${BASE}/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=800&q=80`, category: "plats" },
      { url: `${BASE}/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80`, category: "plats" },
      { url: `${BASE}/photo-1424847651672-bf20a4b0982b?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
    ],
    [
      { url: `${BASE}/photo-1543353071-10c8ba85a904?auto=format&fit=crop&w=800&q=80`, category: "plats" },
      { url: `${BASE}/photo-1537047902294-62a40c20a6ae?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1600891964599-f61ba0e24092?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "beaute-bien-etre": [
    [
      { url: `${BASE}/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1616394584738-fc6e612e71b9?auto=format&fit=crop&w=800&q=80`, category: "produits" },
    ],
    [
      { url: `${BASE}/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
    ],
  ],

  "salons-beaute-spas": [
    [
      { url: `${BASE}/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1616394584738-fc6e612e71b9?auto=format&fit=crop&w=800&q=80`, category: "produits" },
    ],
    [
      { url: `${BASE}/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=800&q=80`, category: "produits" },
    ],
  ],

  sante: [
    [
      { url: `${BASE}/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1538108149393-fbbd81895907?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1516574187841-cb9cc2ca948b?auto=format&fit=crop&w=800&q=80`, category: "salle" },
    ],
    [
      { url: `${BASE}/photo-1551076805-e1869033e561?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1584820927498-cfe5211fd8bf?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "sante-medical": [
    [
      { url: `${BASE}/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1538108149393-fbbd81895907?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1516574187841-cb9cc2ca948b?auto=format&fit=crop&w=800&q=80`, category: "salle" },
    ],
  ],

  automobile: [
    [
      { url: `${BASE}/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1562141961-b6b02e037e7c?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1517994112540-009c47ea476b?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  hebergement: [
    [
      { url: `${BASE}/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1445019980597-93fa8acb246c?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1631049307264-da0ec9d70304?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1551882547-ff40c63fe2e2?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1609949279531-cf48d64bed89?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "hotels-sejours": [
    [
      { url: `${BASE}/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1445019980597-93fa8acb246c?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "activites-loisirs": [
    [
      { url: `${BASE}/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1459865264687-595d652de67e?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1530549387789-4c1017266635?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
    ],
    [
      { url: `${BASE}/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1574680178050-55c6a6a96e0a?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1598971861-2a3f9d73bcc3?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "sports-activites-loisirs": [
    [
      { url: `${BASE}/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1459865264687-595d652de67e?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1530549387789-4c1017266635?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
    ],
  ],

  "maison-services": [
    [
      { url: `${BASE}/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
    ],
  ],

  "maison-travaux": [
    [
      { url: `${BASE}/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  commerces: [
    [
      { url: `${BASE}/photo-1555529669-e69e7aa0ba9a?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1604719312566-8912e9c8a213?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1546213290-e1b492ab3eee?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  shopping: [
    [
      { url: `${BASE}/photo-1555529669-e69e7aa0ba9a?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1604719312566-8912e9c8a213?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  alimentation: [
    [
      { url: `${BASE}/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1608686207856-001b95cf60ca?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1506617564039-2f3b650b7010?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1534483509719-3feaee7c30da?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1518977956812-cd3dbadaaf31?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1550989460-0adf9ea622e2?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
    ],
  ],

  "voyage-tourisme": [
    [
      { url: `${BASE}/photo-1488085061387-422e29b40080?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80`, category: "autres" },
    ],
    [
      { url: `${BASE}/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1530521954074-e64f6810b32d?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1501555088652-021faa106b9b?auto=format&fit=crop&w=800&q=80`, category: "autres" },
    ],
  ],

  // alias possible dans le JSON OSM
  "voyages-tourisme": [
    [
      { url: `${BASE}/photo-1488085061387-422e29b40080?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80`, category: "autres" },
    ],
  ],

  "services-professionnels": [
    [
      { url: `${BASE}/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1521737604893-d14cc237f11d?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1600880292203-757bb62b4baf?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
    [
      { url: `${BASE}/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1542744173-8e7e53415bb0?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "services-destines-professionnels": [
    [
      { url: `${BASE}/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1521737604893-d14cc237f11d?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1600880292203-757bb62b4baf?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "formation-enseignement": [
    [
      { url: `${BASE}/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  education: [
    [
      { url: `${BASE}/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  evenements: [
    [
      { url: `${BASE}/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1501281668745-f7f57925c3b4?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "organisation-evenements": [
    [
      { url: `${BASE}/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=800&q=80`, category: "salle" },
      { url: `${BASE}/photo-1501281668745-f7f57925c3b4?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "vie-nocturne": [
    [
      { url: `${BASE}/photo-1574391884720-bbc3740c59d1?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1514214246283-d8a8d4b81f3f?auto=format&fit=crop&w=800&q=80`, category: "bar" },
      { url: `${BASE}/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
    ],
  ],

  "art-loisirs": [
    [
      { url: `${BASE}/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1534430480872-3498386e7856?auto=format&fit=crop&w=800&q=80`, category: "ambiance" },
      { url: `${BASE}/photo-1460661419201-fd4cecdf8a8b?auto=format&fit=crop&w=800&q=80`, category: "produits" },
    ],
  ],

  "animaux-compagnie": [
    [
      { url: `${BASE}/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1548767797-d8c844163c4a?auto=format&fit=crop&w=800&q=80`, category: "produits" },
      { url: `${BASE}/photo-1601758003122-53c40e686a19?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    ],
  ],

  "services-financiers": [
    [
      { url: `${BASE}/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
      { url: `${BASE}/photo-1601597111158-2fceff292cdc?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
      { url: `${BASE}/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=800&q=80`, category: "salle" },
    ],
  ],
};

// Fallback générique si le slug n'est pas dans la map
const FALLBACK_PHOTOS = [
  [
    { url: `${BASE}/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80`, category: "interieur" },
    { url: `${BASE}/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80`, category: "exterieur" },
    { url: `${BASE}/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=800&q=80`, category: "autres" },
  ],
];

/**
 * Retourne 3 PhotoItem pour un slug donné.
 * @param {string} slug   - slug de catégorie de l'établissement
 * @param {number} index  - index de l'établissement dans la boucle (rotation)
 */
function getPhotosForCategory(slug, index) {
  const groups = CATEGORY_PHOTOS[slug] || FALLBACK_PHOTOS;
  return groups[index % groups.length].map((p) => ({ ...p, type: "photo" }));
}

const args = process.argv.slice(2);
const DRY_RUN = args.includes("--dry-run");
const APPROVE = args.includes("--approve");
const argCategory = args.find((a) => a.startsWith("--category="))?.split("=")[1];
const argLimit = parseInt(args.find((a) => a.startsWith("--limit="))?.split("=")[1] || "0");

// ── DB Setup ──────────────────────────────────────────────────────────────────

const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: "postgres",
  logging: false,
  dialectOptions: process.env.DATABASE_URL?.includes("ssl")
    ? { ssl: { require: true, rejectUnauthorized: false } }
    : {},
});

// ── Main ───────────────────────────────────────────────────────────────────────

async function main() {
  if (!fs.existsSync(INPUT_FILE)) {
    console.error(`❌  Fichier introuvable: ${INPUT_FILE}`);
    console.error(`   Lance d'abord: node scripts/extract-osm-algeria.js`);
    process.exit(1);
  }

  const input = JSON.parse(fs.readFileSync(INPUT_FILE, "utf8"));
  let establishments = input.establishments || [];

  console.log(`📥  Fichier lu: ${establishments.length} établissements`);
  console.log(`   Extrait le : ${input.extracted_at}`);
  console.log(`   Filtre     : ${input.filter_wilaya} / ${input.filter_category}\n`);

  // Filtres supplémentaires
  if (argCategory) {
    establishments = establishments.filter((e) => e.category_slug === argCategory);
    console.log(`   Filtre catégorie "${argCategory}": ${establishments.length} restants`);
  }
  if (argLimit > 0) {
    establishments = establishments.slice(0, argLimit);
    console.log(`   Limite: ${establishments.length} établissements`);
  }

  if (DRY_RUN) {
    console.log(`\n🔍  DRY RUN — aucune insertion en base\n`);
    const sample = establishments.slice(0, 5);
    sample.forEach((e, i) => {
      console.log(`  [${i + 1}] ${e.name}`);
      console.log(`       Catégorie : ${e.category_slug}`);
      console.log(`       Adresse   : ${e.address || "(non renseignée)"}`);
      console.log(`       GPS       : ${e.latitude}, ${e.longitude}`);
      console.log(`       Tél       : ${e.phone || "—"}`);
    });
    if (establishments.length > 5) {
      console.log(`  ... et ${establishments.length - 5} autres`);
    }
    console.log(`\nTotal qui serait importé : ${establishments.length}`);
    return;
  }

  // ── Connexion DB ─────────────────────────────────────────────────────────────
  await sequelize.authenticate();
  console.log(`✅  Connecté à la base de données\n`);

  // Récupérer les IDs des catégories
  const [catRows] = await sequelize.query(
    "SELECT id, slug FROM categories WHERE is_active = true"
  );
  const catMap = {};
  catRows.forEach((r) => (catMap[r.slug] = r.id));

  // Récupérer les IDs des wilayas (pour matching par nom de ville)
  const [wilayaRows] = await sequelize.query(
    "SELECT id, name, code FROM wilayas"
  );

  // Récupérer l'ID du premier admin pour "partner" fictif OSM
  const [adminRows] = await sequelize.query(
    "SELECT id FROM users WHERE role = 'admin' LIMIT 1"
  );
  const adminId = adminRows[0]?.id;
  if (!adminId) {
    throw new Error("Aucun admin trouvé en base");
  }

  // Récupérer ou créer un partenaire OSM fictif
  let [partnerRows] = await sequelize.query(
    "SELECT id FROM partners WHERE user_id = $1 LIMIT 1",
    { bind: [adminId] }
  );
  let partnerId = partnerRows[0]?.id;

  if (!partnerId) {
    const newPartnerId = uuidv4();
    await sequelize.query(
      `INSERT INTO partners (id, user_id, company_name, status, created_at, updated_at)
       VALUES ($1, $2, 'OSM Import', 'approved', NOW(), NOW())`,
      { bind: [newPartnerId, adminId] }
    );
    partnerId = newPartnerId;
    console.log(`   Partenaire OSM créé (id: ${partnerId})`);
  }

  // ── Insertion ─────────────────────────────────────────────────────────────────
  const status = APPROVE ? "active" : "pending";
  let inserted = 0;
  let skipped = 0;
  let errors = 0;

  console.log(`⬆️  Import en cours (status="${status}")...\n`);

  for (let estIdx = 0; estIdx < establishments.length; estIdx++) {
    const est = establishments[estIdx];
    const categoryId = catMap[est.category_slug];
    if (!categoryId) {
      skipped++;
      continue;
    }

    // Tenter de matcher la wilaya depuis l'adresse
    let wilayaId = null;
    if (est.address) {
      const addr = est.address.toLowerCase();
      const matched = wilayaRows.find(
        (w) => addr.includes(w.name.toLowerCase()) || addr.includes(w.code)
      );
      if (matched) wilayaId = matched.id;
    }

    // Générer un slug unique
    const baseSlug = est.name
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60);

    const slug = `${baseSlug}-${est.osm_id.replace("/", "-")}`;

    const photos = getPhotosForCategory(est.category_slug, estIdx);
    const coverUrl = photos[0]?.url || null;

    try {
      await sequelize.query(
        `INSERT INTO establishments (
          id, partner_id, category_id, wilaya_id,
          name, slug, address,
          phone, website,
          latitude, longitude,
          status, source,
          images, cover_image,
          created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4,
          $5, $6, $7,
          $8, $9,
          $10, $11,
          $12, 'osm',
          $13::jsonb, $14,
          NOW(), NOW()
        )
        ON CONFLICT (slug) DO NOTHING`,
        {
          bind: [
            uuidv4(),
            partnerId,
            categoryId,
            wilayaId,
            est.name,
            slug,
            est.address || "",
            est.phone,
            est.website,
            est.latitude,
            est.longitude,
            status,
            JSON.stringify(photos),
            coverUrl,
          ],
        }
      );
      inserted++;

      if (inserted % 100 === 0) {
        process.stdout.write(`   ${inserted} insérés...\r`);
      }
    } catch (err) {
      errors++;
      if (errors <= 5) {
        console.error(`   ⚠️  Erreur pour "${est.name}": ${err.message}`);
      }
    }
  }

  console.log(`\n✅  Import terminé`);
  console.log(`   Insérés  : ${inserted}`);
  console.log(`   Ignorés  : ${skipped} (catégorie inconnue)`);
  console.log(`   Erreurs  : ${errors}`);

  if (!APPROVE) {
    console.log(`\n   ℹ️  Les établissements ont status="pending".`);
    console.log(`   Pour les approuver en masse :`);
    console.log(`   UPDATE establishments SET status='active' WHERE source='osm';\n`);
  }

  await sequelize.close();
}

main().catch((err) => {
  console.error("❌  Erreur fatale:", err.message);
  process.exit(1);
});
