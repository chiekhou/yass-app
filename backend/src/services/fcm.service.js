const admin = require('firebase-admin');

let initialized = false;

function initializeFirebase() {
  if (initialized) return;

  try {
    const projectId    = process.env.FIREBASE_PROJECT_ID;
    const clientEmail  = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey   = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    if (projectId && clientEmail && privateKey) {
      admin.initializeApp({
        credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
      });
      initialized = true;
    } else {
      console.warn('[FCM] Firebase credentials missing in .env. Push notifications disabled.');
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
