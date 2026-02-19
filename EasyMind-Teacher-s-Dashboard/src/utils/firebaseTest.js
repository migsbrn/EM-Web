// Test Firebase Saving Functionality
import { db } from "../firebase";
import { collection, addDoc, serverTimestamp, getDocs } from "firebase/firestore";
import { getAuth } from "firebase/auth";

export const testFirebaseSaving = async () => {
  try {
    console.log("🧪 Testing Firebase saving...");
    
    const auth = getAuth();
    const user = auth.currentUser;
    
    if (!user) {
      console.error("❌ User not authenticated");
      return false;
    }
    
    console.log("✅ User authenticated:", user.uid);
    
    // Test data
    const testContent = {
      type: "lesson",
      title: "Test Lesson",
      description: "This is a test lesson",
      category: "FUNCTIONAL_ACADEMICS",
      difficulty: "beginner",
      createdAt: serverTimestamp(),
      teacherId: user.uid,
      studentAppReady: true,
      template: "test_template",
      
      lessonData: {
        items: [
          { 
            type: "color", 
            name: "Red", 
            description: "Red is a bright color", 
            ttsText: "Red is a bright color", 
            color: "#FF0000",
            imageUrl: "assets/red.png"
          }
        ],
        currentIndex: 0,
        enableProgress: true,
        enableTTS: true,
        enableAnimations: true
      },
      
      settings: {
        enableTTS: true,
        enableAnimations: true,
        enableSoundEffects: true,
        enableGamification: true,
        enableProgressTracking: true,
        enableConfetti: true
      },
      
      studentAppData: {
        displayType: "interactive",
        uiTheme: "kid-friendly",
        animations: true,
        soundEffects: true,
        progressTracking: true,
        gamification: true,
        confetti: true,
        tts: true
      }
    };
    
    // Save to Firebase
    console.log("💾 Saving test content to Firebase...");
    const docRef = await addDoc(collection(db, "contents"), testContent);
    console.log("✅ Document written with ID:", docRef.id);
    
    // Verify it was saved
    console.log("🔍 Verifying content was saved...");
    const querySnapshot = await getDocs(collection(db, "contents"));
    const savedContent = querySnapshot.docs.find(doc => doc.id === docRef.id);
    
    if (savedContent) {
      console.log("✅ Content successfully saved and verified!");
      console.log("📄 Saved content:", savedContent.data());
      return true;
    } else {
      console.error("❌ Content not found after saving");
      return false;
    }
    
  } catch (error) {
    console.error("❌ Error testing Firebase saving:", error);
    return false;
  }
};

export const testAssessmentSaving = async () => {
  try {
    console.log("🧪 Testing Assessment saving...");
    
    const auth = getAuth();
    const user = auth.currentUser;
    
    if (!user) {
      console.error("❌ User not authenticated");
      return false;
    }
    
    // Test assessment data
    const testAssessment = {
      type: "assessment",
      title: "Test Assessment",
      description: "This is a test assessment",
      category: "FUNCTIONAL_ACADEMICS",
      difficulty: "beginner",
      createdAt: serverTimestamp(),
      teacherId: user.uid,
      studentAppReady: true,
      template: "test_assessment_template",
      
      assessmentData: {
        questions: [
          {
            question: "What color is this?",
            type: "multiple_choice",
            options: ["Red", "Blue", "Green", "Yellow"],
            correctAnswer: "Red",
            explanation: "This is red",
            ttsText: "What color is this?",
            imageUrl: "assets/red.png"
          }
        ],
        currentQuestion: 0,
        enableAdaptiveMode: true,
        enableTTS: true,
        enableConfetti: true,
        scoring: {
          pointsPerQuestion: 20,
          perfectBonus: 50,
          streakBonus: 30
        }
      },
      
      settings: {
        enableTTS: true,
        enableAnimations: true,
        enableSoundEffects: true,
        enableGamification: true,
        enableProgressTracking: true,
        enableConfetti: true,
        timeLimit: 300,
        attempts: 1
      },
      
      studentAppData: {
        displayType: "interactive",
        uiTheme: "kid-friendly",
        animations: true,
        soundEffects: true,
        progressTracking: true,
        gamification: true,
        confetti: true,
        tts: true
      }
    };
    
    // Save to Firebase
    console.log("💾 Saving test assessment to Firebase...");
    const docRef = await addDoc(collection(db, "contents"), testAssessment);
    console.log("✅ Assessment written with ID:", docRef.id);
    
    return true;
    
  } catch (error) {
    console.error("❌ Error testing Assessment saving:", error);
    return false;
  }
};

export const testGameSaving = async () => {
  try {
    console.log("🧪 Testing Game saving...");
    
    const auth = getAuth();
    const user = auth.currentUser;
    
    if (!user) {
      console.error("❌ User not authenticated");
      return false;
    }
    
    // Test game data
    const testGame = {
      type: "game",
      title: "Test Game",
      description: "This is a test game",
      category: "FUNCTIONAL_ACADEMICS",
      difficulty: "beginner",
      createdAt: serverTimestamp(),
      teacherId: user.uid,
      studentAppReady: true,
      template: "test_game_template",
      
      gameData: {
        gameType: "matching",
        levels: [
          {
            level: 1,
            difficulty: "beginner",
            colors: [
              { name: "Red", color: "#FF0000", emoji: "🔴", imageUrl: "assets/red.png" }
            ],
            questions: [
              { 
                target: "Red", 
                options: ["Red", "Blue", "Green"], 
                correct: 0,
                imageUrl: "assets/red.png",
                ttsText: "Match the red color"
              }
            ]
          }
        ],
        currentLevel: 0,
        scoring: {
          pointsPerAction: 10,
          timeBonus: 5,
          perfectBonus: 20,
          levelBonus: 100
        },
        enableAnimations: true,
        enableConfetti: true
      },
      
      settings: {
        enableTTS: true,
        enableAnimations: true,
        enableSoundEffects: true,
        enableGamification: true,
        enableProgressTracking: true,
        enableConfetti: true
      },
      
      studentAppData: {
        displayType: "interactive",
        uiTheme: "kid-friendly",
        animations: true,
        soundEffects: true,
        progressTracking: true,
        gamification: true,
        confetti: true,
        tts: true
      }
    };
    
    // Save to Firebase
    console.log("💾 Saving test game to Firebase...");
    const docRef = await addDoc(collection(db, "contents"), testGame);
    console.log("✅ Game written with ID:", docRef.id);
    
    return true;
    
  } catch (error) {
    console.error("❌ Error testing Game saving:", error);
    return false;
  }
};
