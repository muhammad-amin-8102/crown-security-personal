'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class TrainingReport extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      TrainingReport.belongsTo(models.Site, { foreignKey: 'site_id' });
    }
  }
  TrainingReport.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    site_id: DataTypes.UUID,
    date: DataTypes.DATE,
    topics: DataTypes.TEXT,
    attendance_count: DataTypes.INTEGER
  }, {
    sequelize,
    modelName: 'TrainingReport',
  });
  return TrainingReport;
};
