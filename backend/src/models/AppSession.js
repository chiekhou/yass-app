const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const AppSession = sequelize.define(
    'AppSession',
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      user_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: { model: 'users', key: 'id' },
        onDelete: 'SET NULL',
      },
      platform: {
        type: DataTypes.ENUM('android', 'ios', 'web'),
        allowNull: true,
      },
    },
    {
      tableName: 'app_sessions',
      timestamps: true,
      underscored: true,
    }
  );

  AppSession.associate = (models) => {
    AppSession.belongsTo(models.User, {
      foreignKey: 'user_id',
      as: 'user',
    });
  };

  return AppSession;
};
