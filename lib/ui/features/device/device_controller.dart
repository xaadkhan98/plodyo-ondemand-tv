import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/languages.dart';
import '../../../core/constants/legal.dart';
import '../../../core/utils/retry.dart';
import '../../../data/models/auth_exception.dart';
import '../../../data/models/device_models.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../data/repositories/usage_queue.dart';

/// A catalogue read, retried like any flaky TV network, except a refusal no retry fixes: a refused
/// credential, a bad request, or a story or series that is gone.
Future<T> catalogueRead<T>(Future<T> Function() read) => retry(
  read,
  retryIf: (e) =>
      !(e is AuthException && const {400, 401, 404}.contains(e.statusCode)),
);

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
  const DeviceReady({required this.config});

  final DeviceConfig config;
}

/// What the catalogue screens read: the languages and ages on offer, and the viewer's picks. The picks live
/// here rather than in storage: a hotel TV is reset between guests by being switched off, and reviving the
/// last guest's language for the next one is worse than starting over. They never leave the TV on their own.
abstract class LibrarySession extends ChangeNotifier {
  /// What the pickers offer; null while a TV's room is unresolved.
  DeviceConfig? get config;

  /// The language the catalogue is read in. Null means whatever the reader's default resolves to, not a code.
  String? get language => _language;
  String? _language;

  void chooseLanguage(String? code) {
    _language = code;
    notifyListeners();
  }

  /// Who's watching, kept across the stories, series and learning screens. Null is every age.
  AgeGroup? get ageGroup => _ageGroup;
  AgeGroup? _ageGroup;

  void chooseAgeGroup(AgeGroup? group) {
    _ageGroup = group;
    notifyListeners();
  }
}

/// The console's library: every language and age the API serves, with no room behind it, so nothing is
/// recorded. English is what /admin/content reads when no language is asked for.
class ConsoleLibrary extends LibrarySession {
  @override
  final DeviceConfig config = const DeviceConfig(
    languages: languages,
    ageGroups: AgeGroup.values,
    defaultLanguage: 'ENG',
  );
}

/// Resolves what this TV may show and, once it is ready, keeps its room online with a heartbeat. Guards the
/// catalogue behind the Terms notice, and reports viewing to the property's totals.
class DeviceController extends LibrarySession {
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

  @override
  DeviceConfig? get config => switch (_phase) {
    DeviceReady(:final config) => config,
    _ => null,
  };

  /// The Terms notice stands before any content: on every cold start, and again after [noticeIdleLimit].
  bool get noticeDue => _noticeDue;
  bool _noticeDue = true;

  // Notices not yet sent; they ride the next heartbeat.
  final List<Map<String, Object?>> _notices = [];

  /// The notice is on screen.
  void noticeShown() => _logNotice('notice_shown');

  /// Continue: a grown-up agreed, and the catalogue opens.
  void acceptNotice() {
    _logNotice('notice_accepted');
    _usage.markActive();
    _noticeDue = false;
    notifyListeners();
  }

  // The device and the Terms version only: never content or anything about the child.
  void _logNotice(String event) {
    _notices.add({
      'event': event,
      'terms_version': termsVersion,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    });
    // ponytail: held in memory and sent at once, so a power cut before it lands loses it; persist if needed.
    _beat();
  }

  bool get _idleTooLong => !_usage.activeWithin(noticeIdleLimit);

  void _dueIfIdle() {
    if (_noticeDue || !_idleTooLong) return;
    _noticeDue = true;
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
      final config = await _device.getConfig();
      if (generation == _generation) _settle(DeviceReady(config: config));
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
    _ageGroup = null;
    _noticeDue = true;
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

  // Time in standby counts as untouched, so a TV woken after the idle limit shows the notice first.
  void _onShow() {
    _visible = true;
    if (_phase is DeviceReady) _dueIfIdle();
    _beat();
    _schedule();
  }

  void _onHide() {
    _visible = false;
    _schedule();
    _usage.persistNow();
  }

  // A press past the idle limit wakes the notice, and is spent on it rather than on whatever was focused.
  bool _onKey(KeyEvent event) {
    if (event is KeyUpEvent) return false;
    final wakes = _phase is DeviceReady && !_noticeDue && _idleTooLong;
    _usage.markActive();
    if (wakes) {
      _noticeDue = true;
      notifyListeners();
    }
    return wakes;
  }

  void _onPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    if (_phase is DeviceReady) _dueIfIdle();
    _usage.markActive();
  }

  Future<void> _beat() async {
    if (_phase is! DeviceReady || _beating) return;
    _dueIfIdle();
    _beating = true;
    final notices = [..._notices];
    final events = _usage.takeBatch();
    try {
      await _send(
        () => _device.heartbeat(
          appVersion: ApiConstants.appVersion,
          notices: notices,
        ),
        () => _notices.removeRange(0, notices.length),
      );
      if (events.isNotEmpty) {
        await _send(
          () => _device.reportViewing(events),
          () => _usage.acknowledge(events),
        );
      }
    } finally {
      _beating = false;
    }
  }

  /// Sends, then forgets what went. A refusal never succeeds, so it is forgotten too; anything else retries.
  static Future<void> _send(
    Future<void> Function() send,
    void Function() forget,
  ) async {
    try {
      await send();
      forget();
    } catch (error) {
      if (error is AuthException && error.statusCode == 400) forget();
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

/// Hands the catalogue screens their [LibrarySession], rebuilding them when it changes: a paired TV's
/// [DeviceController], or the console's [ConsoleLibrary].
class DeviceScope extends InheritedNotifier<LibrarySession> {
  const DeviceScope({
    super.key,
    required LibrarySession session,
    required super.child,
  }) : super(notifier: session);

  static LibrarySession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeviceScope>()!.notifier!;
}
