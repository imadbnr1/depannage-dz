const admin = require("firebase-admin");
const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const OFFER_TIMEOUT_SECONDS = 18;
const EARTH_RADIUS_KM = 6371;

function safeString(value, fallback = "") {
  return typeof value === "string" ? value : fallback;
}

function asNumber(value, fallback = null) {
  return typeof value === "number" ? value : fallback;
}

function parsePosition(raw) {
  if (!raw || typeof raw !== "object") return null;

  const lat = asNumber(raw.lat);
  const lng = asNumber(raw.lng);
  if (lat === null || lng === null) return null;

  return {lat, lng};
}

function toRadians(value) {
  return value * (Math.PI / 180);
}

function distanceKm(from, to) {
  const dLat = toRadians(to.lat - from.lat);
  const dLng = toRadians(to.lng - from.lng);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(from.lat)) *
      Math.cos(toRadians(to.lat)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

function rejectedProviderUids(data) {
  if (!Array.isArray(data?.rejectedProviderUids)) return [];
  return data.rejectedProviderUids.map((value) => `${value}`);
}

function isProviderDispatchEligible(data) {
  return data?.isApproved === true &&
    data?.isOnline === true &&
    data?.isBusy !== true &&
    data?.isBlocked !== true;
}

function isRequestAssignable(data) {
  return safeString(data?.status) === "searching" &&
    !safeString(data?.providerUid) &&
    !safeString(data?.offeredProviderUid);
}

function parseDate(value) {
  if (!value) return null;
  if (value instanceof admin.firestore.Timestamp) return value.toDate();
  if (typeof value === "string" && value.trim()) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }
  return null;
}

async function getUserToken(uid) {
  if (!uid) return null;
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return null;
  const data = snap.data() || {};
  return safeString(data.fcmToken, "");
}

async function sendToToken(token, payload) {
  if (!token) return;

  await messaging.send({
    token,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      type: safeString(payload.type),
      requestId: safeString(payload.requestId),
      status: safeString(payload.status),
      senderRole: safeString(payload.senderRole),
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
      },
    },
  });
}

async function eligibleProvidersSortedByDistance(requestData) {
  const customerPosition = parsePosition(requestData?.customerPosition);
  if (!customerPosition) return [];

  const rejected = new Set(rejectedProviderUids(requestData));
  const providersSnap = await db.collection("providers").get();

  return providersSnap.docs
      .map((doc) => {
        const data = doc.data() || {};
        return {
          uid: safeString(data.uid, doc.id),
          position: parsePosition(data.position),
          raw: data,
        };
      })
      .filter((provider) => {
        return provider.uid &&
        provider.position &&
        isProviderDispatchEligible(provider.raw) &&
        !rejected.has(provider.uid);
      })
      .sort((a, b) => {
        return distanceKm(customerPosition, a.position) -
        distanceKm(customerPosition, b.position);
      });
}

async function offerRequestToProvider(requestId, providerUid) {
  return db.runTransaction(async (tx) => {
    const ref = db.collection("requests").doc(requestId);
    const snap = await tx.get(ref);
    if (!snap.exists) return false;

    const data = snap.data() || {};
    if (!isRequestAssignable(data)) return false;

    const rejected = rejectedProviderUids(data);
    if (rejected.includes(providerUid)) return false;

    const offeredAt = admin.firestore.Timestamp.now();
    const offerExpiresAt = admin.firestore.Timestamp.fromMillis(
        Date.now() + (OFFER_TIMEOUT_SECONDS * 1000),
    );

    tx.set(ref, {
      offeredProviderUid: providerUid,
      offeredAt,
      offerExpiresAt,
    }, {merge: true});

    return true;
  });
}

