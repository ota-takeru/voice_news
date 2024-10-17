import * as admin from "firebase-admin";

if (process.env.FIRESTORE_EMULATOR_HOST) {
  // エミュレータの設定
  process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
}

admin.initializeApp();
export const db = admin.firestore();
