import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/outset_shadow.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/repositories/device_repository.dart';
import '../device_controller.dart';
import '../widgets/guest_page.dart';
import '../widgets/story_grid.dart';

const _minTerm = 2;
const _maxTerm = 40;

enum _Field { term }

/// Public films in this room's language, a row per language of a film; a title search is the one filter.
class VideosView extends StatefulWidget {
  const VideosView({super.key, this.deviceRepository});

  final DeviceRepository? deviceRepository;

  @override
  State<VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends State<VideosView> {
  late final DeviceRepository _catalogue =
      widget.deviceRepository ?? sharedDeviceRepository;
  late final TextEntryController<_Field> _entry = TextEntryController(
    _Field.values,
    maxLength: _maxTerm,
  )..addListener(_onType);
  final _toggle = FocusNode();
  Timer? _settle;
  String _settled = '';
  bool _keyboardOpen = false;

  // False while a film plays over this screen, so typing then leaves the search alone.
  bool _onScreen = true;

  @override
  void initState() {
    super.initState();
    // A physical keyboard types into the search wherever the ring is, the side rail included.
    HardwareKeyboard.instance.addHandler(_onKeyboard);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onScreen = TickerMode.valuesOf(context).enabled;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyboard);
    _settle?.cancel();
    _entry.dispose();
    _toggle.dispose();
    super.dispose();
  }

  bool _onKeyboard(KeyEvent event) {
    final text = _onScreen ? typedText(event) : null;
    if (text == null) return false;
    _entry.append(text);
    return true;
  }

  // The query shows every key at once; the search waits for a pause in typing.
  void _onType() {
    _settle?.cancel();
    _settle = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _settled = _entry.value.trim()),
    );
    setState(() {});
  }

  // Back with nothing left to delete closes the keyboard, and the ring goes back to the toggle.
  void _close() {
    setState(() => _keyboardOpen = false);
    _toggle.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final language = DeviceScope.of(context).language;
    final search = _settled.length >= _minTerm ? _settled : null;
    return TextEntryScope(
      controller: _entry,
      holdsBack: _keyboardOpen,
      onExit: _close,
      child: GuestPage(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TvInsets.safeX,
            vertical: TvInsets.safeY,
          ),
          child: StoryGrid(
            query: (language, search),
            noun: 'videos',
            emptyHint: search == null
                ? 'Try a different language.'
                : 'Try a different word.',
            fetchPage: (page) => catalogueRead(
              () => _catalogue.getVideos(
                language: language,
                search: search,
                page: page,
                pageSize: gridPageSize,
              ),
            ),
            onSelect: (video) => openVideo(context, video),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 2 * rem),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 1.5 * rem,
                children: [
                  const PageTitle(
                    icon: LucideIcons.clapperboard,
                    title: 'Videos',
                    subtitle: 'Cartoon films to watch together 🎬',
                  ),
                  _SearchCard(
                    term: _entry.value,
                    entry: _entry,
                    open: _keyboardOpen,
                    toggle: _toggle,
                    onToggle: () =>
                        setState(() => _keyboardOpen = !_keyboardOpen),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The search toggle beside what has been typed, and the keyboard under them while it is open.
class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.term,
    required this.entry,
    required this.open,
    required this.toggle,
    required this.onToggle,
  });

  final String term;
  final TextEntryController entry;
  final bool open;
  final FocusNode toggle;
  final VoidCallback onToggle;

  static final _shadow = [TvShadows.css(const Color(0x994C1D95), 14, 34, -24)];
  static const _radius = BorderRadius.all(Radius.circular(2 * rem));
  static const _pill = BorderRadius.all(Radius.circular(999));

  /// A floor in px: these are a child's targets too.
  static const _minHeight = BoxConstraints(minHeight: 48 * px);

  @override
  Widget build(BuildContext context) {
    // The shadow is outset only, or it would tint the translucent fill.
    return OutsetShadow(
      shadows: _shadow,
      borderRadius: _radius,
      child: Container(
        padding: const EdgeInsets.all(0.75 * rem),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: _radius,
          border: Border.all(color: Colors.white, width: 2 * px),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 0.75 * rem,
              children: [
                TvFocusable(
                  focusNode: toggle,
                  borderRadius: _pill,
                  semanticLabel: open ? 'Done' : 'Search',
                  onSelect: onToggle,
                  builder: (context, focused) {
                    final lit = focused || open;
                    final ink = lit ? Colors.white : TvColors.primaryInk;
                    return AnimatedContainer(
                      duration: TvMotion.focusDuration,
                      constraints: _minHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 1.5 * rem,
                        vertical: 0.5 * rem,
                      ),
                      decoration: BoxDecoration(
                        color: lit ? null : TvColors.secondary,
                        gradient: lit ? TvColors.brandBold : null,
                        borderRadius: _pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 0.5 * rem,
                        children: [
                          Icon(
                            LucideIcons.search500,
                            size: 1.25 * rem,
                            color: ink,
                          ),
                          Text(
                            open ? 'Done' : 'Search',
                            style: TvText.sm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    constraints: _minHeight,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 1.25 * rem),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: _pill,
                      boxShadow: [
                        BoxShadow(color: Color(0x0F000000), spreadRadius: px),
                      ],
                    ),
                    child: Text(
                      term.isEmpty ? 'Search videos by title…' : term,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvText.sm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: term.isEmpty
                            ? TvColors.mutedForeground
                            : TvColors.foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.only(top: rem),
                child: OnScreenKeyboard(controller: entry),
              ),
          ],
        ),
      ),
    );
  }
}
