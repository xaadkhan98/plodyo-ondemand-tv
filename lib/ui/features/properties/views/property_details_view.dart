import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/language_flag.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/two_column_grid.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../property_labels.dart';

/// One property: where it is, what it defaults to, and the lever that stops every room in it.
class PropertyDetailsView extends StatefulWidget {
  const PropertyDetailsView({
    super.key,
    required this.property,
    this.propertiesRepository,
    this.authRepository,
  });

  final PropertyModel property;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;

  @override
  State<PropertyDetailsView> createState() => _PropertyDetailsViewState();
}

class _PropertyDetailsViewState extends State<PropertyDetailsView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late PropertyModel _property = widget.property;
  bool _busy = false;
  String? _error;

  Future<void> _toggleStatus() async {
    final properties =
        widget.propertiesRepository ?? sharedPropertiesRepository;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = _property.isSuspended
          ? await properties.activateProperty(
              accessToken: _auth.accessToken,
              propertyId: _property.id,
            )
          : await properties.suspendProperty(
              accessToken: _auth.accessToken,
              propertyId: _property.id,
            );
      if (mounted) setState(() => _property = updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not complete that action.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    setState(() => _error = null);
    final saved = await context.push<PropertyModel>(
      '/properties/edit',
      extra: _property,
    );
    if (saved != null && mounted) setState(() => _property = saved);
  }

  @override
  Widget build(BuildContext context) {
    final property = _property;
    return ConsolePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvButton(
            label: 'All properties',
            icon: LucideIcons.arrowLeft,
            variant: TvButtonVariant.quiet,
            size: TvButtonSize.sm,
            onSelect: () => context.pop(),
          ),
          const SizedBox(height: rem),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: rem,
            children: [
              ScreenHeading(property.name),
              StatusBadge(property.statusLabel, tone: property.statusTone),
            ],
          ),
          const SizedBox(height: 2 * rem),
          TwoColumnGrid(
            children: [
              DetailCard.text(label: 'City', value: property.city ?? 'Not set'),
              DetailCard.text(
                label: 'Country',
                value: property.country ?? 'Not set',
              ),
              DetailCard.text(
                label: 'Timezone',
                value: property.timezone ?? 'Not set — sessions bucket by UTC',
              ),
              DetailCard(
                label: 'Default language',
                value: Row(
                  spacing: 0.625 * rem,
                  children: [
                    LanguageFlag(code: property.defaultLanguage),
                    Flexible(
                      child: Text(
                        languageLabel(property.defaultLanguage, 'Not set'),
                      ),
                    ),
                  ],
                ),
              ),
              DetailCard.text(
                label: 'Created',
                value: formatDateTime(property.createdAt),
              ),
              DetailCard.text(
                label: 'Last updated',
                value: formatDateTime(property.updatedAt ?? property.createdAt),
              ),
            ],
          ),
          if (property.isSuspended) ...[
            const SizedBox(height: 1.5 * rem),
            const StatusMessage(
              tone: StatusTone.warning,
              message:
                  'While suspended, rooms under this property stop serving content and no new room can be created.',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 1.5 * rem),
            StatusMessage(tone: StatusTone.error, message: _error!),
          ],
          const SizedBox(height: 2 * rem),
          Wrap(
            spacing: rem,
            runSpacing: rem,
            children: [
              TvButton(
                label: 'Edit details',
                icon: LucideIcons.pencil,
                variant: TvButtonVariant.outline,
                autofocus: true,
                disabled: _busy,
                onSelect: _edit,
              ),
              if (_auth.currentUser?.canAdminister ?? false)
                TvButton(
                  label: property.isSuspended
                      ? 'Reactivate property'
                      : 'Suspend property',
                  icon: property.isSuspended
                      ? LucideIcons.power
                      : LucideIcons.powerOff,
                  variant: property.isSuspended
                      ? TvButtonVariant.primary
                      : TvButtonVariant.danger,
                  busy: _busy,
                  busyLabel: 'Saving…',
                  onSelect: _toggleStatus,
                ),
            ],
          ),
          const SizedBox(height: 2.5 * rem),
        ],
      ),
    );
  }
}
