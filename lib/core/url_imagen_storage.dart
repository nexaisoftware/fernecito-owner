import 'package:supabase_flutter/supabase_flutter.dart';

/// Resuelve paths de Storage a URL pública. Si ya es http(s), se devuelve tal cual.
String? urlImagenStorage(String? raw, {required String bucket}) {
  if (raw == null) return null;
  final p = raw.trim();
  if (p.isEmpty) return null;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  return Supabase.instance.client.storage.from(bucket).getPublicUrl(p);
}

String? urlAvatarUsuario(String? raw) =>
    urlImagenStorage(raw, bucket: 'avatars');

String? urlAvatarLocal(String? raw) =>
    urlImagenStorage(raw, bucket: 'avatars_locales');
