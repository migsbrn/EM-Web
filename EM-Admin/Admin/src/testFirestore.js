import { initializeApp } from "firebase/app";
import { getFirestore, doc, setDoc } from "firebase/firestore";

try {
  const firebaseConfig = {
    apiKey: "AIzaSyCT5HTrn5anC7bwfdLx8AmF-MafDcNlIzg",
    authDomain: "easy-mind-51834.firebaseapp.com",
    projectId: "easy-mind-51834",
    storageBucket: "easy-mind-51834.appspot.com",
    messagingSenderId: "1026451165224",
    appId: "1:1026451165224:web:dc442a4c04fe8cf7be651d",
    measurementId: "G-LELN1NTF6M",
  };

  const app = initializeApp(firebaseConfig, "test-app");
  const db = getFirestore(app);

  const testData = {
    firstName: "Test",
    lastName: "Teacher",
    email: "test@teacher.com",
    role: "teacher",
    status: "Pending",
    createdAt: new Date(),
  };

  console.log("Attempting to write to Firestore...");
  await setDoc(doc(db, "teacherRequests", "test-uid"), testData);
  console.log("Test data written successfully to teacherRequests");
} catch (error) {
  console.error(
    "Error:",
    error.code || "No error code",
    error.message,
    error.stack || "No stack trace"
  );
}
