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
    code: {
      type: DataTypes.STRING,
      unique: true,
      allowNull: false,
      validate: {
        len: [4, 64]
      }
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

  // Ensure code exists before validation so validators pass
  Bill.beforeValidate((bill) => {
    if (!bill.code) {
      const idPart = (bill.id ? String(bill.id) : '').replace(/-/g, '').slice(0, 8).toUpperCase();
      bill.code = `BILL-${idPart || Math.random().toString(36).slice(2, 10).toUpperCase()}`;
    }
  });

  Bill.beforeBulkCreate((rows) => {
    rows.forEach((bill) => {
      if (!bill.code) {
        const idPart = (bill.id ? String(bill.id) : '').replace(/-/g, '').slice(0, 8).toUpperCase();
        bill.code = `BILL-${idPart || Math.random().toString(36).slice(2, 10).toUpperCase()}`;
      }
    });
  });
  return Bill;
};
