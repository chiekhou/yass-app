const { DataTypes } = require("sequelize");
const bcrypt = require("bcryptjs");
const config = require("../config/app");

module.exports = (sequelize) => {
  const User = sequelize.define(
    "User",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      email: {
        type: DataTypes.STRING(255),
        allowNull: true,
        unique: true,
        validate: {
          isEmail: true,
        },
      },
      password: {
        type: DataTypes.STRING(255),
        allowNull: false,
      },
      phone: {
        type: DataTypes.STRING(20),
        allowNull: true,
        unique: true,
      },
      first_name: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      last_name: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      avatar: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      role: {
        type: DataTypes.ENUM("user", "partner", "admin", "super_admin"),
        defaultValue: "user",
      },
      status: {
        type: DataTypes.ENUM("active", "inactive", "suspended", "pending"),
        defaultValue: "active",
      },
      language: {
        type: DataTypes.ENUM("fr", "ar", "en"),
        defaultValue: "fr",
      },
      email_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      phone_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      email_verification_token: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      email_verification_expires: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      password_reset_token: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      password_reset_expires: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      phone_otp: {
        type: DataTypes.STRING(6),
        allowNull: true,
      },
      phone_otp_expires: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      email_otp: {
        type: DataTypes.STRING(6),
        allowNull: true,
      },
      email_otp_expires: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      last_login: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      fcm_token: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      age: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },
      gender: {
        type: DataTypes.ENUM("male", "female", "young", "child"),
        allowNull: true,
      },
      wilaya_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "wilayas",
          key: "id",
        },
      },
      is_elite: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
    },
    {
      tableName: "users",
      timestamps: true,
      underscored: true,
      hooks: {
        beforeCreate: async (user) => {
          if (user.password) {
            user.password = await bcrypt.hash(
              user.password,
              config.bcrypt.saltRounds,
            );
          }
        },
        beforeUpdate: async (user) => {
          if (user.changed("password")) {
            user.password = await bcrypt.hash(
              user.password,
              config.bcrypt.saltRounds,
            );
          }
        },
      },
    },
  );

  // Instance methods
  User.prototype.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
  };

  User.prototype.toJSON = function () {
    const values = { ...this.get() };
    delete values.password;
    delete values.email_verification_token;
    delete values.email_verification_expires;
    delete values.password_reset_token;
    delete values.password_reset_expires;
    delete values.phone_otp;
    delete values.phone_otp_expires;
    delete values.email_otp;
    delete values.email_otp_expires;
    return values;
  };

  // Associations
  User.associate = (models) => {
    User.belongsTo(models.Wilaya, {
      foreignKey: "wilaya_id",
      as: "wilaya",
    });
    User.hasMany(models.Favorite, {
      foreignKey: "user_id",
      as: "favorites",
    });
    User.hasMany(models.Review, {
      foreignKey: "user_id",
      as: "reviews",
    });
    User.hasOne(models.Partner, {
      foreignKey: "user_id",
      as: "partner_profile",
    });
  };

  return User;
};
