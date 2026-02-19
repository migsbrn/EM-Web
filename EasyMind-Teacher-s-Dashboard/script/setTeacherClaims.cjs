const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Replace with your service account key path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function setTeacherClaims() {
  try {
    console.log('🔍 Checking for active teachers...');
    const teacherDocs = await admin.firestore().collection('teacherRequests').where('status', '==', 'Active').get();
    console.log(`Found ${teacherDocs.size} active teachers`);

    if (teacherDocs.empty) {
      console.log('No active teachers found in teacherRequests collection.');
      return;
    }

    const updates = [];
    for (const doc of teacherDocs.docs) {
      const uid = doc.id;
      const teacherData = doc.data();
      console.log(`Processing teacher UID: ${uid}, Email: ${teacherData.email}`);

      // Verify the user exists in Firebase Authentication
      try {
        const userRecord = await admin.auth().getUser(uid);
        console.log(`✅ User found: ${userRecord.email}`);
        
        // Check if user already has teacher role
        const currentClaims = userRecord.customClaims || {};
        if (currentClaims.role === 'teacher') {
          console.log(`⚠️  User ${uid} already has teacher role, skipping...`);
          continue;
        }

        updates.push(
          admin.auth().setCustomUserClaims(uid, { role: 'teacher' })
            .then(() => {
              console.log(`✅ Set role: teacher for UID: ${uid} (${teacherData.email})`);
              return { success: true, uid, email: teacherData.email };
            })
            .catch(error => {
              console.error(`❌ Failed to set claim for UID ${uid}:`, error);
              return { success: false, uid, email: teacherData.email, error };
            })
        );
      } catch (error) {
        console.error(`❌ User with UID ${uid} not found in Firebase Authentication:`, error);
      }
    }

    if (updates.length === 0) {
      console.log('No updates needed - all active teachers already have proper roles.');
      return;
    }

    const results = await Promise.all(updates);
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    
    console.log(`\n📊 Results:`);
    console.log(`✅ Successfully set teacher roles: ${successful}`);
    console.log(`❌ Failed to set teacher roles: ${failed}`);
    
    if (failed > 0) {
      console.log('\n❌ Failed updates:');
      results.filter(r => !r.success).forEach(r => {
        console.log(`  - ${r.email} (${r.uid}): ${r.error.message}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error setting teacher roles:', error);
  }
}

// Add function to set role for specific user
async function setRoleForUser(uid, role = 'teacher') {
  try {
    console.log(`🔧 Setting ${role} role for user: ${uid}`);
    
    // Verify user exists
    const userRecord = await admin.auth().getUser(uid);
    console.log(`✅ User found: ${userRecord.email}`);
    
    // Set custom claims
    await admin.auth().setCustomUserClaims(uid, { role });
    console.log(`✅ Successfully set ${role} role for ${userRecord.email}`);
    
    return { success: true, email: userRecord.email };
  } catch (error) {
    console.error(`❌ Failed to set role for user ${uid}:`, error);
    return { success: false, error };
  }
}

// Add function to check user roles
async function checkUserRoles() {
  try {
    console.log('🔍 Checking all user roles...');
    
    const listUsersResult = await admin.auth().listUsers();
    const usersWithRoles = [];
    
    for (const userRecord of listUsersResult.users) {
      const claims = userRecord.customClaims || {};
      if (claims.role) {
        usersWithRoles.push({
          uid: userRecord.uid,
          email: userRecord.email,
          role: claims.role
        });
      }
    }
    
    console.log(`\n📋 Users with custom roles (${usersWithRoles.length}):`);
    usersWithRoles.forEach(user => {
      console.log(`  - ${user.email}: ${user.role}`);
    });
    
    return usersWithRoles;
  } catch (error) {
    console.error('❌ Error checking user roles:', error);
    return [];
  }
}

// Command line interface
const command = process.argv[2];
const uid = process.argv[3];

if (command === 'set-role' && uid) {
  const role = process.argv[4] || 'teacher';
  setRoleForUser(uid, role).then(() => process.exit(0));
} else if (command === 'check-roles') {
  checkUserRoles().then(() => process.exit(0));
} else if (command === 'help') {
  console.log(`
📚 Teacher Claims Management Script

Usage:
  node setTeacherClaims.cjs                    # Set roles for all active teachers
  node setTeacherClaims.cjs set-role <uid>     # Set role for specific user
  node setTeacherClaims.cjs check-roles        # Check all user roles
  node setTeacherClaims.cjs help               # Show this help

Examples:
  node setTeacherClaims.cjs set-role abc123 teacher
  node setTeacherClaims.cjs check-roles
  `);
  process.exit(0);
} else {
  // Default behavior - set roles for all active teachers
  setTeacherClaims().then(() => process.exit(0));
}