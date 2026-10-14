import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/picker_list.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../properties/property_labels.dart';

/// Picks the active property new rooms go under, loading the choices itself. Shared by both room forms.
class PropertyPicker extends StatefulWidget {
  const PropertyPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.emptyMessage,
    required this.authRepository,
    this.propertiesRepository,
    this.disabled = false,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final String emptyMessage;
  final AuthRepository authRepository;
  final PropertiesRepository? propertiesRepository;
  final bool disabled;

  @override
  State<PropertyPicker> createState() => _PropertyPickerState();
}

class _PropertyPickerState extends State<PropertyPicker> {
  List<PropertyModel>? _properties;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page =
          await (widget.propertiesRepository ?? sharedPropertiesRepository)
              .getProperties(
                accessToken: widget.authRepository.accessToken,
                status: 'ACTIVE',
                pageSize: pickerPageSize,
              );
      if (mounted) setState(() => _properties = page.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not load properties.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PickerList(
      label: 'Property',
      icon: LucideIcons.landmark,
      value: widget.value,
      onChanged: widget.onChanged,
      loading: _properties == null && _error == null,
      error: _error,
      disabled: widget.disabled,
      emptyMessage: widget.emptyMessage,
      options: [
        for (final property in _properties ?? const <PropertyModel>[])
          PickerOption(
            id: property.id,
            label: property.name,
            hint: property.place,
          ),
      ],
    );
  }
}
