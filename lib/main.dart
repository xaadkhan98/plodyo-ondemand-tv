import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/tv_theme.dart';
import 'core/constants/app_constants.dart';
import 'ui/features/auth/views/sign_in_view.dart';
import 'ui/features/main_layout.dart';

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

class PlodyoTvApp extends StatefulWidget {
  const PlodyoTvApp({super.key});

  @override
  State<PlodyoTvApp> createState() => _PlodyoTvAppState();
}

class _PlodyoTvAppState extends State<PlodyoTvApp> {
  bool _isSignedIn = false;

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
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: TvTheme.darkTheme,
        home: _isSignedIn
            ? const MainTvLayout()
            : SignInView(
                onSignedIn: () {
                  setState(() {
                    _isSignedIn = true;
                  });
                },
              ),
      ),
    );
  }
}
