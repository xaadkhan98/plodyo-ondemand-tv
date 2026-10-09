import '../../../core/widgets/status_badge.dart';
import '../../../data/models/person_model.dart';

const personStatusLabels = {
  'INVITED': 'Invited',
  'ACTIVE': 'Active',
  'DISABLED': 'Disabled',
};

/// How an account's state reads on screen.
extension PersonLabels on PersonModel {
  String get statusLabel => personStatusLabels[status.toUpperCase()] ?? status;

  BadgeTone get statusTone => isActive
      ? BadgeTone.positive
      : (isInvited ? BadgeTone.pending : BadgeTone.negative);
}
