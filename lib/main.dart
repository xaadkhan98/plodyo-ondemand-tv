import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/tv_scale.dart';
import 'core/theme/tv_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Full screen, landscape only: a TV has no system bars worth showing.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PlodyoTvApp());
}

class PlodyoTvApp extends StatelessWidget {
  const PlodyoTvApp({super.key});

  // Remote keys need no mapping here: Flutter's defaults already send Select, Enter and gamepad A to ActivateIntent.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: TvTheme.light,
      routerConfig: appRouter,
      builder: (context, child) => TvCanvas(child: child!),
    );
  }
}
