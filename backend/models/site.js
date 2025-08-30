'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Site extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      Site.hasMany(models.Shift, { foreignKey: 'site_id' });
      Site.hasMany(models.Attendance, { foreignKey: 'site_id' });
      Site.hasMany(models.Spend, { foreignKey: 'site_id' });
      Site.hasMany(models.NightRound, { foreignKey: 'site_id' });
      Site.hasMany(models.TrainingReport, { foreignKey: 'site_id' });
      Site.hasMany(models.SalaryDisbursement, { foreignKey: 'site_id' });
      Site.hasMany(models.Complaint, { foreignKey: 'site_id' });
      Site.hasMany(models.Rating, { foreignKey: 'site_id' });
      Site.hasMany(models.Bill, { foreignKey: 'site_id' });
    }
  }
  Site.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    name: DataTypes.STRING,
    location: DataTypes.STRING,
    strength: DataTypes.INTEGER,
    rate_per_guard: DataTypes.DECIMAL,
    agreement_start: DataTypes.DATE,
    agreement_end: DataTypes.DATE,
    area_officer_name: DataTypes.STRING,
    area_officer_phone: DataTypes.STRING,
    cro_name: DataTypes.STRING,
  cro_phone: DataTypes.STRING,
  client_id: DataTypes.UUID
  }, {
    sequelize,
    modelName: 'Site',
  });
  return Site;
};
