'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // 1. wilayas
    await queryInterface.createTable('wilayas', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      code: { type: Sequelize.STRING(5), allowNull: false, unique: true },
      name: { type: Sequelize.STRING(100), allowNull: false },
      name_ar: { type: Sequelize.STRING(100), allowNull: false },
      name_en: { type: Sequelize.STRING(100), allowNull: true },
      latitude: { type: Sequelize.DECIMAL(10, 8), allowNull: true },
      longitude: { type: Sequelize.DECIMAL(11, 8), allowNull: true },
      is_active: { type: Sequelize.BOOLEAN, defaultValue: true },
      order: { type: Sequelize.INTEGER, defaultValue: 0 },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });

    // 2. categories
    await queryInterface.createTable('categories', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      name: { type: Sequelize.STRING(100), allowNull: false },
      name_ar: { type: Sequelize.STRING(100), allowNull: false },
      name_en: { type: Sequelize.STRING(100), allowNull: true },
      slug: { type: Sequelize.STRING(120), allowNull: false, unique: true },
      description: { type: Sequelize.TEXT, allowNull: true },
      description_ar: { type: Sequelize.TEXT, allowNull: true },
      icon: { type: Sequelize.STRING(100), allowNull: true },
      image: { type: Sequelize.STRING(500), allowNull: true },
      color: { type: Sequelize.STRING(20), allowNull: true },
      is_active: { type: Sequelize.BOOLEAN, defaultValue: true },
      order: { type: Sequelize.INTEGER, defaultValue: 0 },
      meta_title: { type: Sequelize.STRING(200), allowNull: true },
      meta_description: { type: Sequelize.TEXT, allowNull: true },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });

    // 3. communes (dépend de wilayas)
    await queryInterface.createTable('communes', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      wilaya_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'wilayas', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      code: { type: Sequelize.STRING(10), allowNull: false },
      name: { type: Sequelize.STRING(100), allowNull: false },
      name_ar: { type: Sequelize.STRING(100), allowNull: false },
      name_en: { type: Sequelize.STRING(100), allowNull: true },
      postal_code: { type: Sequelize.STRING(10), allowNull: true },
      latitude: { type: Sequelize.DECIMAL(10, 8), allowNull: true },
      longitude: { type: Sequelize.DECIMAL(11, 8), allowNull: true },
      is_active: { type: Sequelize.BOOLEAN, defaultValue: true },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });
    await queryInterface.sequelize.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS communes_wilaya_id_code ON communes (wilaya_id, code);`
    );

    // 4. subcategories (dépend de categories)
    await queryInterface.createTable('subcategories', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      category_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'categories', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      name: { type: Sequelize.STRING(100), allowNull: false },
      name_ar: { type: Sequelize.STRING(100), allowNull: false },
      name_en: { type: Sequelize.STRING(100), allowNull: true },
      slug: { type: Sequelize.STRING(120), allowNull: false, unique: true },
      description: { type: Sequelize.TEXT, allowNull: true },
      description_ar: { type: Sequelize.TEXT, allowNull: true },
      icon: { type: Sequelize.STRING(100), allowNull: true },
      image: { type: Sequelize.STRING(500), allowNull: true },
      is_active: { type: Sequelize.BOOLEAN, defaultValue: true },
      order: { type: Sequelize.INTEGER, defaultValue: 0 },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });

    // 5. users (dépend de wilayas)
    await queryInterface.createTable('users', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      email: { type: Sequelize.STRING(255), allowNull: true, unique: true },
      password: { type: Sequelize.STRING(255), allowNull: false },
      phone: { type: Sequelize.STRING(20), allowNull: true, unique: true },
      first_name: { type: Sequelize.STRING(100), allowNull: false },
      last_name: { type: Sequelize.STRING(100), allowNull: false },
      avatar: { type: Sequelize.STRING(500), allowNull: true },
      role: { type: Sequelize.ENUM('user', 'partner', 'admin', 'super_admin'), defaultValue: 'user' },
      status: { type: Sequelize.ENUM('active', 'inactive', 'suspended', 'pending'), defaultValue: 'active' },
      language: { type: Sequelize.ENUM('fr', 'ar', 'en'), defaultValue: 'fr' },
      email_verified: { type: Sequelize.BOOLEAN, defaultValue: false },
      phone_verified: { type: Sequelize.BOOLEAN, defaultValue: false },
      email_verification_token: { type: Sequelize.STRING(255), allowNull: true },
      email_verification_expires: { type: Sequelize.DATE, allowNull: true },
      password_reset_token: { type: Sequelize.STRING(255), allowNull: true },
      password_reset_expires: { type: Sequelize.DATE, allowNull: true },
      phone_otp: { type: Sequelize.STRING(6), allowNull: true },
      phone_otp_expires: { type: Sequelize.DATE, allowNull: true },
      email_otp: { type: Sequelize.STRING(6), allowNull: true },
      email_otp_expires: { type: Sequelize.DATE, allowNull: true },
      last_login: { type: Sequelize.DATE, allowNull: true },
      fcm_token: { type: Sequelize.STRING(500), allowNull: true },
      age: { type: Sequelize.INTEGER, allowNull: true },
      gender: { type: Sequelize.ENUM('male', 'female', 'young', 'child'), allowNull: true },
      wilaya_id: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'wilayas', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });

    // 6. refresh_tokens (dépend de users)
    await queryInterface.createTable('refresh_tokens', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      user_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      token: { type: Sequelize.STRING(500), allowNull: false, unique: true },
      expires_at: { type: Sequelize.DATE, allowNull: false },
      device_info: { type: Sequelize.JSONB, allowNull: true },
      ip_address: { type: Sequelize.STRING(50), allowNull: true },
      is_revoked: { type: Sequelize.BOOLEAN, defaultValue: false },
      revoked_at: { type: Sequelize.DATE, allowNull: true },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS refresh_tokens_token ON refresh_tokens (token);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS refresh_tokens_user_id ON refresh_tokens (user_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS refresh_tokens_expires_at ON refresh_tokens (expires_at);`);

    // 7. partners (dépend de users)
    await queryInterface.createTable('partners', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      user_id: {
        type: Sequelize.UUID, allowNull: false, unique: true,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      company_name: { type: Sequelize.STRING(255), allowNull: true },
      registration_number: { type: Sequelize.STRING(100), allowNull: true },
      tax_id: { type: Sequelize.STRING(100), allowNull: true },
      status: { type: Sequelize.ENUM('pending', 'approved', 'rejected', 'suspended'), defaultValue: 'pending' },
      subscription_plan: { type: Sequelize.ENUM('free', 'premium', 'gold'), defaultValue: 'free' },
      subscription_expires_at: { type: Sequelize.DATE, allowNull: true },
      documents: { type: Sequelize.JSONB, allowNull: true, defaultValue: [] },
      verified_at: { type: Sequelize.DATE, allowNull: true },
      verified_by: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      rejection_reason: { type: Sequelize.TEXT, allowNull: true },
      notes: { type: Sequelize.TEXT, allowNull: true },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });

    // 8. establishments (dépend de partners, categories, subcategories, wilayas, communes, users)
    await queryInterface.createTable('establishments', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      partner_id: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'partners', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      category_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'categories', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'RESTRICT',
      },
      subcategory_id: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'subcategories', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      wilaya_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'wilayas', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'RESTRICT',
      },
      commune_id: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'communes', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      name: { type: Sequelize.STRING(255), allowNull: false },
      name_ar: { type: Sequelize.STRING(255), allowNull: true },
      slug: { type: Sequelize.STRING(280), allowNull: false, unique: true },
      description: { type: Sequelize.TEXT, allowNull: true },
      description_ar: { type: Sequelize.TEXT, allowNull: true },
      address: { type: Sequelize.STRING(500), allowNull: false },
      address_ar: { type: Sequelize.STRING(500), allowNull: true },
      latitude: { type: Sequelize.DECIMAL(10, 8), allowNull: true },
      longitude: { type: Sequelize.DECIMAL(11, 8), allowNull: true },
      phone: { type: Sequelize.STRING(20), allowNull: true },
      phone_secondary: { type: Sequelize.STRING(20), allowNull: true },
      whatsapp: { type: Sequelize.STRING(20), allowNull: true },
      email: { type: Sequelize.STRING(255), allowNull: true },
      website: { type: Sequelize.STRING(500), allowNull: true },
      facebook: { type: Sequelize.STRING(500), allowNull: true },
      instagram: { type: Sequelize.STRING(500), allowNull: true },
      tiktok: { type: Sequelize.STRING(500), allowNull: true },
      snapchat: { type: Sequelize.STRING(500), allowNull: true },
      logo: { type: Sequelize.STRING(500), allowNull: true },
      cover_image: { type: Sequelize.STRING(500), allowNull: true },
      images: { type: Sequelize.JSONB, allowNull: true, defaultValue: [] },
      opening_hours: { type: Sequelize.JSONB, allowNull: true, defaultValue: {} },
      price_range: { type: Sequelize.ENUM('$', '$$', '$$$', '$$$$'), allowNull: true },
      services: { type: Sequelize.JSONB, allowNull: true, defaultValue: [] },
      amenities: { type: Sequelize.JSONB, allowNull: true, defaultValue: [] },
      tags: { type: Sequelize.JSONB, allowNull: true, defaultValue: [] },
      status: {
        type: Sequelize.ENUM('pending', 'active', 'inactive', 'rejected', 'suspended'),
        defaultValue: 'pending',
      },
      is_verified: { type: Sequelize.BOOLEAN, defaultValue: false },
      is_featured: { type: Sequelize.BOOLEAN, defaultValue: false },
      featured_until: { type: Sequelize.DATE, allowNull: true, defaultValue: null },
      average_rating: { type: Sequelize.DECIMAL(3, 2), defaultValue: 0 },
      total_reviews: { type: Sequelize.INTEGER, defaultValue: 0 },
      total_views: { type: Sequelize.INTEGER, defaultValue: 0 },
      total_favorites: { type: Sequelize.INTEGER, defaultValue: 0 },
      total_calls: { type: Sequelize.INTEGER, defaultValue: 0 },
      total_whatsapp_clicks: { type: Sequelize.INTEGER, defaultValue: 0 },
      total_contacts: { type: Sequelize.INTEGER, defaultValue: 0 },
      verified_at: { type: Sequelize.DATE, allowNull: true },
      verified_by: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      rejection_reason: { type: Sequelize.TEXT, allowNull: true },
      meta_title: { type: Sequelize.STRING(200), allowNull: true },
      meta_description: { type: Sequelize.TEXT, allowNull: true },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_status ON establishments (status);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_category_id ON establishments (category_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_subcategory_id ON establishments (subcategory_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_wilaya_id ON establishments (wilaya_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_commune_id ON establishments (commune_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_is_featured ON establishments (is_featured);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_average_rating ON establishments (average_rating);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS establishments_latitude_longitude ON establishments (latitude, longitude);`);

    // 9. reviews (dépend de users, establishments)
    await queryInterface.createTable('reviews', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      user_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      establishment_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'establishments', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      rating: { type: Sequelize.INTEGER, allowNull: false },
      title: { type: Sequelize.STRING(255), allowNull: true },
      comment: { type: Sequelize.TEXT, allowNull: true },
      images: { type: Sequelize.JSONB, allowNull: true, defaultValue: [] },
      status: { type: Sequelize.ENUM('pending', 'approved', 'rejected', 'hidden'), defaultValue: 'approved' },
      is_verified: { type: Sequelize.BOOLEAN, defaultValue: false },
      partner_reply: { type: Sequelize.TEXT, allowNull: true },
      partner_reply_at: { type: Sequelize.DATE, allowNull: true },
      sub_ratings: { type: Sequelize.JSONB, allowNull: true, defaultValue: null },
      helpful_count: { type: Sequelize.INTEGER, defaultValue: 0 },
      report_count: { type: Sequelize.INTEGER, defaultValue: 0 },
      moderated_by: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      moderated_at: { type: Sequelize.DATE, allowNull: true },
      rejection_reason: { type: Sequelize.TEXT, allowNull: true },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });
    await queryInterface.sequelize.query(`CREATE UNIQUE INDEX IF NOT EXISTS unique_user_establishment_review ON reviews (user_id, establishment_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS reviews_establishment_id ON reviews (establishment_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS reviews_status ON reviews (status);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS reviews_rating ON reviews (rating);`);

    // 10. favorites (dépend de users, establishments)
    await queryInterface.createTable('favorites', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      user_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      establishment_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'establishments', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });
    await queryInterface.sequelize.query(`CREATE UNIQUE INDEX IF NOT EXISTS unique_user_establishment_favorite ON favorites (user_id, establishment_id);`);

    // 11. promotions (dépend de establishments, users)
    await queryInterface.createTable('promotions', {
      id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
      establishment_id: {
        type: Sequelize.UUID, allowNull: false,
        references: { model: 'establishments', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'CASCADE',
      },
      title: { type: Sequelize.STRING(255), allowNull: false },
      title_ar: { type: Sequelize.STRING(255), allowNull: true },
      description: { type: Sequelize.TEXT, allowNull: true },
      description_ar: { type: Sequelize.TEXT, allowNull: true },
      type: {
        type: Sequelize.ENUM('percentage', 'fixed', 'buy_one_get_one', 'free_item', 'other'),
        defaultValue: 'percentage',
      },
      discount_value: { type: Sequelize.DECIMAL(10, 2), allowNull: true },
      promo_code: { type: Sequelize.STRING(50), allowNull: true },
      image: { type: Sequelize.STRING(500), allowNull: true },
      terms: { type: Sequelize.TEXT, allowNull: true },
      start_date: { type: Sequelize.DATE, allowNull: false },
      end_date: { type: Sequelize.DATE, allowNull: false },
      max_uses: { type: Sequelize.INTEGER, allowNull: true },
      current_uses: { type: Sequelize.INTEGER, defaultValue: 0 },
      status: {
        type: Sequelize.ENUM('draft', 'pending', 'active', 'paused', 'expired', 'rejected'),
        defaultValue: 'pending',
      },
      is_featured: { type: Sequelize.BOOLEAN, defaultValue: false },
      total_views: { type: Sequelize.INTEGER, defaultValue: 0 },
      approved_by: {
        type: Sequelize.UUID, allowNull: true,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE', onDelete: 'SET NULL',
      },
      approved_at: { type: Sequelize.DATE, allowNull: true },
      rejection_reason: { type: Sequelize.TEXT, allowNull: true },
      created_at: { type: Sequelize.DATE, allowNull: false },
      updated_at: { type: Sequelize.DATE, allowNull: false },
    }, { ifNotExists: true });
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS promotions_establishment_id ON promotions (establishment_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS promotions_status ON promotions (status);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS promotions_start_date_end_date ON promotions (start_date, end_date);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS promotions_is_featured ON promotions (is_featured);`);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('promotions');
    await queryInterface.dropTable('favorites');
    await queryInterface.dropTable('reviews');
    await queryInterface.dropTable('establishments');
    await queryInterface.dropTable('partners');
    await queryInterface.dropTable('refresh_tokens');
    await queryInterface.dropTable('users');
    await queryInterface.dropTable('subcategories');
    await queryInterface.dropTable('communes');
    await queryInterface.dropTable('categories');
    await queryInterface.dropTable('wilayas');
  },
};
