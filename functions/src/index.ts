import { setGlobalOptions } from "firebase-functions/v2";
setGlobalOptions({
  region: "asia-northeast1",
});

export { fetchnews } from "./functions/fetchNews";
export { delivernews } from "./functions/deliverNews";
export { generateAudioForNews } from "./functions/generateAudioForNews";
