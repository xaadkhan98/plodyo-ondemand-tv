import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/notice_screen.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';

enum _Field {
  name('Business name', 'Grand Plaza Hotel', LucideIcons.building2, [
    '-',
    '&',
    '.',
    "'",
  ]),
  contactEmail(
    'Contact email',
    'ops@grandplaza.com',
    LucideIcons.mail,
    KeySets.email,
  ),
  contactName(
    'Contact name (optional)',
    'Jordan Lee',
    LucideIcons.userRound,
    KeySets.name,
  ),
  phone('Phone (optional)', '+1-555-0100', LucideIcons.phone, KeySets.phone);

  const _Field(this.label, this.placeholder, this.icon, this.extraKeys);

  final String label;
  final String placeholder;
  final IconData icon;

  /// Trading names carry an ampersand far more often than a person's name does.
  final List<String> extraKeys;
}

/// The API's column limits for a partner.
abstract final class _Limits {
  static const int name = 200;
  static const int contactName = 200;
  static const int phone = 50;
}

/// Self-registration for a venue. INDEPENDENT applications join the approval queue and HOST accounts open
/// at once, so the closing screen says which rather than thanking blandly.
class RegisterVenueView extends StatefulWidget {
  const RegisterVenueView({super.key, this.authRepository, this.onBack});

  final AuthRepository? authRepository;
  final VoidCallback? onBack;

  @override
  State<RegisterVenueView> createState() => _RegisterVenueViewState();
}

class _RegisterVenueViewState extends State<RegisterVenueView> {
  static const _types = [
    Choice(
      value: 'INDEPENDENT',
      label: 'Hotel or guest house',
      description: 'Reviewed by our team before the account opens.',
    ),
    Choice(
      value: 'HOST',
      label: 'Short-let host',
      description: 'Activated straight away, no review needed.',
    ),
  ];

  late final _entry = TextEntryController<_Field>(
    _Field.values,
    maxLength: _Limits.name,
    onEdit: () => setState(() => _error = null),
  );
  final _keyboard = FocusNode();
  String _partnerType = 'INDEPENDENT';
  bool _busy = false;
  String? _error;
  ({String status, String message})? _registration;

  @override
  void dispose() {
    _entry.dispose();
    _keyboard.dispose();
    super.dispose();
  }

  void _back() => widget.onBack != null
      ? widget.onBack!()
      : (context.canPop() ? context.pop() : context.go('/sign-in'));

  Future<void> _submit() async {
    // Ordered so the message names the first field that needs fixing.
    final invalid =
        validateRequired(
          _entry[_Field.name],
          'business name',
          maxLength: _Limits.name,
        ) ??
        validateEmail(_entry[_Field.contactEmail], label: 'contact email') ??
        validateMaxLength(
          _entry[_Field.contactName],
          'contact name',
          _Limits.contactName,
        ) ??
        validateMaxLength(_entry[_Field.phone], 'phone number', _Limits.phone);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() => _busy = true);
    try {
      final response = await (widget.authRepository ?? sharedAuthRepository)
          .registerVenue(
            name: _entry[_Field.name].trim(),
            partnerType: _partnerType,
            contactEmail: _entry[_Field.contactEmail].trim(),
            contactName: _entry[_Field.contactName].trim(),
            phone: _entry[_Field.phone].trim(),
          );
      if (!mounted) return;
      setState(
        () => _registration = (
          status: response['status'] as String? ?? '',
          message: response['message'] as String? ?? '',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not send the registration.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_registration case final registration?) {
      final active = registration.status == 'ACTIVE';
      return Scaffold(
        body: NoticeScreen(
          icon: Icon(
            active ? LucideIcons.sparkles : LucideIcons.circleCheck,
            size: 4 * rem,
            color: TvColors.primary,
          ),
          title: active ? 'Your account is ready' : 'Registration received',
          body: registration.message,
          footnote: active
              ? 'Check your email for an invite to set a password, then sign in on this TV.'
              : 'We will email you once it has been reviewed. Nothing else is needed from you now.',
          actions: [NoticeAction(label: 'Back to sign in', onSelect: _back)],
        ),
      );
    }

    return Scaffold(
      body: TextEntryScope(
        controller: _entry,
        onExit: _back,
        child: CenteredScrollView(
          alignment: Alignment.topCenter,
          child: Entrance(
            rise: 20,
            duration: const Duration(milliseconds: 450),
            child: ListenableBuilder(
              listenable: _entry,
              builder: (context, _) => KeyboardFormLayout(
                maxWidth: 93.75 * rem,
                alignTop: true,
                keyboardLabel:
                    'Entering ${_entry.active.label.replaceAll(' (optional)', '')}',
                keyboard: OnScreenKeyboard(
                  controller: _entry,
                  extraKeys: _entry.active.extraKeys,
                  entryFocusNode: _keyboard,
                ),
                form: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenHeading('Register your venue', tight: true),
                    const SizedBox(height: 0.5 * rem),
                    const ScreenSubtitle(
                      'Tell us who you are and we will set up a Plodyo account for your rooms.',
                      maxCh: 52,
                    ),
                    const SizedBox(height: 1.75 * rem),
                    ChoiceGroup<String>(
                      label: 'Business type',
                      value: _partnerType,
                      options: _types,
                      disabled: _busy,
                      onChanged: (type) => setState(() => _partnerType = type),
                    ),
                    const SizedBox(height: 1.5 * rem),
                    for (final field in _Field.values) ...[
                      if (field != _Field.name)
                        const SizedBox(height: 0.75 * rem),
                      TvTextField(
                        label: field.label,
                        value: _entry[field],
                        placeholder: field.placeholder,
                        icon: field.icon,
                        autofocus: field == _Field.name,
                        active: _entry.active == field,
                        keyboardFocusNode: _keyboard,
                        onSelect: () => _entry.focus(field),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: rem),
                      StatusMessage(tone: StatusTone.error, message: _error!),
                    ],
                    const SizedBox(height: 1.5 * rem),
                    TvButton(
                      label: 'Send registration',
                      busy: _busy,
                      busyLabel: 'Sending…',
                      fullWidth: true,
                      onSelect: _submit,
                    ),
                    const SizedBox(height: 0.75 * rem),
                    TvButton(
                      label: 'Back to sign in',
                      icon: LucideIcons.arrowLeft,
                      variant: TvButtonVariant.quiet,
                      size: TvButtonSize.sm,
                      fullWidth: true,
                      disabled: _busy,
                      onSelect: _back,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
