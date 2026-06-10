import 'package:flutter/material.dart';

import '../core/owner_theme.dart';

/// Escudo estilo badge verificado con el logo F de Fernecito adentro.
class LogoEscudoFernecito extends StatelessWidget {
  final double size;
  final Color borderColor;
  final Color fillColor;

  const LogoEscudoFernecito({
    super.key,
    this.size = 88,
    this.borderColor = OwnerTheme.violetaMarca,
    this.fillColor = const Color(0xFF14100E),
  });

  static Path escudoPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    // Escudo redondeado: hombro ancho arriba, punta abajo (estilo verificado Fernecito)
    path.moveTo(w * 0.12, h * 0.08);
    path.lineTo(w * 0.88, h * 0.08);
    path.quadraticBezierTo(w * 0.98, h * 0.12, w * 0.96, h * 0.32);
    path.quadraticBezierTo(w * 0.92, h * 0.62, w * 0.5, h * 0.96);
    path.quadraticBezierTo(w * 0.08, h * 0.62, w * 0.04, h * 0.32);
    path.quadraticBezierTo(w * 0.02, h * 0.12, w * 0.12, h * 0.08);
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final height = size * 1.12;
    final shieldSize = Size(size, height);

    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: shieldSize,
            painter: _EscudoPainter(
              path: escudoPath(shieldSize),
              fillColor: fillColor,
              borderColor: borderColor,
            ),
          ),
          ClipPath(
            clipper: _EscudoClipper(shieldSize),
            child: Padding(
              padding: EdgeInsets.fromLTRB(size * 0.16, size * 0.14, size * 0.16, size * 0.22),
              child: Image.asset(
                'assets/images/logo_f_fernecito.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EscudoClipper extends CustomClipper<Path> {
  final Size shieldSize;

  _EscudoClipper(this.shieldSize);

  @override
  Path getClip(Size size) => LogoEscudoFernecito.escudoPath(shieldSize);

  @override
  bool shouldReclip(covariant _EscudoClipper oldClipper) =>
      oldClipper.shieldSize != shieldSize;
}

class _EscudoPainter extends CustomPainter {
  final Path path;
  final Color fillColor;
  final Color borderColor;

  _EscudoPainter({
    required this.path,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.12), 8, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor,
            Color.lerp(fillColor, borderColor, 0.18)!,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _EscudoPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor || oldDelegate.borderColor != borderColor;
}
