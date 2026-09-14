import 'package:flutter/material.dart';
import '../../core/widgets/tv_sidebar.dart';

/// Main TV Application Shell coordinating dynamic Sidebar and Screen Navigation.
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
          // Main View Content Canvas (padded by 74px to leave room for the collapsed rail)
          Positioned.fill(
            left: 74,
            child: child,
          ),

          // Floating TV Sidebar Rail on Top with Dynamic Expansion
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
