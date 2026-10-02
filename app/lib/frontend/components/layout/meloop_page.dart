import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';

/// A scrollable page with safe areas and keyboard resize; no fixed text heights.
class MeloopPage extends StatelessWidget {
  const MeloopPage({
    super.key,
    required this.child,
    this.topBar,
    this.bottomNavigation,
    this.padding,
    this.scrollController,
    this.topBarGap = TempoSpace.xl,
    this.hideBottomNavigationWithKeyboard = true,
  });
  final Widget child;
  final Widget? topBar;
  final Widget? bottomNavigation;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final double topBarGap;
  final bool hideBottomNavigationWithKeyboard;

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TempoSize.contentMaxWidth,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding:
                padding ??
                const EdgeInsets.fromLTRB(
                  TempoSpace.page,
                  TempoSpace.pageTop,
                  TempoSpace.page,
                  TempoSpace.pageBottom,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (topBar != null) ...[topBar!, SizedBox(height: topBarGap)],
                child,
              ],
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar:
        hideBottomNavigationWithKeyboard &&
            MediaQuery.viewInsetsOf(context).bottom > 0
        ? null
        : bottomNavigation == null
        ? null
        : Padding(
            padding: EdgeInsets.only(
              bottom: hideBottomNavigationWithKeyboard
                  ? 0
                  : MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: bottomNavigation,
          ),
  );
}

class MeloopResponsiveRow extends StatelessWidget {
  const MeloopResponsiveRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final vertical =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(16) > 20;
      return vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: TempoSpace.md,
              children: children,
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: TempoSpace.md,
              children: children
                  .map((child) => Expanded(child: child))
                  .toList(),
            );
    },
  );
}

class MeloopCard extends StatelessWidget {
  const MeloopCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(TempoSpace.lg),
  });
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: padding, child: child),
  );
}
