import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/device_models.dart';
import 'package:plodyo_ondemand_tv/data/repositories/device_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/usage_queue.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/device_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _config = DeviceConfig(languages: [], ageGroups: []);

DeviceSession _session(String id) => DeviceSession(
  sessionId: id,
  roomId: 'r1',
  startedAt: '2026-10-09T12:00:00Z',
);

/// A device API whose answers each test sets, recording the heartbeats it is sent.
class _Device implements DeviceRepository {
  @override
  bool isPaired = true;

  Future<DeviceConfig> Function() config = () async => _config;
  Future<DeviceSession> Function() session = () async => _session('s1');
  Future<DeviceSession> Function(String sessionId) beat = (id) async =>
      _session(id);
  final beats = <({String sessionId, bool active, List<UsageEvent> events})>[];

  @override
  Future<DeviceConfig> getConfig() => config();

  @override
  Future<DeviceSession> openSession() => session();

  @override
  Future<DeviceSession> heartbeat({
    required String sessionId,
    required bool active,
    required List<UsageEvent> events,
  }) {
    beats.add((sessionId: sessionId, active: active, events: events));
    return beat(sessionId);
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

  Future<DeviceController> start(WidgetTester tester) async {
    final controller = DeviceController(device: device, usage: usage);
    await tester.pumpWidget(_Owner(controller));
    return controller;
  }

  setUp(() {
    device = _Device();
    usage = UsageQueue(device);
  });

  testWidgets('an unpaired TV asks to be set up', (tester) async {
    device.isPaired = false;

    final controller = await start(tester);

    expect(controller.phase, isA<DeviceUnpaired>());
  });

  testWidgets('opens the session alongside config, not after it', (
    tester,
  ) async {
    final config = Completer<DeviceConfig>();
    var sessionAsked = false;
    device
      ..config = (() => config.future)
      ..session = () async {
        sessionAsked = true;
        return _session('s1');
      };

    final controller = await start(tester);
    expect(sessionAsked, isTrue);
    expect(controller.phase, isA<DeviceLoading>());

    config.complete(_config);
    await tester.pump();
    expect(
      controller.phase,
      isA<DeviceReady>().having((p) => p.session.sessionId, 'session', 's1'),
    );
  });

  testWidgets('keeps the credential when the API refuses it', (tester) async {
    device.session = () async =>
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
    'records a guest language pick but not clearing one, and unpairing forgets it',
    (tester) async {
      final controller = await start(tester);

      controller.chooseLanguage('SPA');
      controller.chooseLanguage(null);

      final batch = usage.takeBatch();
      expect(batch.single['type'], 'LANGUAGE_SELECT');
      expect(batch.single['language'], 'SPA');
      controller.chooseLanguage('SPA');
      await controller.unpair();
      expect(controller.language, isNull);
      await usage.persistNow();
    },
  );

  testWidgets(
    'beats once a minute, active only after a remote press, even one a screen consumed',
    (tester) async {
      await start(tester);

      await tester.pump(DeviceController.heartbeatInterval);
      final beat = device.beats.single;
      expect(beat.sessionId, 's1');
      expect(beat.active, isFalse);
      expect(beat.events, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.beats.last.active, isTrue);
    },
  );

  testWidgets(
    'swaps in the session a heartbeat hands back, and beats with it after',
    (tester) async {
      device.beat = (_) async => _session('s2');
      final controller = await start(tester);

      await tester.pump(DeviceController.heartbeatInterval);
      expect(
        controller.phase,
        isA<DeviceReady>().having((p) => p.session.sessionId, 'session', 's2'),
      );

      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.beats.map((b) => b.sessionId), ['s1', 's2']);
    },
  );

  testWidgets(
    'carries queued usage, keeps it through a network failure, and drops a batch the API refuses',
    (tester) async {
      await start(tester);
      final event = usage.record(UsageType.languageSelect, language: 'ENG')!;

      device.beat = (_) async => throw AuthException.network();
      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.beats.last.events, [event]);

      device.beat = (_) async =>
          throw const AuthException(message: 'Bad event', statusCode: 400);
      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.beats.last.events, [event]);

      device.beat = (id) async => _session(id);
      await tester.pump(DeviceController.heartbeatInterval);
      expect(device.beats.last.events, isEmpty);
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
