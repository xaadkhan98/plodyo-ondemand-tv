import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/legal.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/widgets/legal_qr.dart';
import '../../../../core/widgets/page_title.dart';
import '../device_controller.dart';
import '../widgets/guest_page.dart';

/// Terms & Privacy in the guest rail: the notice's code, address and date, to read on a phone at any time.
class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final effectiveDate = DeviceScope.of(context).config?.termsEffectiveDate;

    return GuestPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TvInsets.safeX,
          0,
          TvInsets.safeX,
          TvInsets.safeY,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageTitle(
              icon: LucideIcons.scrollText,
              title: 'Terms & Privacy',
              subtitle:
                  'Scan the code or visit $legalAddress to read the Plodyo Terms of Service.',
            ),
            const SizedBox(height: 1.5 * rem),
            Center(child: LegalQr(effectiveDate: effectiveDate)),
          ],
        ),
      ),
    );
  }
}
