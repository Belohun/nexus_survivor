import 'dart:ui';

/// [CharacterType] identifies the available playable character variants.
///
/// Each value carries a human-readable [displayName], a [placeholderColor]
/// used by the main-menu character selector and by development placeholder
/// sprites, and a short [description] shown on the character selection page.
enum CharacterType {
  /// Ranged character that fires projectiles with [DevWeapon].
  devGunner(
    'Dev Gunner',
    Color(0xFF00BCD4),
    'A nimble ranged fighter. Keeps enemies at bay with rapid projectile fire. '
        'High speed, lower defence.',
  ),

  /// Melee character that swings a sword with [DevSwordWeapon].
  devSwordsman(
    'Dev Swordsman',
    Color(0xFFE91E63),
    'A sturdy melee brawler. Deals heavy damage up close with wide sword swings. '
        'High HP and defence, lower speed.',
  );

  const CharacterType(
    this.displayName,
    this.placeholderColor,
    this.description,
  );

  /// Human-readable label shown in the UI.
  final String displayName;

  /// Colour used for placeholder sprites and menu previews.
  final Color placeholderColor;

  /// Short description shown on the character selection page.
  final String description;
}
