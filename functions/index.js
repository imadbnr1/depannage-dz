const admin = require("firebase-admin");
const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

function safeString(value, fallback = "") {
  return typeof value === "string" ? value : fallback;
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

exports.notifyProviderOnNewRequest = onDocumentCreated(
    "requests/{requestId}",
    async (event) => {
      const data = event.data?.data();
      if (!data) return;

      const providerUid = safeString(data.offeredProviderUid);
      if (!providerUid) return;

      const token = await getUserToken(providerUid);
      await sendToToken(token, {
        title: "Nouvelle mission",
        body: `${safeString(data.customerName, "Client")} a besoin d'aide.`,
        type: "new_order",
        requestId: event.params.requestId,
        status: safeString(data.status),
      });
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
    async () => {
      // Placeholder for future token cleanup strategy if desired.
      return;
    },
);