const admin = require('firebase-admin');

let initialized = false;

function initializeFirebase() {
  if (initialized) return;

  try {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

    if (serviceAccountJson) {
      const serviceAccount = JSON.parse(serviceAccountJson);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      initialized = true;
    } else if (credentialsPath) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      initialized = true;
    } else {
      console.warn('[FCM] No Firebase credentials found. Push notifications disabled.');
    }
  } catch (err) {
    console.error('[FCM] Firebase initialization error:', err.message);
  }
}

/**
 * Send a push notification to a single device.
 * Returns true on success, false on failure.
 */
async function sendToDevice(fcmToken, title, body, data = {}) {
  if (!initialized || !fcmToken) return false;

  try {
    const message = {
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        notification: {
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default' },
        },
      },
    };

    await admin.messaging().send(message);
    return true;
  } catch (err) {
    // Don't crash — invalid/expired tokens are common
    console.warn('[FCM] sendToDevice error:', err.message);
    return false;
  }
}

// Initialize on module load
initializeFirebase();

module.exports = { sendToDevice };
