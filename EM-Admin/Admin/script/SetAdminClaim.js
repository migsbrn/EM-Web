import admin from "firebase-admin";
import serviceAccount from "./serviceAccountKey.json" assert { type: "json" };

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "easy-mind-51834",
});

// UIDs of admin users
const userUids = {
  bprosas: "lCPzNsW6t4RBm77ehbxprqK3ybv2",
  kaiii: "yP1XzeVZbzTSkn2JwrPKUaZla2H3",
  migs: "QuAxGmBozFPOXLId8Q1EpZXIPtu2",
};

// Set custom claim { role: "admin" } for each UID
const setCustomClaims = async (uid) => {
  try {
    await admin.auth().setCustomUserClaims(uid, { role: "admin" });
    console.log(`✅ Successfully set role: "admin" for UID: ${uid}`);
  } catch (error) {
    console.error(`❌ Failed to set claims for UID: ${uid}`, error);
  }
};

// Apply claims to all listed UIDs
const applyCustomClaims = async () => {
  for (const uid of Object.values(userUids)) {
    await setCustomClaims(uid);
  }
};

applyCustomClaims();
