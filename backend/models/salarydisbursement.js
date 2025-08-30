'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class SalaryDisbursement extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      SalaryDisbursement.belongsTo(models.Site, { foreignKey: 'site_id' });
    }
  }
  SalaryDisbursement.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    site_id: DataTypes.UUID,
    month: DataTypes.DATE,
    status: DataTypes.STRING,
    date_paid: DataTypes.DATE
  }, {
    sequelize,
    modelName: 'SalaryDisbursement',
  });
  return SalaryDisbursement;
};
