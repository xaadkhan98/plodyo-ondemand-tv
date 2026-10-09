import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/side_nav.dart';
import 'language_menu.dart';

/// Back where the guest came from, or Home when this screen was the first (a restart, a deep link).
void goBack(BuildContext context) =>
    context.canPop() ? context.pop() : context.go('/');

/// A guest screen's frame: the top bar, carrying the language pill, scrolls away with the screen, which
/// sits past the collapsed rail and owns its own gutters so rails can run to the right edge.
class GuestPage extends StatelessWidget {
  const GuestPage({super.key, required this.child}) : _fill = false;

  /// A full-pane state — a spinner, a message, the reader — that takes the height under the bar.
  const GuestPage.fill({super.key, required this.child}) : _fill = true;

  final Widget child;
  final bool _fill;

  @override
  Widget build(BuildContext context) {
    if (_fill) {
      return ConsolePage.fill(actions: const LanguageMenu(), child: child);
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TopBar(actions: LanguageMenu()),
            Padding(
              padding: const EdgeInsets.only(left: SideNav.collapsedWidth),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
