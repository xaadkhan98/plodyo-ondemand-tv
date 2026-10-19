import 'package:flutter/material.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/legal_qr.dart';
import '../../../../core/widgets/tv_button.dart';

/// Wording from Terms of Service §8(b). Not to be edited here.
const termsNoticeText =
    'For grown-ups: by pressing Continue, you agree to the Plodyo Terms of Service. Scan the code or visit plodyo.com/tos to read it.';

/// What a guest sees before any content: on every cold start, and after the TV has sat idle four hours.
class TermsNoticeView extends StatefulWidget {
  const TermsNoticeView({
    super.key,
    required this.effectiveDate,
    required this.onShown,
    required this.onContinue,
  });

  /// The Terms' effective date, from /device/config.
  final String? effectiveDate;
  final VoidCallback onShown;
  final VoidCallback onContinue;

  @override
  State<TermsNoticeView> createState() => _TermsNoticeViewState();
}

class _TermsNoticeViewState extends State<TermsNoticeView> {
  @override
  void initState() {
    super.initState();
    widget.onShown();
  }

  @override
  Widget build(BuildContext context) {
    const text = TvText.lg;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TvInsets.safeX,
          vertical: TvInsets.safeY,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 52 * TvText.ch(text)),
                  child: Text(
                    termsNoticeText,
                    textAlign: TextAlign.center,
                    style: text.copyWith(color: TvColors.foreground),
                  ),
                ),
                const SizedBox(height: 1.25 * rem),
                LegalQr(effectiveDate: widget.effectiveDate),
                const SizedBox(height: 1.5 * rem),
                // Focused from the first frame, so OK on the remote is all it takes.
                TvButton(
                  label: 'Continue',
                  onSelect: widget.onContinue,
                  autofocus: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
