/// Global constants for the TV app layout and animation timings.
class AppConstants {
  AppConstants._();

  static const String appName = 'Plodyo TV';
  
  // Animation Durations
  static const Duration focusAnimationDuration = Duration(milliseconds: 200);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration sidebarExpandDuration = Duration(milliseconds: 250);

  // Dimensions
  static const double sidebarCollapsedWidth = 72.0;
  static const double sidebarExpandedWidth = 220.0;
  
  // Card dimensions (standard 16:9 and 2:3 poster aspect ratios)
  static const double posterWidth = 140.0;
  static const double posterHeight = 210.0;

  static const double backdropWidth = 260.0;
  static const double backdropHeight = 150.0;

  static const double heroHeight = 380.0;
}
