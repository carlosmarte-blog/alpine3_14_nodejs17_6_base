import * as sequelize from "sequelize";

const { Sequelize } = sequelize;

const postgres = new Sequelize("postgres", "postgres", "", {
  host: "localhost",
  dialect: "postgres",
});

(async () => {
  try {
    await postgres.authenticate();
    console.log("[POSTGRES]:CONNECTED");
  } catch (error) {
    console.log(error);
  }
})();
