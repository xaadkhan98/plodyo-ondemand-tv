import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/notice_screen.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';

enum _Field { email }

/// Requests a password reset link. The API's acknowledgement is shown verbatim: it reads the same whether
/// or not the account exists, and rewording it would leak which addresses are registered.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key, this.authRepository, this.onBack});

  final AuthRepository? authRepository;
  final VoidCallback? onBack;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    onEdit: () => setState(() => _error = null),
  );
  bool _busy = false;
  String? _error;
  String? _acknowledgement;

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _back() => widget.onBack != null
      ? widget.onBack!()
      : (context.canPop() ? context.pop() : context.go('/sign-in'));

  Future<void> _submit() async {
    final email = _entry[_Field.email];
    final invalid = validateEmail(email);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() => _busy = true);
    try {
      final message = await (widget.authRepository ?? sharedAuthRepository)
          .forgotPassword(email: email.trim());
      if (mounted) setState(() => _acknowledgement = message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not send a reset link.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_acknowledgement != null) {
      return Scaffold(
        body: NoticeScreen(
          icon: const Icon(
            LucideIcons.mailCheck,
            size: 4 * rem,
            color: TvColors.primary,
          ),
          title: 'Check your email',
          body: _acknowledgement,
          footnote:
              'Open the link on a phone or computer to choose a new password. The link expires in an hour.',
          actions: [NoticeAction(label: 'Back to sign in', onSelect: _back)],
        ),
      );
    }

    return Scaffold(
      body: TextEntryScope(
        controller: _entry,
        onExit: _back,
        child: CenteredScrollView(
          child: Entrance(
            rise: 20,
            duration: const Duration(milliseconds: 450),
            child: KeyboardFormLayout(
              keyboardLabel: 'Entering email address',
              keyboard: OnScreenKeyboard(
                controller: _entry,
                extraKeys: KeySets.email,
              ),
              form: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ScreenHeading('Reset your password', tight: true),
                  const SizedBox(height: 0.5 * rem),
                  const ScreenSubtitle(
                    'Enter the account email and we will send a link to choose a new password.',
                    maxCh: 46,
                  ),
                  const SizedBox(height: 2 * rem),
                  // The only field, so it is always the one typing: no reason to make it a stop on the D-pad.
                  ListenableBuilder(
                    listenable: _entry,
                    builder: (context, _) => TvTextField(
                      label: 'Email',
                      value: _entry[_Field.email],
                      placeholder: 'you@venue.com',
                      icon: LucideIcons.mail,
                      active: true,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: rem),
                    StatusMessage(tone: StatusTone.error, message: _error!),
                  ],
                  const SizedBox(height: 1.5 * rem),
                  TvButton(
                    label: 'Send reset link',
                    autofocus: true,
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
                    onSelect: _back,
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
