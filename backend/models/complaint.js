'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Complaint extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      Complaint.belongsTo(models.Site, { foreignKey: 'site_id' });
      Complaint.belongsTo(models.User, { foreignKey: 'client_id' });
    }
  }
  Complaint.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    site_id: {
      type: DataTypes.UUID
    },
    client_id: {
      type: DataTypes.UUID
    },
    complaint_text: DataTypes.TEXT,
    status: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'Complaint',
  });
  return Complaint;
};
