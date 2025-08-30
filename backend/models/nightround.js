'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class NightRound extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      NightRound.belongsTo(models.Site, { foreignKey: 'site_id' });
    }
  }
  NightRound.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    site_id: DataTypes.UUID,
    date: DataTypes.DATE,
    findings: DataTypes.TEXT,
    officer_id: DataTypes.UUID
  }, {
    sequelize,
    modelName: 'NightRound',
  });
  return NightRound;
};
