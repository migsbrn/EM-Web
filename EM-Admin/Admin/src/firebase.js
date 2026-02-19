import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";
import { getAnalytics } from "firebase/analytics";
import { getFunctions } from "firebase/functions";

// Firebase configuration for EasyMind-Admin
const firebaseConfig = {
  apiKey: "AIzaSyCT5HTrn5anC7bwfdLx8AmF-MafDcNlIzg",
  authDomain: "easy-mind-51834.firebaseapp.com",
  projectId: "easy-mind-51834",
  storageBucket: "easy-mind-51834.firebasestorage.app",
  messagingSenderId: "1026451165224",
  appId: "1:1026451165224:web:dcc4f8abeb3293b5be651d",
  measurementId: "G-JD3G9FXMK1",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);
const analytics = getAnalytics(app);
const functions = getFunctions(app);

// Export all Firebase services
export { app, auth, db, storage, analytics, functions };
