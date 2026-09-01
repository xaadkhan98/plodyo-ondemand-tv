import 'package:flutter/material.dart';
import '../../core/widgets/tv_sidebar.dart';

/// Main TV Application Shell coordinating Sidebar and Screen Navigation.
class MainTvLayout extends StatelessWidget {
  const MainTvLayout({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: Stack(
        children: [
          // Main View Content Canvas (padded to leave room for sidebar)
          Positioned.fill(
            left: 58,
            child: child,
          ),

          // Floating TV Sidebar Rail on Top with Right Shadow
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: TvSidebar(currentPath: currentPath),
          ),
        ],
      ),
    );
  }
}
