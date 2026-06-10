import 'package:flutter/material.dart';

import '../core/fernecito_brand.dart';

/// Logo de app (mismo PNG que favicon / splash).
class AppLogoImage extends StatelessWidget {
  final double size;

  const AppLogoImage({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      FernecitoBrand.ownerLogoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
