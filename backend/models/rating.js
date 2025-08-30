'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Rating extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      Rating.belongsTo(models.Site, { foreignKey: 'site_id' });
      Rating.belongsTo(models.User, { foreignKey: 'client_id' });
    }
  }
  Rating.init({
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
    month: DataTypes.DATE,
    rating_value: DataTypes.INTEGER,
    nps_score: DataTypes.INTEGER
  }, {
    sequelize,
    modelName: 'Rating',
  });
  return Rating;
};
