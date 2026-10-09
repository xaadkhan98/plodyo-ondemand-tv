import '../../../core/widgets/choice_group.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/partner_model.dart';

/// How a partner's states and settings read on screen; copy matches the reference word for word.
extension PartnerLabels on PartnerModel {
  String get statusLabel => partnerStatusLabels[status] ?? status;

  BadgeTone get statusTone => switch (status) {
    'PENDING_APPROVAL' => BadgeTone.pending,
    'ACTIVE' => BadgeTone.positive,
    _ => BadgeTone.negative,
  };

  String get typeLabel => partnerTypeLabels[partnerType] ?? partnerType;

  /// e.g. "Tier 1 — The whole library, with no cap."
  String get tierDescription =>
      '${contentTierLabels[contentTier] ?? contentTier} — ${contentTierSummaries[contentTier] ?? ''}';
}

const partnerStatusLabels = {
  'PENDING_APPROVAL': 'Pending approval',
  'ACTIVE': 'Active',
  'SUSPENDED': 'Suspended',
  'REJECTED': 'Rejected',
};

const partnerTypeLabels = {
  'CHAIN': 'Chain',
  'INDEPENDENT': 'Independent',
  'HOST': 'Host',
};

const contentTierLabels = {
  'TIER_1': 'Tier 1',
  'TIER_2': 'Tier 2',
  'TIER_3': 'Tier 3',
};

const contentTierSummaries = {
  'TIER_1': 'The whole library, with no cap.',
  'TIER_2': '1,000 stories, 25 entertainment series, 25 learning series.',
  'TIER_3': '500 stories, 10 entertainment series, 10 learning series.',
};

/// Content tier choices for the partner form.
final contentTierChoices = [
  for (final tier in contentTierLabels.keys)
    Choice(
      value: tier,
      label: contentTierLabels[tier]!,
      description: contentTierSummaries[tier],
    ),
];
