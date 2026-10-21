import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'ui_kit.dart' show kRootRoutes, parentRouteOf;

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool showAppBar;
  final bool automaticallyImplyLeading;
  final bool useCustomScaffold;

  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.showAppBar = false,
    this.automaticallyImplyLeading = true,
    this.useCustomScaffold = true,
  });

  /// Root tab routes — pressing back on these shows the exit confirmation.
  static const _rootRoutes = kRootRoutes;

  bool _isRootRoute(BuildContext context) {
    try {
      final location = GoRouterState.of(context).matchedLocation;
      return _rootRoutes.contains(location);
    } catch (_) {
      return false;
    }
  }

  bool _routerCanPop(BuildContext context) {
    try {
      return GoRouter.of(context).canPop();
    } catch (_) {
      return Navigator.of(context).canPop();
    }
  }

  /// Back on a page with nothing beneath it (opened from the drawer, a bottom-nav
  /// tab or a deep link): root tabs ask before exiting, sub-pages go to their
  /// parent section instead of closing the app.
  Future<void> _handleBlockedPop(BuildContext context, bool isRoot) async {
    if (!isRoot) {
      String location = '/';
      try {
        location = GoRouterState.of(context).matchedLocation;
      } catch (_) {}
      context.go(parentRouteOf(location));
      return;
    }
    final shouldExit = await _showExitConfirmation(context);
    if (shouldExit && context.mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = _isRootRoute(context);
    final canPop = _routerCanPop(context);

    if (useCustomScaffold) {
      // Screen manages its own Scaffold — just wrap with pop handling.
      return PopScope(
        // Sub-pages can pop freely; only root/tab screens are intercepted.
        canPop: canPop,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          await _handleBlockedPop(context, isRoot);
        },
        child: child,
      );
    }

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBlockedPop(context, isRoot);
      },
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: title != null ? Text(title!) : null,
                actions: actions,
                automaticallyImplyLeading: automaticallyImplyLeading,
                leading: automaticallyImplyLeading && GoRouter.of(context).canPop()
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => GoRouter.of(context).pop(),
                      )
                    : null,
              )
            : null,
        drawer: drawer,
        body: child,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Exit App'),
                ],
              ),
              content: const Text(
                'Are you sure you want to close Metromate?',
                style: TextStyle(fontSize: 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

// Extension to make it easier to use AppScaffold
extension AppScaffoldExtension on Widget {
  Widget withAppScaffold({
    String? title,
    List<Widget>? actions,
    Widget? drawer,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
    Color? backgroundColor,
    bool showAppBar = false,
    bool automaticallyImplyLeading = true,
    bool useCustomScaffold = true,
  }) {
    return AppScaffold(
      title: title,
      actions: actions,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      showAppBar: showAppBar,
      automaticallyImplyLeading: automaticallyImplyLeading,
      useCustomScaffold: useCustomScaffold,
      child: this,
    );
  }
}
