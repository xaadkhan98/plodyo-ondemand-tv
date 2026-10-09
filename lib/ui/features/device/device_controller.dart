import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/utils/retry.dart';
import '../../../data/models/auth_exception.dart';
import '../../../data/models/device_models.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/repositories/usage_queue.dart';

/// A catalogue read, retried like any flaky TV network, except a refused credential, which no retry fixes.
Future<T> catalogueRead<T>(Future<T> Function() read) =>
    retry(read, retryIf: (e) => !(e is AuthException && e.statusCode == 401));

/// What this TV may show, resolved on every boot.
sealed class DevicePhase {
  const DevicePhase();
}

class DeviceLoading extends DevicePhase {
  const DeviceLoading();
}

/// No credential on this set: someone has to type a pairing code.
class DeviceUnpaired extends DevicePhase {
  const DeviceUnpaired();
}

/// Refused. One message covers every cause, so the token is kept: a suspension lifts on its own.
class DeviceUnauthorized extends DevicePhase {
  const DeviceUnauthorized();
}

/// Unreachable. The credential is fine and a retry may succeed.
class DeviceUnavailable extends DevicePhase {
  const DeviceUnavailable(this.notice);

  final String notice;
}

class DeviceReady extends DevicePhase {
  const DeviceReady({required this.config, required this.session});

  final DeviceConfig config;
  final DeviceSession session;
}

/// Resolves what this TV may show and, once it is ready, keeps its room online with a heartbeat.
/// The guest's choices live here rather than in storage: a hotel TV is reset between guests by being
/// switched off, and reviving the last guest's language for the next one is worse than starting over.
class DeviceController extends ChangeNotifier {
  DeviceController({DeviceRepository? device, UsageQueue? usage})
    : _device = device ?? sharedDeviceRepository,
      _usage = usage ?? sharedUsageQueue {
    // Observed before the focus tree, so a press a screen consumes still counts as activity.
    HardwareKeyboard.instance.addHandler(_onKey);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    _lifecycle = AppLifecycleListener(onShow: _onShow, onHide: _onHide);
    resolve();
  }

  /// Well inside the console's three-minute "online" window, so one lost beat never reads as offline.
  static const heartbeatInterval = Duration(minutes: 1);

  /// A remote press or a playing story this recent makes a beat count as a guest using the TV.
  static const activeWindow = Duration(minutes: 1);

  final DeviceRepository _device;
  final UsageQueue _usage;
  late final AppLifecycleListener _lifecycle;
  DevicePhase _phase = const DeviceLoading();
  Timer? _timer;
  bool _visible = true;
  bool _beating = false;

  // Bumped by every resolve and by dispose, so a stale answer never lands over a newer phase.
  int _generation = 0;

  DevicePhase get phase => _phase;

  /// The language the catalogue is read in. Null means whatever the room resolves to, not a code.
  String? get language => _language;
  String? _language;

  void chooseLanguage(String? code) {
    _language = code;
    // A guest's pick is usage the venue sees; clearing a filter is not a pick.
    if (code != null) _usage.record(UsageType.languageSelect, language: code);
    notifyListeners();
  }

  void _settle(DevicePhase next) {
    _phase = next;
    _schedule();
    notifyListeners();
  }

  /// Re-reads config and session; also the remedy offered when either fails.
  Future<void> resolve() async {
    final generation = ++_generation;
    if (!_device.isPaired) {
      _settle(const DeviceUnpaired());
      return;
    }
    _settle(const DeviceLoading());
    try {
      // Fetched together: they fail for the same reasons.
      final [config, session] = await Future.wait<Object>([
        _device.getConfig(),
        _device.openSession(),
      ]);
      if (generation == _generation) {
        _settle(
          DeviceReady(
            config: config as DeviceConfig,
            session: session as DeviceSession,
          ),
        );
      }
    } catch (error) {
      if (generation != _generation) return;
      _settle(
        error is AuthException && error.statusCode == 401
            ? const DeviceUnauthorized()
            : DeviceUnavailable(
                messageOf(
                  error,
                  'Cannot reach Plodyo. Check the network connection.',
                ),
              ),
      );
    }
  }

  /// Errors reach the pairing screen, which shows them beside the code.
  Future<void> pair(String pairingCode) async {
    await _device.pair(pairingCode);
    await resolve();
  }

  Future<void> unpair() async {
    _language = null;
    await _device.unpair();
    await resolve();
  }

  // A hidden app sends nothing, so a TV switched to another input reads as offline.
  void _schedule() {
    _timer?.cancel();
    _timer = _phase is DeviceReady && _visible
        ? Timer.periodic(heartbeatInterval, (_) => _beat())
        : null;
  }

  void _onShow() {
    _visible = true;
    _beat();
    _schedule();
  }

  void _onHide() {
    _visible = false;
    _schedule();
    _usage.persistNow();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyUpEvent) _usage.markActive();
    return false;
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) _usage.markActive();
  }

  Future<void> _beat() async {
    final phase = _phase;
    if (phase is! DeviceReady || _beating) return;
    _beating = true;
    final generation = _generation;
    final events = _usage.takeBatch();
    try {
      final session = await _device.heartbeat(
        sessionId: phase.session.sessionId,
        active: _usage.activeWithin(activeWindow),
        events: events,
      );
      _usage.acknowledge(events);
      // A visit that idled out is replaced in place, so This TV shows the session the API now counts.
      if (generation == _generation &&
          session.sessionId != phase.session.sessionId) {
        _settle(DeviceReady(config: phase.config, session: session));
      }
    } catch (error) {
      // A batch the API refuses never succeeds, so it is dropped; anything else is retried next beat.
      if (error is AuthException && error.statusCode == 400) {
        _usage.acknowledge(events);
      }
    } finally {
      _beating = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    _lifecycle.dispose();
    super.dispose();
  }
}

/// Hands the gate's [DeviceController] to the guest screens, rebuilding them when it changes.
class DeviceScope extends InheritedNotifier<DeviceController> {
  const DeviceScope({
    super.key,
    required DeviceController controller,
    required super.child,
  }) : super(notifier: controller);

  static DeviceController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeviceScope>()!.notifier!;
}
