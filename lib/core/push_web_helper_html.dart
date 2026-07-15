import 'dart:html' as html;

Future<void> asegurarServiceWorkerPush() async {
  final sw = html.window.navigator.serviceWorker;
  if (sw == null) return;
  try {
    await sw.register('/firebase-messaging-sw.js');
  } catch (_) {}
}

Future<void> mostrarNotificacionForegroundWeb({
  required String titulo,
  String cuerpo = '',
}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;
  try {
    html.Notification(titulo, body: cuerpo, icon: '/icons/apple-touch-icon.png');
  } catch (_) {}
}
