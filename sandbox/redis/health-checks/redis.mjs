import { createClient } from "redis";

const redis = createClient();

(async () => {
  try {
    await redis.connect();
    console.log("REDIS:CONNECTED");
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(2);
  }
})();
