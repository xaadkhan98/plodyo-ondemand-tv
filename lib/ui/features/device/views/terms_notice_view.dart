import 'package:flutter/material.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/legal_qr.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/device_models.dart';
import '../widgets/language_menu.dart';

/// What a guest sees before any content: on every cold start, and after the TV has sat idle four hours.
class TermsNoticeView extends StatefulWidget {
  const TermsNoticeView({
    super.key,
    required this.notice,
    required this.onShown,
    required this.onContinue,
  });

  /// In the guest's pick, else the room's language, from /device/config.
  final TermsNotice notice;
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
    final notice = widget.notice;

    return Scaffold(
      body: Directionality(
        textDirection: notice.direction,
        child: Padding(
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
                      notice.notice,
                      locale: notice.textLocale,
                      textAlign: TextAlign.center,
                      style: text.copyWith(color: TvColors.foreground),
                    ),
                  ),
                  const SizedBox(height: 1.25 * rem),
                  LegalQr(dateLine: notice.dateLine),
                  const SizedBox(height: 1.5 * rem),
                  // Beside Continue, a guest can read it in another language; the pick carries on into the catalogue.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 1 * rem,
                    runSpacing: 1 * rem,
                    children: [
                      const LanguageMenu(),
                      // Focused from the first frame, so OK on the remote is all it takes.
                      TvButton(
                        label: notice.continueLabel,
                        onSelect: widget.onContinue,
                        autofocus: true,
                      ),
                    ],
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
