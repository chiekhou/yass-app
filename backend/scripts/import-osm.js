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

  for (const est of establishments) {
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

    try {
      await sequelize.query(
        `INSERT INTO establishments (
          id, partner_id, category_id, wilaya_id,
          name, slug, address,
          phone, website,
          latitude, longitude,
          status, source,
          created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4,
          $5, $6, $7,
          $8, $9,
          $10, $11,
          $12, 'osm',
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
