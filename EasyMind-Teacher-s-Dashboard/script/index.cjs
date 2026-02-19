const admin = require('firebase-admin');

// Initialize Firebase Admin SDK (ensure serviceAccountKey.json is in the same directory)
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function watchTeacherRequests() {
  console.log('Watching teacherRequests for status changes...');
  db.collection('teacherRequests').onSnapshot(async (snapshot) => {
    snapshot.docChanges().forEach(async (change) => {
      if (change.type === 'modified') {
        const newData = change.doc.data();
        const userId = change.doc.id;

        // Simulate the onUpdate behavior by checking status
        if (newData.status === 'Active' && newData.previousStatus !== 'Active') {
          try {
            await admin.auth().setCustomUserClaims(userId, { role: 'teacher' });
            console.log(`Set 'teacher' role claims for user ${userId}`);

            // Update the document to store the previous status (to avoid re-triggering)
            await db.collection('teacherRequests').doc(userId).update({
              previousStatus: newData.status,
            });
          } catch (error) {
            console.error(`Failed to set claims for user ${userId}:`, error);
          }
        }
      }
    });
  });
}

// Run the script
watchTeacherRequests().catch(console.error);