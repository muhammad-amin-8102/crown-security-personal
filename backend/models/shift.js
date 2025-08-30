'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Shift extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      Shift.belongsTo(models.Site, { foreignKey: 'site_id' });
    }
  }
  Shift.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    site_id: DataTypes.UUID,
    date: DataTypes.DATE,
    shift_type: DataTypes.STRING,
    guard_count: DataTypes.INTEGER
  }, {
    sequelize,
    modelName: 'Shift',
  });
  return Shift;
};
