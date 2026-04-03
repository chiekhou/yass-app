"use strict";
const { v4: uuidv4 } = require("uuid");

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const now = new Date();

    // Get partners with their user info
    const partners = await queryInterface.sequelize.query(
      `SELECT p.id as partner_id, p.company_name, u.wilaya_id 
       FROM partners p 
       JOIN users u ON p.user_id = u.id 
       WHERE p.status = 'approved';`,
      { type: Sequelize.QueryTypes.SELECT },
    );

    // Get categories and subcategories
    const categories = await queryInterface.sequelize.query(
      `SELECT id, slug FROM categories;`,
      { type: Sequelize.QueryTypes.SELECT },
    );
    const catMap = {};
    categories.forEach((c) => {
      catMap[c.slug] = c.id;
    });

    const subcategories = await queryInterface.sequelize.query(
      `SELECT id, slug, category_id FROM subcategories;`,
      { type: Sequelize.QueryTypes.SELECT },
    );
    const subMap = {};
    subcategories.forEach((s) => {
      subMap[s.slug] = { id: s.id, category_id: s.category_id };
    });

    // Get wilayas and communes
    const wilayas = await queryInterface.sequelize.query(
      `SELECT id, code FROM wilayas;`,
      { type: Sequelize.QueryTypes.SELECT },
    );
    const wilayaMap = {};
    wilayas.forEach((w) => {
      wilayaMap[w.code] = w.id;
    });

    const communes = await queryInterface.sequelize.query(
      `SELECT id, code, wilaya_id FROM communes;`,
      { type: Sequelize.QueryTypes.SELECT },
    );
    const communeMap = {};
    communes.forEach((c) => {
      communeMap[c.code] = { id: c.id, wilaya_id: c.wilaya_id };
    });

    // Get partner map by company name
    const partnerMap = {};
    partners.forEach((p) => {
      partnerMap[p.company_name] = { id: p.partner_id, wilaya_id: p.wilaya_id };
    });

    // Opening hours templates
    const standardHours = {
      monday: { open: "08:00", close: "18:00", is_closed: false },
      tuesday: { open: "08:00", close: "18:00", is_closed: false },
      wednesday: { open: "08:00", close: "18:00", is_closed: false },
      thursday: { open: "08:00", close: "18:00", is_closed: false },
      friday: { open: "08:00", close: "12:00", is_closed: false },
      saturday: { open: "08:00", close: "18:00", is_closed: false },
      sunday: { is_closed: true },
    };

    const restaurantHours = {
      monday: { open: "11:00", close: "23:00", is_closed: false },
      tuesday: { open: "11:00", close: "23:00", is_closed: false },
      wednesday: { open: "11:00", close: "23:00", is_closed: false },
      thursday: { open: "11:00", close: "23:00", is_closed: false },
      friday: { open: "13:00", close: "23:00", is_closed: false },
      saturday: { open: "11:00", close: "23:30", is_closed: false },
      sunday: { open: "11:00", close: "22:00", is_closed: false },
    };

    const hotelHours = {
      monday: { open: "00:00", close: "23:59", is_closed: false },
      tuesday: { open: "00:00", close: "23:59", is_closed: false },
      wednesday: { open: "00:00", close: "23:59", is_closed: false },
      thursday: { open: "00:00", close: "23:59", is_closed: false },
      friday: { open: "00:00", close: "23:59", is_closed: false },
      saturday: { open: "00:00", close: "23:59", is_closed: false },
      sunday: { open: "00:00", close: "23:59", is_closed: false },
    };

    const establishments = [
      // ==================== ALGER ====================
      {
        partner: "Restaurant El Djazair",
        name: "Restaurant El Djazair",
        name_ar: "مطعم الجزائر",
        slug: "restaurant-el-djazair-alger",
        description:
          "Restaurant traditionnel algérien proposant les meilleures spécialités locales. Couscous, tajines, grillades et pâtisseries orientales dans une ambiance chaleureuse.",
        description_ar:
          "مطعم جزائري تقليدي يقدم أفضل الأطباق المحلية. كسكس، طواجن، مشاوي وحلويات شرقية في جو دافئ.",
        subcategory: "restaurant-traditionnel",
        commune: "1601",
        address: "15 Rue Didouche Mourad, Alger Centre",
        address_ar: "15 شارع ديدوش مراد، الجزائر الوسطى",
        latitude: 36.7731,
        longitude: 3.0589,
        phone: "023456789",
        whatsapp: "0551234567",
        opening_hours: restaurantHours,
        price_range: "$$",
        services: ["Livraison", "Sur place", "À emporter", "Réservation"],
        amenities: ["WiFi gratuit", "Climatisation", "Parking", "Terrasse"],
        tags: ["couscous", "traditionnel", "familial", "halal"],
        logo: "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&h=600&fit=crop",
        ],
      },
      {
        partner: "Salon de Coiffure Nour",
        name: "Salon de Coiffure Nour",
        name_ar: "صالون نور للحلاقة",
        slug: "salon-coiffure-nour-alger",
        description:
          "Salon de coiffure pour femmes proposant coupe, coloration, brushing, soins capillaires et maquillage. Équipe professionnelle et produits de qualité.",
        description_ar:
          "صالون حلاقة للنساء يقدم قص، صبغة، تجفيف، عناية بالشعر ومكياج. فريق محترف ومنتجات عالية الجودة.",
        subcategory: "coiffure-femme",
        commune: "1612",
        address: "45 Avenue Ali Khodja, Hydra",
        address_ar: "45 شارع علي خوجة، حيدرة",
        latitude: 36.7453,
        longitude: 3.0239,
        phone: "023567890",
        whatsapp: "0552345678",
        opening_hours: standardHours,
        price_range: "$$$",
        services: ["Coupe", "Coloration", "Brushing", "Maquillage", "Soins"],
        amenities: ["Climatisation", "Parking"],
        tags: ["coiffure femme", "maquillage", "soins"],
        logo: "https://images.unsplash.com/photo-1560066984-138dadb4c035?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1562322140-8baeececf3df?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800&h=600&fit=crop",
        ],
      },
      {
        partner: "Location Auto Plus",
        name: "Location Auto Plus",
        name_ar: "تأجير السيارات بلس",
        slug: "location-auto-plus-alger",
        description:
          "Agence de location de voitures proposant une large gamme de véhicules : citadines, berlines, SUV, utilitaires. Location courte et longue durée.",
        description_ar:
          "وكالة تأجير سيارات تقدم مجموعة واسعة من المركبات: سيارات صغيرة، سيدان، SUV، نفعية. إيجار قصير وطويل الأجل.",
        subcategory: "location-voitures",
        commune: "1620",
        address: "Zone industrielle, Dar El Beïda",
        address_ar: "المنطقة الصناعية، الدار البيضاء",
        latitude: 36.7167,
        longitude: 3.2167,
        phone: "023678901",
        whatsapp: "0557890123",
        opening_hours: standardHours,
        price_range: "$$",
        services: [
          "Location courte durée",
          "Location longue durée",
          "Livraison",
          "Assurance",
        ],
        amenities: ["Parking", "Climatisation"],
        tags: ["location voiture", "voiture", "transport"],
        logo: "https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1485291571150-772bcfc10da5?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1502877338535-766e1452684a?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1489824904134-891ab64532f1?w=800&h=600&fit=crop",
        ],
      },
      {
        partner: "Spa & Hammam Relaxation",
        name: "Spa & Hammam Relaxation",
        name_ar: "سبا وحمام الاسترخاء",
        slug: "spa-hammam-relaxation-alger",
        description:
          "Spa et hammam traditionnel offrant une expérience de détente complète. Hammam, gommage, massage, soins du visage et du corps.",
        description_ar:
          "سبا وحمام تقليدي يقدم تجربة استرخاء كاملة. حمام، تقشير، تدليك، عناية بالوجه والجسم.",
        subcategory: "spa-hammam",
        commune: "1611",
        address: "23 Rue des Frères Bouadou, El Biar",
        address_ar: "23 شارع الإخوة بوعدو، الأبيار",
        latitude: 36.7689,
        longitude: 3.0308,
        phone: "023789012",
        whatsapp: "0559012345",
        opening_hours: {
          monday: { open: "09:00", close: "21:00", is_closed: false },
          tuesday: { open: "09:00", close: "21:00", is_closed: false },
          wednesday: { open: "09:00", close: "21:00", is_closed: false },
          thursday: { open: "09:00", close: "21:00", is_closed: false },
          friday: { open: "14:00", close: "21:00", is_closed: false },
          saturday: { open: "09:00", close: "21:00", is_closed: false },
          sunday: { open: "09:00", close: "18:00", is_closed: false },
        },
        price_range: "$$$",
        services: [
          "Hammam",
          "Gommage",
          "Massage",
          "Soins visage",
          "Soins corps",
        ],
        amenities: ["Climatisation", "Parking", "Vestiaires"],
        tags: ["spa", "hammam", "massage", "détente", "bien-être"],
        logo: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1507652313519-d4e9174996dd?w=800&h=600&fit=crop",
        ],
      },

      // ==================== ORAN ====================
      {
        partner: "Garage Auto Amine",
        name: "Garage Auto Amine",
        name_ar: "ورشة أمين للسيارات",
        slug: "garage-auto-amine-oran",
        description:
          "Garage automobile offrant tous les services de réparation et entretien : mécanique générale, électricité auto, climatisation, vidange, freins.",
        description_ar:
          "ورشة سيارات تقدم جميع خدمات الإصلاح والصيانة: ميكانيك عامة، كهرباء السيارات، تكييف، تغيير الزيت، فرامل.",
        subcategory: "garage-mecanique",
        commune: "3101",
        address: "78 Boulevard de l'ANP, Oran",
        address_ar: "78 شارع الجيش الوطني الشعبي، وهران",
        latitude: 35.6969,
        longitude: -0.6331,
        phone: "041234567",
        whatsapp: "0553456789",
        opening_hours: standardHours,
        price_range: "$$",
        services: [
          "Mécanique générale",
          "Électricité",
          "Climatisation",
          "Vidange",
          "Freins",
          "Diagnostic",
        ],
        amenities: ["Parking", "Salle d'attente"],
        tags: ["garage", "mécanique", "réparation", "entretien"],
        logo: "https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1625047509248-ec889cbff17f?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1530046339160-ce3e530c7d2f?w=800&h=600&fit=crop",
        ],
      },
      {
        partner: "Pizza Napoli",
        name: "Pizza Napoli Oran",
        name_ar: "بيتزا نابولي وهران",
        slug: "pizza-napoli-oran",
        description:
          "Pizzeria italienne authentique proposant des pizzas cuites au feu de bois, pâtes fraîches et desserts italiens. Livraison gratuite.",
        description_ar:
          "بيتزيريا إيطالية أصيلة تقدم بيتزا مطهية على الحطب، معكرونة طازجة وحلويات إيطالية. توصيل مجاني.",
        subcategory: "pizzeria",
        commune: "3103",
        address: "12 Avenue Larbi Ben M'hidi, Bir El Djir",
        address_ar: "12 شارع العربي بن مهيدي، بئر الجير",
        latitude: 35.7167,
        longitude: -0.55,
        phone: "041345678",
        whatsapp: "0558901234",
        opening_hours: restaurantHours,
        price_range: "$$",
        services: ["Sur place", "Livraison", "À emporter"],
        amenities: ["WiFi gratuit", "Climatisation", "Parking"],
        tags: ["pizza", "italien", "livraison", "pâtes"],
        logo: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1579751626657-72bc17010498?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1595854341625-f33ee10dbf94?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1555072956-7758afb20e8f?w=800&h=600&fit=crop",
        ],
      },

      // ==================== CONSTANTINE ====================
      {
        partner: "Hôtel Cirta Palace",
        name: "Hôtel Cirta Palace",
        name_ar: "فندق سيرتا بالاس",
        slug: "hotel-cirta-palace-constantine",
        description:
          "Hôtel 4 étoiles au cœur de Constantine avec vue panoramique sur les gorges du Rhumel. Chambres luxueuses, restaurant gastronomique, spa et salle de conférence.",
        description_ar:
          "فندق 4 نجوم في قلب قسنطينة مع إطلالة بانورامية على وادي الرمال. غرف فاخرة، مطعم راقي، سبا وقاعة مؤتمرات.",
        subcategory: "hotel",
        commune: "2501",
        address: "5 Place du 1er Novembre, Constantine",
        address_ar: "5 ساحة أول نوفمبر، قسنطينة",
        latitude: 36.365,
        longitude: 6.6147,
        phone: "031456789",
        whatsapp: "0554567890",
        email: "contact@cirtapalace.dz",
        website: "https://www.cirtapalace.dz",
        opening_hours: hotelHours,
        price_range: "$$$$",
        services: [
          "Réception 24h/24",
          "Room service",
          "Restaurant",
          "Spa",
          "Salle de conférence",
          "Parking",
        ],
        amenities: [
          "WiFi gratuit",
          "Climatisation",
          "Parking",
          "Piscine",
          "Salle de sport",
          "Restaurant",
        ],
        tags: ["hôtel", "luxe", "4 étoiles", "vue panoramique", "spa"],
        logo: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&h=600&fit=crop",
        ],
      },
      {
        partner: "Salle des Fêtes El Amir",
        name: "Salle des Fêtes El Amir",
        name_ar: "قاعة الحفلات الأمير",
        slug: "salle-fetes-el-amir-constantine",
        description:
          "Salle des fêtes prestigieuse pour mariages, fiançailles et événements. Capacité jusqu'à 500 personnes. Décoration personnalisable, traiteur disponible.",
        description_ar:
          "قاعة حفلات فخمة للأعراس والخطوبة والمناسبات. سعة تصل إلى 500 شخص. ديكور قابل للتخصيص، خدمة تموين متاحة.",
        subcategory: "salle-fetes",
        commune: "2502",
        address: "120 Route de l'Aéroport, El Khroub",
        address_ar: "120 طريق المطار، الخروب",
        latitude: 36.2636,
        longitude: 6.6906,
        phone: "031567890",
        whatsapp: "0560123456",
        opening_hours: {
          monday: { open: "09:00", close: "23:00", is_closed: false },
          tuesday: { open: "09:00", close: "23:00", is_closed: false },
          wednesday: { open: "09:00", close: "23:00", is_closed: false },
          thursday: { open: "09:00", close: "23:00", is_closed: false },
          friday: { open: "09:00", close: "23:00", is_closed: false },
          saturday: { open: "09:00", close: "23:00", is_closed: false },
          sunday: { open: "09:00", close: "23:00", is_closed: false },
        },
        price_range: "$$$",
        services: [
          "Location salle",
          "Décoration",
          "Traiteur",
          "DJ",
          "Photographe",
        ],
        amenities: [
          "Climatisation",
          "Parking",
          "Cuisine équipée",
          "Vestiaires",
        ],
        tags: ["mariage", "fête", "événement", "salle"],
        logo: "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1478146896981-b80fe463b330?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=800&h=600&fit=crop",
        ],
      },

      // ==================== ANNABA ====================
      {
        partner: "Pharmacie Centrale",
        name: "Pharmacie Centrale Annaba",
        name_ar: "الصيدلية المركزية عنابة",
        slug: "pharmacie-centrale-annaba",
        description:
          "Pharmacie de garde proposant médicaments, parapharmacie, produits de beauté, matériel médical. Conseil pharmaceutique personnalisé.",
        description_ar:
          "صيدلية مناوبة تقدم أدوية، منتجات شبه صيدلانية، منتجات تجميل، معدات طبية. استشارة صيدلانية شخصية.",
        subcategory: "pharmacie",
        commune: "2301",
        address: "34 Cours de la Révolution, Annaba",
        address_ar: "34 شارع الثورة، عنابة",
        latitude: 36.9,
        longitude: 7.7667,
        phone: "038456789",
        whatsapp: "0555678901",
        opening_hours: {
          monday: { open: "08:00", close: "20:00", is_closed: false },
          tuesday: { open: "08:00", close: "20:00", is_closed: false },
          wednesday: { open: "08:00", close: "20:00", is_closed: false },
          thursday: { open: "08:00", close: "20:00", is_closed: false },
          friday: { open: "08:00", close: "12:00", is_closed: false },
          saturday: { open: "08:00", close: "20:00", is_closed: false },
          sunday: { open: "09:00", close: "13:00", is_closed: false },
        },
        price_range: "$$",
        services: ["Médicaments", "Parapharmacie", "Conseil", "Livraison"],
        amenities: ["Climatisation", "Parking à proximité"],
        tags: ["pharmacie", "médicaments", "santé", "garde"],
        logo: "https://images.unsplash.com/photo-1576602976047-174e57a47881?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1586015555751-63bb77f4322a?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1585435557343-3b092031a831?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=800&h=600&fit=crop",
        ],
      },

      // ==================== TIZI OUZOU ====================
      {
        partner: "Café Djurdjura",
        name: "Café Djurdjura",
        name_ar: "مقهى جرجرة",
        slug: "cafe-djurdjura-tizi-ouzou",
        description:
          "Café traditionnel kabyle avec vue sur les montagnes du Djurdjura. Café, thé à la menthe, pâtisseries kabyles. Ambiance authentique et conviviale.",
        description_ar:
          "مقهى قبائلي تقليدي مع إطلالة على جبال جرجرة. قهوة، شاي بالنعناع، حلويات قبائلية. جو أصيل وودي.",
        subcategory: "cafe-salon-the",
        commune: "1501",
        address: "8 Boulevard Stiti Ali, Tizi Ouzou",
        address_ar: "8 شارع سطيطي علي، تيزي وزو",
        latitude: 36.7117,
        longitude: 4.0453,
        phone: "026456789",
        whatsapp: "0556789012",
        opening_hours: {
          monday: { open: "06:00", close: "22:00", is_closed: false },
          tuesday: { open: "06:00", close: "22:00", is_closed: false },
          wednesday: { open: "06:00", close: "22:00", is_closed: false },
          thursday: { open: "06:00", close: "22:00", is_closed: false },
          friday: { open: "06:00", close: "22:00", is_closed: false },
          saturday: { open: "06:00", close: "23:00", is_closed: false },
          sunday: { open: "07:00", close: "22:00", is_closed: false },
        },
        price_range: "$",
        services: ["Sur place", "À emporter"],
        amenities: ["WiFi gratuit", "Terrasse", "Vue panoramique"],
        tags: ["café", "thé", "kabyle", "traditionnel", "montagne"],
        logo: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&h=200&fit=crop",
        cover_image: "https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=1200&h=600&fit=crop",
        images: [
          "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1498804103079-a6351b050096?w=800&h=600&fit=crop",
          "https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=800&h=600&fit=crop",
        ],
      },
    ];

    // Build establishments array
    const establishmentsToInsert = establishments.map((est, index) => {
      const partner = partnerMap[est.partner];
      const sub = subMap[est.subcategory];
      const commune = communeMap[est.commune];

      // Validation avec messages d'erreur détaillés
      if (!partner) {
        console.error(`Partner not found: "${est.partner}"`);
        console.error("Available partners:", Object.keys(partnerMap));
        throw new Error(`Partner not found: "${est.partner}"`);
      }
      if (!sub) {
        console.error(`Subcategory not found: "${est.subcategory}"`);
        console.error("Available subcategories:", Object.keys(subMap));
        throw new Error(`Subcategory not found: "${est.subcategory}"`);
      }
      if (!commune) {
        console.error(`Commune not found: "${est.commune}"`);
        console.error("Available communes:", Object.keys(communeMap));
        throw new Error(`Commune not found: "${est.commune}"`);
      }

      // Mark first 5 establishments as featured
      const isFeatured = index < 5;

      return {
        id: uuidv4(),
        partner_id: partner.id,
        category_id: sub.category_id,
        subcategory_id: sub.id,
        wilaya_id: commune.wilaya_id,
        commune_id: commune.id,
        name: est.name,
        name_ar: est.name_ar,
        slug: est.slug,
        description: est.description,
        description_ar: est.description_ar,
        address: est.address,
        address_ar: est.address_ar,
        latitude: est.latitude,
        longitude: est.longitude,
        phone: est.phone,
        whatsapp: est.whatsapp,
        email: est.email || null,
        website: est.website || null,
        logo: est.logo || null,
        cover_image: est.cover_image || null,
        images: JSON.stringify(est.images || []),
        opening_hours: JSON.stringify(est.opening_hours),
        price_range: est.price_range,
        services: JSON.stringify(est.services),
        amenities: JSON.stringify(est.amenities),
        tags: JSON.stringify(est.tags),
        status: "active",
        is_verified: true,
        is_featured: isFeatured,
        average_rating: (3.5 + Math.random() * 1.5).toFixed(2),
        total_reviews: Math.floor(Math.random() * 50) + 5,
        total_views: Math.floor(Math.random() * 1000) + 100,
        total_favorites: Math.floor(Math.random() * 100) + 10,
        created_at: now,
        updated_at: now,
      };
    });

    // Supprimer les anciens établissements avant d'insérer
    await queryInterface.bulkDelete("establishments", null, {});

    await queryInterface.bulkInsert(
      "establishments",
      establishmentsToInsert,
      {},
    );
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete("establishments", null, {});
  },
};
