import 'package:flutter/material.dart';

import '../core/owner_layout.dart';
import '../core/owner_theme.dart';
import 'owner_desktop_refresh.dart';

/// Scaffold para subpáginas con refresh en escritorio y ancho contenido.
class OwnerSubpageScaffold extends StatelessWidget {
  const OwnerSubpageScaffold({
    super.key,
    required this.body,
    this.title,
    this.onRefresh,
    this.loading = false,
    this.constrainBody = true,
  });

  final Widget body;
  final String? title;
  final Future<void> Function()? onRefresh;
  final bool loading;
  final bool constrainBody;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final desktop = OwnerLayout.isDesktop(context);

    Widget content = body;
    if (constrainBody) {
      content = OwnerLayout.form(context: context, child: body);
    }

    content = OwnerDesktopRefreshOverlay(
      onRefresh: desktop ? null : onRefresh,
      loading: loading,
      child: content,
    );

    return Scaffold(
      backgroundColor: OwnerTheme.fondo,
      appBar: canPop
          ? AppBar(
              title: title != null
                  ? Text(
                      title!,
                      style: OwnerTheme.baloo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
              actions: [
                if (desktop && onRefresh != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: OwnerRefreshIconButton(
                        loading: loading,
                        onPressed: () => onRefresh!(),
                      ),
                    ),
                  ),
              ],
            )
          : null,
      body: content,
    );
  }
}
