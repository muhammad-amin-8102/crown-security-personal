'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Bill extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      Bill.belongsTo(models.Site, { foreignKey: 'site_id' });
    }
  }
  Bill.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    site_id: DataTypes.UUID,
    amount: DataTypes.DECIMAL,
    due_date: DataTypes.DATE,
    status: DataTypes.STRING,
    invoice_url: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'Bill',
  });
  return Bill;
};
