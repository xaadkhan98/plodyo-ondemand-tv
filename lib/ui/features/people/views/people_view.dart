import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/person_model.dart';
import '../../../../data/models/roles.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/people_repository.dart';
import '../person_labels.dart';

/// Everyone who can sign in within the account's scope. Disabling one ends its sessions everywhere at once.
class PeopleView extends StatefulWidget {
  const PeopleView({
    super.key,
    this.peopleRepository,
    this.authRepository,
    this.onPersonSelected,
  });

  final PeopleRepository? peopleRepository;
  final AuthRepository? authRepository;

  /// Replaces opening the person's screen, e.g. in tests.
  final ValueChanged<PersonModel>? onPersonSelected;

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  // Invited but never accepted is the state staff chase, so it sits early.
  static const _filters = [
    Choice(value: 'all', label: 'All'),
    Choice(value: 'ACTIVE', label: 'Active'),
    Choice(value: 'INVITED', label: 'Invited'),
    Choice(value: 'DISABLED', label: 'Disabled'),
  ];

  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final PeopleRepository _people =
      widget.peopleRepository ?? sharedPeopleRepository;
  late final _list = PagedList<PersonModel, String>(
    filter: 'all',
    fetch: (status, page) => _people.getPeople(
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

  Future<void> _open(PersonModel person) async {
    if (widget.onPersonSelected != null) {
      widget.onPersonSelected!(person);
      return;
    }
    await context.push('/people/details', extra: person);
    if (mounted) _list.load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final selfId = _auth.currentUser?.userId;
    return ConsolePage(
      maxWidth: 93.75 * rem,
      child: ListenableBuilder(
        listenable: _list,
        builder: (context, _) => AdminListLayout<PersonModel, String>(
          list: _list,
          icon: LucideIcons.users,
          title: 'People',
          description:
              'Everyone who can sign in within your scope. Disabling an account ends its sessions on every device at once.',
          filters: _filters,
          emptyMessage: _list.filter == 'all'
              ? 'No accounts yet. Invite someone to create the first.'
              : 'No accounts are ${personStatusLabels[_list.filter]!.toLowerCase()}.',
          rowBuilder: (person) {
            final roles = {
              for (final m in person.memberships) roleLabel(m.role),
            };
            return ListRow(
              icon: LucideIcons.userRound,
              title: person.fullName.isNotEmpty
                  ? person.fullName
                  : person.email,
              badges: [
                StatusBadge(person.statusLabel, tone: person.statusTone),
                if (person.id == selfId) const StatusBadge('You'),
              ],
              meta: [
                MetaItem(person.email, icon: LucideIcons.mail),
                if (roles.isNotEmpty)
                  MetaItem(roles.join(', '), icon: LucideIcons.shieldCheck),
                MetaItem(
                  person.lastLoginAt == null
                      ? 'Never signed in'
                      : 'Last in ${formatDate(person.lastLoginAt)}',
                ),
              ],
              onSelect: () => _open(person),
            );
          },
        ),
      ),
    );
  }
}
