const { logger } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const fieldValue = admin.firestore.FieldValue;

async function createNotification(userId, title, body, data = {}) {
  await db.collection("notifications").add({
    userId,
    title,
    body,
    data,
    sentAt: fieldValue.serverTimestamp(),
    read: false,
  });
}

function fcmData(data = {}) {
  return Object.fromEntries(
    Object.entries(data ?? {}).map(([key, value]) => [key, String(value)]),
  );
}

exports.sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const notification = event.data.data();
    const user = await db.collection("users").doc(notification.userId).get();
    const token = user.data()?.fcmToken;

    if (!token) {
      logger.info("Skipping push because user has no FCM token", {
        userId: notification.userId,
      });
      return;
    }

    try {
      await admin.messaging().send({
        token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: fcmData(notification.data),
        android: {
          priority: "high",
          notification: {
            channelId: "asal_dairy_channel",
            sound: "default",
          },
        },
      });
    } catch (error) {
      logger.error("Unable to send push notification", error);
      if (
        error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-registration-token"
      ) {
        await user.ref.update({ fcmToken: fieldValue.delete() });
      }
    }
  },
);
