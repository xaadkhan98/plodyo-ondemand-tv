import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/legal.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/widgets/legal_qr.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../data/models/device_models.dart';
import '../device_controller.dart';
import '../widgets/guest_page.dart';

/// Terms of Service in the guest rail: the notice's code, address and date, to read on a phone at any time.
class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = DeviceScope.of(context);
    final notice =
        session.config?.termsNotice(session.language) ??
        TermsNotice.english(null);
    const subtitle =
        'Scan the code or visit $legalAddress to read the Plodyo Terms of Service.';

    return GuestPage(
      child: Directionality(
        textDirection: notice.direction,
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
              PageTitle(
                icon: LucideIcons.scrollText,
                title: notice.menuItem,
                // Not on the translated list: English, isolated left to right on a right-to-left screen.
                subtitle: notice.rtl ? '\u2066$subtitle\u2069' : subtitle,
              ),
              const SizedBox(height: 1.5 * rem),
              Center(child: LegalQr(dateLine: notice.dateLine)),
            ],
          ),
        ),
      ),
    );
  }
}
