import 'package:flutter/material.dart';

import '../core/owner_theme.dart';

/// Pull-to-refresh con scroll mínimo garantizado (también en vacío/carga).
class OwnerRefreshable extends StatelessWidget {
  const OwnerRefreshable({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: OwnerTheme.violetaMarca,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Refresh sobre un scroll existente (ListView, CustomScrollView hijo, etc.).
class OwnerRefreshScroll extends StatelessWidget {
  const OwnerRefreshScroll({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: OwnerTheme.violetaMarca,
      child: child,
    );
  }
}
