const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccountPath = path.resolve(
  __dirname,
  '..',
  process.env.FIREBASE_ADMIN_CREDENTIALS || 'firebase-admin.json',
);

if (!fs.existsSync(serviceAccountPath)) {
  console.error(
    `Missing Firebase Admin credentials at ${serviceAccountPath}.\n` +
      'Set FIREBASE_ADMIN_CREDENTIALS or place an ignored firebase-admin.json file at the project root.',
  );
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function reset() {
  console.log('Resetting providers...');

  const providers = await db.collection('providers').get();

  for (const doc of providers.docs) {
    await doc.ref.update({
      isOnline: false,
      isBusy: false,
      updatedAtIso: new Date().toISOString(),
    });
  }

  console.log('Resetting requests...');

  const requests = await db.collection('requests').get();

  for (const doc of requests.docs) {
    const data = doc.data();

    const activeStatuses = [
      'searching',
      'accepted',
      'onTheWay',
      'arrived',
      'inService',
    ];

    if (activeStatuses.includes(data.status)) {
      await doc.ref.update({
        status: 'cancelled',
        offeredProviderUid: null,
        providerUid: null,
        offerExpiresAt: null,
        offeredAt: null,
        updatedAtIso: new Date().toISOString(),
      });
    }
  }

  console.log('DONE.');
  process.exit(0);
}

reset().catch((e) => {
  console.error(e);
  process.exit(1);
});
