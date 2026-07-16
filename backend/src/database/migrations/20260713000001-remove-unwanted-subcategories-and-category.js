"use strict";

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Supprimer les sous-catégories indésirables
    await queryInterface.bulkDelete(
      "subcategories",
      {
        slug: [
          "tatouage-piercing",   // Salons de beauté & Spas
          "courtier-credit",     // Services financiers
          "temple-hindou",       // Organisation religieuse
          "temple-bouddhiste",   // Organisation religieuse
          "temples-sikh",        // Organisation religieuse
          // Hébergement → fusionné dans Hôtels & séjours (doublons supprimés)
          "hotel",
          "appart-hotel",
          "maison-hotes",
          "location-vacances",
          "auberge",
          // Vie nocturne
          "bar",
          "boite-nuit",
        ],
      },
      {}
    );

    // Supprimer la catégorie Hébergement (remplacée par Hôtels & séjours)
    await queryInterface.bulkDelete(
      "categories",
      { slug: "hebergement" },
      {}
    );

    // ── Fusion Activités & Loisirs + Maison & Services → Activités & Services ──

    // 1. Renommer activites-loisirs → activites-services
    await queryInterface.sequelize.query(`
      UPDATE categories
      SET name = 'Activités & Services',
          name_ar = 'الأنشطة والخدمات',
          name_en = 'Activities & Services',
          slug = 'activites-services',
          description = 'Sport, loisirs, services à domicile',
          description_ar = 'الرياضة والترفيه والخدمات المنزلية',
          updated_at = NOW()
      WHERE slug = 'activites-loisirs';
    `);

    // 2. Réattribuer les sous-catégories de maison-services vers activites-services
    await queryInterface.sequelize.query(`
      UPDATE subcategories
      SET category_id = (SELECT id FROM categories WHERE slug = 'activites-services'),
          updated_at = NOW()
      WHERE category_id = (SELECT id FROM categories WHERE slug = 'maison-services');
    `);

    // 3. Supprimer maison-services (ses sous-catégories ont été transférées)
    await queryInterface.bulkDelete(
      "categories",
      { slug: "maison-services" },
      {}
    );

    // ── Réorganisation de l'ordre d'affichage des catégories ──
    const categoryOrder = [
      { slug: "restaurants",                       order: 1  },
      { slug: "organisation-religieuse",           order: 2  },
      { slug: "activites-services",                order: 3  },
      { slug: "sports-activites-loisirs",          order: 4  },
      { slug: "alimentation",                      order: 5  },
      { slug: "salons-beaute-spas",                order: 6  },
      { slug: "vie-nocturne",                      order: 7  },
      { slug: "shopping",                          order: 8  },
      { slug: "beaute-bien-etre",                  order: 9  },
      { slug: "sante",                             order: 10 },
      { slug: "automobile",                        order: 11 },
      { slug: "commerces",                         order: 12 },
      { slug: "education",                         order: 13 },
      { slug: "services-professionnels",           order: 14 },
      { slug: "voyage-tourisme",                   order: 15 },
      { slug: "evenements",                        order: 16 },
      { slug: "maison-travaux",                    order: 17 },
      { slug: "services-locaux",                   order: 18 },
      { slug: "organisation-evenements",           order: 19 },
      { slug: "art-loisirs",                       order: 20 },
      { slug: "services-destines-professionnels",  order: 21 },
      { slug: "hotels-sejours",                    order: 22 },
      { slug: "formation-enseignement",            order: 23 },
      { slug: "animaux-compagnie",                 order: 24 },
      { slug: "services-financiers",               order: 25 },
      { slug: "couleur-locale",                    order: 26 },
      { slug: "services-publics-gouvernementaux",  order: 27 },
      { slug: "media",                             order: 28 },
      { slug: "sante-medical",                     order: 29 },
    ];

    for (const { slug, order } of categoryOrder) {
      await queryInterface.sequelize.query(
        `UPDATE categories SET "order" = ${order}, updated_at = NOW() WHERE slug = '${slug}';`
      );
    }
  },

  async down(queryInterface, Sequelize) {
    // Pas de rollback automatique — réinsérer manuellement si nécessaire
  },
};
