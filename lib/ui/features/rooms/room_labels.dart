import '../../../core/widgets/status_badge.dart';
import '../../../data/models/room_model.dart';

const roomStatusLabels = {
  'UNPROVISIONED': 'Not set up',
  'ACTIVE': 'Active',
  'REVOKED': 'Revoked',
};

/// How a room's state reads on screen.
extension RoomLabels on RoomModel {
  String get statusLabel => roomStatusLabels[status] ?? status;

  BadgeTone get statusTone => switch (status) {
    'UNPROVISIONED' => BadgeTone.pending,
    'ACTIVE' => BadgeTone.positive,
    _ => BadgeTone.negative,
  };
}