async function assignNearestProvider(requestId, requestData = null) {
  let latestData = requestData;
  if (!latestData) {
    const latestSnap = await db.collection("requests").doc(requestId).get();
    if (!latestSnap.exists) return false;
    latestData = latestSnap.data() || {};
  }

  if (!isRequestAssignable(latestData)) return false;

  const candidates = await eligibleProvidersSortedByDistance(latestData);
  if (candidates.length === 0) return false;

  for (const candidate of candidates) {
    // eslint-disable-next-line no-await-in-loop
    const assigned = await offerRequestToProvider(requestId, candidate.uid);
    if (assigned) return true;
  }

  return false;
}

async function clearOfferAndRejectProvider(requestId, providerUid) {
  return db.runTransaction(async (tx) => {
    const ref = db.collection("requests").doc(requestId);
    const snap = await tx.get(ref);
    if (!snap.exists) return false;

    const data = snap.data() || {};
    if (safeString(data.status) !== "searching") return false;
    if (safeString(data.offeredProviderUid) !== providerUid) return false;

    const rejected = new Set(rejectedProviderUids(data));
    rejected.add(providerUid);

    tx.set(ref, {
      offeredProviderUid: null,
      offeredAt: null,
      offerExpiresAt: null,
      rejectedProviderUids: Array.from(rejected),
    }, {merge: true});

    return true;
  });
}

async function reassignAfterProviderExit(providerUid) {
  const offeredRequests = await db.collection("requests")
      .where("status", "==", "searching")
      .where("offeredProviderUid", "==", providerUid)
      .get();

  for (const doc of offeredRequests.docs) {
    // eslint-disable-next-line no-await-in-loop
    const cleared = await clearOfferAndRejectProvider(doc.id, providerUid);
    if (!cleared) continue;
    // eslint-disable-next-line no-await-in-loop
    await assignNearestProvider(doc.id);
  }
}

async function assignWaitingRequests(limit = 5) {
  const waitingRequests = await db.collection("requests")
      .where("status", "==", "searching")
      .orderBy("createdAt", "asc")
      .limit(limit)
      .get();

  for (const doc of waitingRequests.docs) {
    const data = doc.data() || {};
    if (!isRequestAssignable(data)) continue;
    // eslint-disable-next-line no-await-in-loop
    const assigned = await assignNearestProvider(doc.id, data);
    if (assigned) return true;
  }

  return false;
}

exports.assignNearestProviderOnNewRequest = onDocumentCreated(
    "requests/{requestId}",
    async (event) => {
      const data = event.data?.data();
      if (!data) return;
      await assignNearestProvider(event.params.requestId, data);
    },
);

exports.redispatchWaitingRequests = onDocumentUpdated(
    "requests/{requestId}",
    async (event) => {
      const before = event.data?.before?.data() || {};
      const after = event.data?.after?.data() || {};

      const becameAssignable =
        isRequestAssignable(after) && !isRequestAssignable(before);
      const rejectedChanged =
        JSON.stringify(rejectedProviderUids(before)) !==
        JSON.stringify(rejectedProviderUids(after));
      const offerCleared =
        safeString(before.offeredProviderUid) &&
        !safeString(after.offeredProviderUid);

      if (becameAssignable || (isRequestAssignable(after) &&
          (rejectedChanged || offerCleared))) {
        await assignNearestProvider(event.params.requestId, after);
      }
    },
);

exports.redispatchOnProviderAvailabilityChange = onDocumentUpdated(
    "providers/{providerId}",
    async (event) => {
      const before = event.data?.before?.data() || {};
      const after = event.data?.after?.data() || {};
      const providerId = event.params.providerId;

      const wasEligible = isProviderDispatchEligible(before);
      const isEligible = isProviderDispatchEligible(after);

      if (wasEligible && !isEligible) {
        await reassignAfterProviderExit(providerId);
        return;
      }

      if (!wasEligible && isEligible) {
        await assignWaitingRequests(8);
      }
    },
);

