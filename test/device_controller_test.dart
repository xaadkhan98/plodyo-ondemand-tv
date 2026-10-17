import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/constants/api_constants.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/device_models.dart';
import 'package:plodyo_ondemand_tv/data/repositories/device_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/usage_queue.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/device_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _config = DeviceConfig(languages: [], ageGroups: [], roomId: 'r1');

/// A device API whose answers each test sets, recording what it is sent.
class _Device implements DeviceRepository {
  @override
  bool isPaired = true;

  Future<DeviceConfig> Function() config = () async => _config;
  Future<void> Function() beat = () async {};
  Future<void> Function() report = () async {};
  final beats = <({String appVersion, List<Map<String, Object?>> notices})>[];
  final reports = <List<Map<String, Object?>>>[];

  @override
  Future<DeviceConfig> getConfig() => config();

  @override
  Future<void> heartbeat({
    required String appVersion,
    required List<Map<String, Object?>> notices,
  }) {
    beats.add((appVersion: appVersion, notices: notices));
    return beat();
  }

  @override
  Future<void> reportViewing(List<Map<String, Object?>> slices) {
    reports.add(slices);
    return report();
  }

  @override
  Future<void> pair(String pairingCode) async => isPaired = true;

  @override
  Future<void> unpair() async => isPaired = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _Device device;
  late UsageQueue usage;
  // The queue's clock, which is what "idle" is measured on.
  late DateTime now;

  Future<DeviceController> start(WidgetTester tester) async {
    final controller = DeviceController(device: device, usage: usage);
    await tester.pumpWidget(_Owner(controller));
    return controller;
  }

  setUp(() {
    now = DateTime.utc(2026, 10, 25, 20);
    device = _Device();
    usage = UsageQueue(device, now: () => now);
  });

  testWidgets('an unpaired TV asks to be set up', (tester) async {
    device.isPaired = false;

    final controller = await start(tester);

    expect(controller.phase, isA<DeviceUnpaired>());
  });

  testWidgets('is ready on config alone, with the room it is paired to', (
    tester,
  ) async {
    final controller = await start(tester);

    expect(
      controller.phase,
      isA<DeviceReady>().having((p) => p.config.roomId, 'room', 'r1'),
    );
  });

  testWidgets('keeps the credential when the API refuses it', (tester) async {
    device.config = () async =>
        throw const AuthException(message: 'Unauthorized', statusCode: 401);

    final controller = await start(tester);

    expect(controller.phase, isA<DeviceUnauthorized>());
    expect(device.isPaired, isTrue);
  });

  testWidgets('separates a network fault from a refused credential', (
    tester,
  ) async {
    device.config = () async =>
        throw AuthException.network('Cannot reach Plodyo TV.');

    final controller = await start(tester);

    expect(
      controller.phase,
      isA<DeviceUnavailable>().having(
        (p) => p.notice,
        'notice',
        'Cannot reach Plodyo TV.',
      ),
    );
  });

  testWidgets('pairing resolves to ready; unpairing returns to setup', (
    tester,
  ) async {
    device.isPaired = false;
    final controller = await start(tester);

    await controller.pair('4F7K-92QT');
    expect(controller.phase, isA<DeviceReady>());

    await controller.unpair();
    expect(controller.phase, isA<DeviceUnpaired>());
  });

  testWidgets(
    "keeps a guest's language and age on this TV, sending neither, and unpairing forgets both",
    (tester) async {
      final controller = await start(tester);

      controller
        ..chooseLanguage('SPA')
        ..chooseAgeGroup(AgeGroup.toddler);
      await tester.pump(DeviceController.heartbeatInterval);

      expect(controller.ageGroup, AgeGroup.toddler);
      expect(usage.takeBatch(), isEmpty);
      expect(device.reports, isEmpty);
      await controller.unpair();
      expect(controller.language, isNull);
      expect(controller.ageGroup, isNull);
    },
  );

  testWidgets(
    'beats once a minute with the app version, and reports viewing only when there is some',
    (tester) async {
      await start(tester);

      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.beats.single.appVersion, ApiConstants.appVersion);
      expect(device.reports, isEmpty);

      final slice = usage.start('s1')!;
      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.reports.single.single['id'], slice['id']);
      await usage.persistNow();
    },
  );

  testWidgets(
    'keeps viewing through a network failure, and drops a batch the API refuses',
    (tester) async {
      await start(tester);
      final slice = usage.start('s1')!;

      device.report = () async => throw AuthException.network();
      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.reports.last.single['id'], slice['id']);

      device.report = () async =>
          throw const AuthException(message: 'Bad slice', statusCode: 400);
      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.reports.last.single['id'], slice['id']);

      device.report = () async {};
      await tester.pump(DeviceController.heartbeatInterval);
      expect(usage.takeBatch(), isEmpty);
      await usage.persistNow();
    },
  );

  testWidgets('sends nothing while hidden, and beats at once on waking', (
    tester,
  ) async {
    await start(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(DeviceController.heartbeatInterval * 3);
    expect(device.beats, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(device.beats, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}

/// Owns the controller as the gate does, so the framework disposes it before checking for live timers.
class _Owner extends StatefulWidget {
  const _Owner(this.controller);

  final DeviceController controller;

  @override
  State<_Owner> createState() => _OwnerState();
}

class _OwnerState extends State<_Owner> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
