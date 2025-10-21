import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
    this.showAppBar = true,
    this.automaticallyImplyLeading = true,
    this.useCustomScaffold = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useCustomScaffold) {
      // For screens that have their own Scaffold (like HomeScreen)
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          
          // Check if we can pop (go back to previous screen)
          if (GoRouter.of(context).canPop()) {
            // Go back to previous screen
            GoRouter.of(context).pop();
          } else {
            // Show exit confirmation dialog
            final shouldExit = await _showExitConfirmation(context);
            if (shouldExit && context.mounted) {
              SystemNavigator.pop();
            }
          }
        },
        child: child,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Check if we can pop (go back to previous screen)
        if (GoRouter.of(context).canPop()) {
          // Go back to previous screen
          GoRouter.of(context).pop();
        } else {
          // Show exit confirmation dialog
          final shouldExit = await _showExitConfirmation(context);
          if (shouldExit && context.mounted) {
            SystemNavigator.pop();
          }
        }
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
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
    bool showAppBar = true,
    bool automaticallyImplyLeading = true,
    bool useCustomScaffold = false,
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
