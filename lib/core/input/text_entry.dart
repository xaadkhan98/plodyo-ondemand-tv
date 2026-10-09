import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Text typed with a remote: one value per field, with every edit going to the [active] one.
class TextEntryController<F extends Enum> extends ChangeNotifier {
  TextEntryController(
    List<F> fields, {
    Map<F, String> initial = const {},
    this.maxLength = 96,
    this.onEdit,
  }) : assert(fields.isNotEmpty),
       _values = {for (final field in fields) field: initial[field] ?? ''},
       _active = fields.first;

  /// Guards against a runaway remote; also the API's column limits.
  final int maxLength;

  /// Fired on every edit, e.g. to drop a stale error message.
  final VoidCallback? onEdit;

  final Map<F, String> _values;
  F _active;

  F get active => _active;

  /// The active field's value.
  String get value => _values[_active]!;

  String operator [](F field) => _values[field]!;

  void focus(F field) {
    if (field == _active) return;
    _active = field;
    notifyListeners();
  }

  void append(String text) =>
      _edit((value) => (value + text).characters.take(maxLength).toString());

  void backspace() => _edit((value) => value.characters.skipLast(1).toString());

  void clear() => _edit((_) => '');

  void _edit(String Function(String value) update) {
    final next = update(value);
    if (next == value) return;
    onEdit?.call();
    _values[_active] = next;
    notifyListeners();
  }
}

/// Wires a [TextEntryController] to the hardware: typed characters append, and Back (or Backspace)
/// deletes — leaving through [onExit] only once the field is empty, so one mistyped character never exits.
class TextEntryScope extends StatelessWidget {
  const TextEntryScope({
    super.key,
    required this.controller,
    this.onExit,
    required this.child,
  });

  final TextEntryController controller;
  final VoidCallback? onExit;
  final Widget child;

  void _back() {
    if (controller.value.isEmpty && onExit != null) {
      onExit!();
    } else {
      controller.backspace();
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    // Escape and Backspace stand in for the remote's Back on keyboards, as in the reference's key map.
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.goBack) {
      _back();
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character != null &&
        character.isNotEmpty &&
        character.codeUnitAt(0) >= 0x20 &&
        character.codeUnitAt(0) != 0x7F) {
      controller.append(character);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // System Back (Android's back key and gesture) arrives as a route pop, not a key event.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: child,
      ),
    );
  }
}
