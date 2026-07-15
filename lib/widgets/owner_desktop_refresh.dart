import 'package:flutter/material.dart';

import '../core/owner_layout.dart';
import '../core/owner_theme.dart';

/// Botón compacto de actualizar (escritorio).
class OwnerRefreshIconButton extends StatelessWidget {
  const OwnerRefreshIconButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.tooltip = 'Actualizar',
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OwnerTheme.superficie,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OwnerTheme.borde),
          ),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: OwnerTheme.violetaMarca,
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: OwnerTheme.violetaMarca,
                ),
        ),
      ),
    );
  }
}

/// Overlay con botón refresh esquina superior derecha (solo escritorio).
class OwnerDesktopRefreshOverlay extends StatelessWidget {
  const OwnerDesktopRefreshOverlay({
    super.key,
    required this.child,
    this.onRefresh,
    this.loading = false,
  });

  final Widget child;
  final Future<void> Function()? onRefresh;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final desktop = OwnerLayout.isDesktop(context);
    if (!desktop || onRefresh == null) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 10,
          right: 14,
          child: Tooltip(
            message: 'Actualizar',
            child: OwnerRefreshIconButton(
              loading: loading,
              onPressed: () => onRefresh!(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón principal: ancho completo en móvil, ancho contenido en escritorio.
class OwnerAdaptiveButton extends StatelessWidget {
  const OwnerAdaptiveButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
    this.maxWidth,
  });

  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final bool loading;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final fullWidth = !OwnerLayout.isDesktop(context);
    final btn = FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : (icon ?? const SizedBox.shrink()),
      label: Text(label),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: btn);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? OwnerLayout.actionButtonMaxWidth,
          minWidth: 200,
        ),
        child: btn,
      ),
    );
  }
}
