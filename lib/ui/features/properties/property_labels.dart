import '../../../core/widgets/status_badge.dart';
import '../../../data/models/property_model.dart';

const propertyStatusLabels = {'ACTIVE': 'Active', 'SUSPENDED': 'Suspended'};

/// How a property's state reads on screen.
extension PropertyLabels on PropertyModel {
  String get statusLabel => propertyStatusLabels[status] ?? status;

  BadgeTone get statusTone =>
      isActive ? BadgeTone.positive : BadgeTone.negative;

  /// "City, Country", or empty when neither is set.
  String get place => [
    city,
    country,
  ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
}
