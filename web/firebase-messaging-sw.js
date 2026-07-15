/* global firebase, self, clients */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');
importScripts('/firebase-config-sw.js');

const ICON = '/icons/apple-touch-icon.png';
const BADGE = '/icons/favicon-32.png';
const APP_URL = 'https://fernecitoapp.online/';

function payloadToNotification(payload) {
  const n = payload.notification || {};
  const d = payload.data || {};
  return {
    title: n.title || d.title || 'Fernecito Owner',
    options: {
      body: n.body || d.body || '',
      icon: n.icon || d.icon || ICON,
      badge: BADGE,
      tag: d.tag || d.tipo || 'fernecito-owner-push',
      requireInteraction: d.urgente === 'true',
      data: {
        ...d,
        url: d.url || d.link || APP_URL,
      },
    },
  };
}

if (self.fernecitoFirebaseConfig) {
  firebase.initializeApp(self.fernecitoFirebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const { title, options } = payloadToNotification(payload);
    return self.registration.showNotification(title, options);
  });
}

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = event.notification.data?.url || APP_URL;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if ('focus' in client) {
          client.navigate(target);
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(target);
      }
      return undefined;
    }),
  );
});
