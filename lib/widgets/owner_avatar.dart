import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/url_imagen_storage.dart';

/// Avatar con resolución de Storage (usuarios → avatars, locales → avatars_locales).
class OwnerAvatar extends StatelessWidget {
  const OwnerAvatar({
    super.key,
    required this.fotoRaw,
    required this.fallback,
    this.esLocal = false,
    this.radius = 22,
  });

  final String? fotoRaw;
  final String fallback;
  final bool esLocal;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = esLocal ? urlAvatarLocal(fotoRaw) : urlAvatarUsuario(fotoRaw);
    final initial =
        fallback.isNotEmpty ? fallback.characters.first.toUpperCase() : '?';

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFEDE9FE),
        child: ClipOval(
          child: Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(initial),
          ),
        ),
      );
    }

    return _fallback(initial);
  }

  Widget _fallback(String initial) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEDE9FE),
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: const Color(0xFF5A2EFF),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
