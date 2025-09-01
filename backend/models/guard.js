'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Guard extends Model {
    static associate(models) {
      Guard.belongsTo(models.Site, { foreignKey: 'site_id' });
      Guard.hasMany(models.Attendance, { foreignKey: 'guard_id' });
    }
  }
  Guard.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    site_id: DataTypes.UUID,
    name: DataTypes.STRING,
    phone: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'Guard',
  });
  return Guard;
};
