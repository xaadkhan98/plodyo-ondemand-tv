import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/tv_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set TV fullscreen immersive mode and landscape lock
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const PlodyoTvApp());
}

class PlodyoTvApp extends StatelessWidget {
  const PlodyoTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      // Configure global remote control key mapping
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
      },
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: TvTheme.darkTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
