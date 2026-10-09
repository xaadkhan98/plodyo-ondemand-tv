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
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../property_labels.dart';

/// The properties in the signed-in account's scope; scoping is the API's job, so a property admin sees one row.
/// The list payload carries no partner name, so a super admin's list resolves the names separately.
class PropertiesView extends StatefulWidget {
  const PropertiesView({
    super.key,
    this.propertiesRepository,
    this.partnersRepository,
    this.authRepository,
  });

  final PropertiesRepository? propertiesRepository;
  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;

  @override
  State<PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<PropertiesView> {
  static const _filters = [
    Choice(value: 'all', label: 'All'),
    Choice(value: 'ACTIVE', label: 'Active'),
    Choice(value: 'SUSPENDED', label: 'Suspended'),
  ];

  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final PropertiesRepository _properties =
      widget.propertiesRepository ?? sharedPropertiesRepository;

  // Only a super admin sees rows from more than one partner, so only they need names and the partner filter.
  late final bool _spansPartners = _auth.currentUser?.partnerId == null;
  List<PartnerModel> _partners = const [];
  String _partnerId = 'all';

  late final _list = PagedList<PropertyModel, String>(
    filter: 'all',
    fetch: (status, page) => _properties.getProperties(
      accessToken: _auth.accessToken,
      status: status == 'all' ? null : status,
      partnerId: _partnerId == 'all' ? null : _partnerId,
      page: page,
      pageSize: defaultPageSize,
    ),
  )..load();

  @override
  void initState() {
    super.initState();
    if (_spansPartners) _loadPartners();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    try {
      final page = await (widget.partnersRepository ?? sharedPartnersRepository)
          .getPartners(
            accessToken: _auth.accessToken,
            pageSize: pickerPageSize,
          );
      if (mounted) setState(() => _partners = page.data);
    } catch (_) {
      // Names are a convenience here: without them the rows still show and the partner filter hides.
    }
  }

  void _changePartner(String id) {
    setState(() => _partnerId = id);
    // Re-applying the status filter resets to page 1 and reloads under the new partner.
    _list.setFilter(_list.filter);
  }

  Future<void> _open(PropertyModel property) async {
    await context.push('/properties/details', extra: property);
    _list.load();
  }

  Future<void> _add() async {
    final created = await context.push<PropertyModel>('/properties/add');
    if (created != null) _list.load();
  }

  @override
  Widget build(BuildContext context) {
    final names = {for (final partner in _partners) partner.id: partner.name};
    return ConsolePage(
      maxWidth: 93.75 * rem,
      child: ListenableBuilder(
        listenable: _list,
        builder: (context, _) => AdminListLayout<PropertyModel, String>(
          list: _list,
          icon: LucideIcons.landmark,
          title: 'Properties',
          description:
              'The buildings and sites rooms are created under. Suspending one stops every room in it.',
          filters: _filters,
          action: (_auth.currentUser?.canAdminister ?? false)
              ? TvButton(
                  label: 'Add property',
                  icon: LucideIcons.plus,
                  size: TvButtonSize.md,
                  autofocus: true,
                  onSelect: _add,
                )
              : null,
          secondaryFilter: _spansPartners && _partners.isNotEmpty
              ? ChoiceGroup<String>(
                  value: _partnerId,
                  layout: ChoiceLayout.chips,
                  onChanged: _changePartner,
                  options: [
                    const Choice(value: 'all', label: 'All partners'),
                    for (final partner in _partners)
                      Choice(value: partner.id, label: partner.name),
                  ],
                )
              : null,
          emptyMessage: _list.filter == 'all'
              ? 'No properties yet.'
              : 'No properties are ${propertyStatusLabels[_list.filter]!.toLowerCase()}.',
          rowBuilder: (property) => ListRow(
            icon: LucideIcons.landmark,
            title: property.name,
            badges: [
              StatusBadge(property.statusLabel, tone: property.statusTone),
            ],
            meta: [
              if (_spansPartners && names[property.partnerId] != null)
                MetaItem(names[property.partnerId]!),
              if (property.place.isNotEmpty)
                MetaItem(property.place, icon: LucideIcons.mapPin),
              if (property.timezone case final timezone?
                  when timezone.isNotEmpty)
                MetaItem(timezone, icon: LucideIcons.globe),
            ],
            onSelect: () => _open(property),
          ),
        ),
      ),
    );
  }
}
