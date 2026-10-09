import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../cubit/sign_in_cubit.dart';
import '../cubit/sign_in_state.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';

enum _Field { email, password }

/// Console sign-in on a TV. Text comes from the on-screen keyboard: a native field would summon the TV's IME.
class SignInView extends StatefulWidget {
  const SignInView({
    super.key,
    this.onSignedIn,
    this.onBack,
    this.onForgotPassword,
    this.onRegisterVenue,
    this.cubit,
  });

  final VoidCallback? onSignedIn;
  final VoidCallback? onBack;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onRegisterVenue;
  final SignInCubit? cubit;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  late final SignInCubit _cubit =
      widget.cubit ??
      SignInCubit(
        authRepository: sharedAuthRepository,
        notice: sharedAuthRepository.takeNotice(),
      );
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    onEdit: _cubit.clearError,
  );
  final _keyboard = FocusNode();

  @override
  void dispose() {
    if (widget.cubit == null) _cubit.close();
    _entry.dispose();
    _keyboard.dispose();
    super.dispose();
  }

  void _back() => widget.onBack != null
      ? widget.onBack!()
      : (context.canPop() ? context.pop() : context.go('/'));

  void _submit() => _cubit.signIn(
    email: _entry[_Field.email],
    password: _entry[_Field.password],
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInCubit, SignInState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state is SignInSuccess) {
          widget.onSignedIn != null
              ? widget.onSignedIn!()
              : context.go('/overview');
        }
      },
      builder: (context, state) {
        final busy = state is SignInLoading;
        return Scaffold(
          body: TextEntryScope(
            controller: _entry,
            onExit: _back,
            child: CenteredScrollView(
              child: Entrance(
                rise: 20,
                duration: const Duration(milliseconds: 450),
                child: KeyboardFormLayout(
                  keyboardOffset: 2 * rem,
                  keyboard: OnScreenKeyboard(
                    controller: _entry,
                    extraKeys: KeySets.email,
                    entryFocusNode: _keyboard,
                  ),
                  form: ListenableBuilder(
                    listenable: _entry,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: _BrandPill(),
                        ),
                        const SizedBox(height: 0.75 * rem),
                        const ScreenHeading('Sign in to the TV', tight: true),
                        const SizedBox(height: 0.5 * rem),
                        // Not "start reading": an account manages venues; the TVs show the library themselves.
                        const ScreenSubtitle(
                          'Manage venues, properties, rooms and the people who run them.',
                          maxCh: 46,
                        ),
                        const SizedBox(height: 2 * rem),
                        _field(
                          _Field.email,
                          'Email',
                          'you@venue.com',
                          LucideIcons.mail,
                          autofocus: true,
                        ),
                        const SizedBox(height: rem),
                        _field(
                          _Field.password,
                          'Password',
                          'Your password',
                          LucideIcons.lock,
                          mask: true,
                        ),
                        if (state is SignInFailure) ...[
                          const SizedBox(height: rem),
                          StatusMessage(
                            tone: StatusTone.error,
                            message: state.errorMessage,
                          ),
                        ],
                        // Full width like the fields, so "down" from the password lands here, not on the keyboard.
                        const SizedBox(height: 1.5 * rem),
                        TvButton(
                          label: 'Sign in',
                          busy: busy,
                          busyLabel: 'Signing in…',
                          fullWidth: true,
                          onSelect: _submit,
                        ),
                        const SizedBox(height: 0.75 * rem),
                        TvButton(
                          label: 'Forgot password?',
                          variant: TvButtonVariant.quiet,
                          size: TvButtonSize.sm,
                          fullWidth: true,
                          disabled: busy,
                          onSelect:
                              widget.onForgotPassword ??
                              () => context.push('/forgot-password'),
                        ),
                        const SizedBox(height: 0.25 * rem),
                        TvButton(
                          label: 'Register a new venue',
                          variant: TvButtonVariant.quiet,
                          size: TvButtonSize.sm,
                          fullWidth: true,
                          disabled: busy,
                          onSelect:
                              widget.onRegisterVenue ??
                              () => context.push('/register-venue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    _Field field,
    String label,
    String placeholder,
    IconData icon, {
    bool mask = false,
    bool autofocus = false,
  }) {
    return TvTextField(
      label: label,
      value: _entry[field],
      placeholder: placeholder,
      icon: icon,
      mask: mask,
      autofocus: autofocus,
      active: _entry.active == field,
      keyboardFocusNode: _keyboard,
      onSelect: () => _entry.focus(field),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 1.25 * rem,
        vertical: 0.5 * rem,
      ),
      decoration: BoxDecoration(
        gradient: TvColors.brand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.75 * rem,
        children: [
          const Icon(LucideIcons.tv, size: 1.25 * rem, color: Colors.white),
          Text(
            'Plodyo TV',
            style: TvText.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
