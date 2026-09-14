/* Background push only. Flutter assets are not cached by this service worker. */
importScripts('/firebase-config.js');
if (!self.KEEKOT_USE_EMULATORS) {
  importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
  importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');
  firebase.initializeApp(self.KEEKOT_FIREBASE_CONFIG);
  firebase.messaging();
  // Notification payloads display automatically. Do not also call showNotification,
  // which would duplicate foreground/background messages.
}
