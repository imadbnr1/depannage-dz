const admin = require('firebase-admin');

const serviceAccount = require('../firebase-admin.json');

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