exports.sweepExpiredOffers = onSchedule(
    {
      schedule: "every 1 minutes",
      timeZone: "Africa/Algiers",
    },
    async () => {
      const now = new Date();
      const searchingRequests = await db.collection("requests")
          .where("status", "==", "searching")
          .get();

      for (const doc of searchingRequests.docs) {
        const data = doc.data() || {};
        const offeredProviderUid = safeString(data.offeredProviderUid);
        if (!offeredProviderUid) continue;

        const expiresAt = parseDate(data.offerExpiresAt);
        if (!expiresAt || expiresAt > now) continue;

        // eslint-disable-next-line no-await-in-loop
        const cleared = await clearOfferAndRejectProvider(
            doc.id,
            offeredProviderUid,
        );

        if (!cleared) continue;
        // eslint-disable-next-line no-await-in-loop
        await assignNearestProvider(doc.id);
      }
    },
);

exports.notifyProviderWhenOfferChanges = onDocumentUpdated(
    "requests/{requestId}",
    async (event) => {
      const before = event.data?.before?.data() || {};
      const after = event.data?.after?.data() || {};

      const beforeOffered = safeString(before.offeredProviderUid);
      const afterOffered = safeString(after.offeredProviderUid);

      if (!afterOffered || beforeOffered === afterOffered) return;

      const token = await getUserToken(afterOffered);
      await sendToToken(token, {
        title: "Nouvelle mission",
        body: `${safeString(after.customerName, "Client")} a besoin d'aide.`,
        type: "new_order",
        requestId: event.params.requestId,
        status: safeString(after.status),
      });
    },
);

exports.notifyCustomerOnRequestUpdate = onDocumentUpdated(
    "requests/{requestId}",
    async (event) => {
      const before = event.data?.before?.data() || {};
      const after = event.data?.after?.data() || {};

      const beforeStatus = safeString(before.status);
      const afterStatus = safeString(after.status);

      if (!afterStatus || beforeStatus === afterStatus) return;

      const customerUid = safeString(after.customerUid);
      if (!customerUid) return;

      const token = await getUserToken(customerUid);
      const providerName = safeString(after.providerName, "Le provider");

      let title = "Mission mise a jour";
      let body = "Votre mission a ete mise a jour.";

      switch (afterStatus) {
        case "accepted":
          title = "Mission acceptee";
          body = `${providerName} a accepte votre mission.`;
          break;
        case "onTheWay":
          title = "Provider en route";
          body = `${providerName} est en route.`;
          break;
        case "arrived":
          title = "Provider arrive";
          body = `${providerName} est arrive.`;
          break;
        case "inService":
          title = "Service commence";
          body = "Votre depannage est en cours.";
          break;
        case "completed":
          title = "Mission terminee";
          body = "Votre mission a ete terminee avec succes.";
          break;
        case "cancelled":
          title = "Mission annulee";
          body = "Votre mission a ete annulee.";
          break;
      }

      await sendToToken(token, {
        title,
        body,
        type: "request_update",
        requestId: event.params.requestId,
        status: afterStatus,
      });
    },
);

exports.notifyOnNewChatMessage = onDocumentCreated(
    "request_chats/{requestId}/messages/{messageId}",
    async (event) => {
      const data = event.data?.data();
      if (!data) return;

      const requestId = event.params.requestId;
      const senderUid = safeString(data.senderUid);
      const senderRole = safeString(data.senderRole);
      const messageText = safeString(data.text, "Nouveau message");

      const requestSnap = await db.collection("requests").doc(requestId).get();
      if (!requestSnap.exists) return;

      const request = requestSnap.data() || {};
      let targetUid = "";

      if (senderRole === "customer") {
        targetUid = safeString(request.providerUid);
      } else if (senderRole === "provider") {
        targetUid = safeString(request.customerUid);
      }

      if (!targetUid || targetUid === senderUid) return;

      const token = await getUserToken(targetUid);
      await sendToToken(token, {
        title: "Nouveau message",
        body: messageText,
        type: "chat",
        requestId,
        status: safeString(request.status),
        senderRole,
      });
    },
);

exports.cleanupInvalidTokens = onDocumentUpdated(
    "users/{userId}",
    async () => null,
);
