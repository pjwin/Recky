const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateAllUsers() {
  const usersSnapshot = await db.collection('users').get();

  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    const data = userDoc.data();
    const friends = data.friends || [];

    console.log(`Migrating user ${userId} with ${friends.length} friends`);

    for (const friendUID of friends) {
      try {
        const friendDoc = await db.collection('users').doc(friendUID).get();
        const friendUsername = friendDoc.get('username') || 'Unknown';

        await db.collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendUID)
          .set({
            username: friendUsername,
            addedAt: admin.firestore.FieldValue.serverTimestamp()
          });

        console.log(`  Added ${friendUsername} to ${userId}'s subcollection`);
      } catch (err) {
        console.error(`  Failed to migrate friend ${friendUID}:`, err);
      }
    }

    // Optional: delete the old array
    await db.collection('users').doc(userId).update({ friends: admin.firestore.FieldValue.delete() });
  }

  console.log('✅ Migration complete.');
}

migrateAllUsers();
