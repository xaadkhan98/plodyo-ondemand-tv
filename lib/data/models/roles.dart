/// Display label for an API role, e.g. `PARTNER_ADMIN` → "Partner admin"; unknown roles show as sent.
String roleLabel(String role) =>
    switch (role.trim().toUpperCase().replaceAll(' ', '_')) {
      'SUPER_ADMIN' => 'Super admin',
      'PARTNER_ADMIN' => 'Partner admin',
      'PROPERTY_ADMIN' => 'Property admin',
      _ => role,
    };
