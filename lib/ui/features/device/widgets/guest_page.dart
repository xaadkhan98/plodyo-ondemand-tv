import 'package:flutter/material.dart';

import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/side_nav.dart';
import 'language_menu.dart';

/// A guest screen's frame: the top bar, carrying the language pill, scrolls away with the screen, which
/// sits past the collapsed rail and owns its own gutters so rails can run to the right edge.
class GuestPage extends StatelessWidget {
  const GuestPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
