import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/theme/tv_scale.dart';
import 'core/theme/tv_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/device_repository.dart';
import 'data/repositories/usage_queue.dart';
import 'data/services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Full screen, landscape only: a TV has no system bars worth showing.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // A paired TV must know it is paired on its first frame, or it would flash the setup screen; a console,
  // that it is signed in.
  await (
    sharedDeviceRepository.restore(),
    sharedUsageQueue.restore(),
    sharedAuthRepository.restore(),
  ).wait;
  ApiClient.renewBearer = sharedAuthRepository.renew;
  runApp(const PlodyoTvApp());
}

class PlodyoTvApp extends StatelessWidget {
  const PlodyoTvApp({super.key});

  // Remote keys need no mapping here: Flutter's defaults already send Select, Enter and gamepad A to ActivateIntent.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Plodyo TV',
      debugShowCheckedModeBanner: false,
      theme: TvTheme.light,
      routerConfig: appRouter,
      builder: (context, child) => TvCanvas(child: child!),
    );
  }
}
