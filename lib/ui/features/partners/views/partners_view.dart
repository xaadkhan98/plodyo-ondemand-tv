import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_scale.dart';
import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../partner_labels.dart';

/// Partner list and approval queue, scoped by the API. A row opens the partner's own screen rather than a
/// side panel: at ten feet, a panel narrow enough to sit beside the list is too narrow to read.
class PartnersView extends StatefulWidget {
  const PartnersView({
    super.key,
    this.partnersRepository,
    this.authRepository,
    this.onPartnerSelected,
  });

  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;

  /// Replaces opening the partner's screen, e.g. in tests.
  final ValueChanged<PartnerModel>? onPartnerSelected;

  @override
  State<PartnersView> createState() => _PartnersViewState();
}

class _PartnersViewState extends State<PartnersView> {
  // "all" is the absence of a status filter; the approval queue comes first because it is why the screen exists.
  static const _filters = [
    Choice(value: 'all', label: 'All'),
    Choice(value: 'PENDING_APPROVAL', label: 'Pending approval'),
    Choice(value: 'ACTIVE', label: 'Active'),
    Choice(value: 'SUSPENDED', label: 'Suspended'),
    Choice(value: 'REJECTED', label: 'Rejected'),
  ];

  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final PartnersRepository _partners =
      widget.partnersRepository ?? sharedPartnersRepository;
  late final _list = PagedList<PartnerModel, String>(
    filter: 'all',
    fetch: (status, page) => _partners.getPartners(
      accessToken: _auth.accessToken,
      status: status == 'all' ? null : status,
      page: page,
      pageSize: defaultPageSize,
    ),
  )..load();

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  Future<void> _open(PartnerModel partner) async {
    if (widget.onPartnerSelected != null) {
      widget.onPartnerSelected!(partner);
      return;
    }
    await context.push('/partners/details', extra: partner);
    // An approval or suspension on the partner's screen changes which filter it belongs under.
    _list.load();
  }

  Future<void> _add() async {
    final created = await context.push<PartnerModel>('/partners/add');
    if (!mounted) return;
    if (created == null) {
      _list.load();
      return;
    }
    // Straight to the new partner: its next step is inviting the first admin, which the row cannot say.
    await _open(created);
  }

  @override
  Widget build(BuildContext context) {
    // Manual onboarding is super admin only: a chain arrives with a contract, not through the public form.
    final canAdd = _auth.currentUser?.isSuperAdmin ?? false;
    return ConsolePage(
      maxWidth: 93.75 * rem,
      child: ListenableBuilder(
        listenable: _list,
        builder: (context, _) => AdminListLayout<PartnerModel, String>(
          list: _list,
          icon: LucideIcons.building2,
          title: 'Partners',
          description:
              'Venues on Plodyo TV. Approve new applications and set how many rooms each may sign in.',
          filters: _filters,
          action: canAdd
              ? TvButton(
                  label: 'Add partner',
                  icon: LucideIcons.plus,
                  size: TvButtonSize.md,
                  autofocus: true,
                  onSelect: _add,
                )
              : null,
          emptyMessage: _list.filter == 'all'
              ? 'No partners yet.'
              : 'No partners are ${partnerStatusLabels[_list.filter]!.toLowerCase()}.',
          rowBuilder: (partner) => ListRow(
            icon: LucideIcons.building2,
            title: partner.name,
            badges: [
              StatusBadge(partner.statusLabel, tone: partner.statusTone),
            ],
            meta: [
              MetaItem(partner.contactEmail, icon: LucideIcons.mail),
              MetaItem(partner.typeLabel),
              MetaItem(
                '${partner.roomLimit} rooms',
                icon: LucideIcons.doorOpen,
              ),
            ],
            onSelect: () => _open(partner),
          ),
        ),
      ),
    );
  }
}
