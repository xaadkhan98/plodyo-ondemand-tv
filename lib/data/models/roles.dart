/// Display label for an API role, e.g. `PARTNER_ADMIN` → "Partner admin"; unknown roles show as sent.
String roleLabel(String role) =>
    switch (role.trim().toUpperCase().replaceAll(' ', '_')) {
      'SUPER_ADMIN' => 'Super admin',
      'PARTNER_ADMIN' => 'Partner admin',
      'PROPERTY_ADMIN' => 'Property admin',
      _ => role,
    };

/// A scope as support reads it out: ids in full, since they are what support asks for when a scope looks wrong.
String describeScope(String? partnerId, String? propertyId) {
  if (partnerId == null) return 'All partners and properties';
  if (propertyId == null) return 'Partner $partnerId';
  return 'Property $propertyId';
}
