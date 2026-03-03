/// [CharacterState] represents all possible states a character can be in.
///
/// Every subclass of [BaseCharacterComponent] must provide a
/// [SpriteAnimation] for each of these states.
enum CharacterState {
  /// Standing still, no action in progress.
  idle,

  /// Actively walking or running.
  moving,

  /// Performing a basic attack.
  attacking,

  /// Reacting to incoming damage (hurt frame).
  hit,

  /// Playing the death animation (not yet removed).
  dying,

  /// Fully dead — no further transitions allowed.
  dead,

  /// Performing a short invincible dash.
  dashing,

  /// Temporarily unable to act (e.g. crowd-control effect).
  stunned,
}

/// [Direction] represents 8-directional and stationary facing.
///
/// Used by [BaseCharacterComponent] to determine sprite flipping and
/// movement vectors.
enum Direction {
  /// Cardinal and inter-cardinal directions.
  up,
  upRight,
  right,
  downRight,
  down,
  downLeft,
  left,
  upLeft,

  /// No direction — the character is stationary.
  none;

  /// Returns `true` when this direction faces left (for sprite flipping).
  bool get isLeft => this == left || this == upLeft || this == downLeft;

  /// Returns `true` when this direction faces right.
  bool get isRight => this == right || this == upRight || this == downRight;

  /// Determines the [Direction] that best matches the given velocity
  /// components [dx] and [dy].
  ///
  /// Flame's y-axis convention: negative = up, positive = down.
  static Direction fromVector(double dx, double dy) {
    if (dx == 0 && dy == 0) return Direction.none;

    if (dx > 0 && dy < 0) return Direction.upRight;
    if (dx < 0 && dy < 0) return Direction.upLeft;
    if (dx > 0 && dy > 0) return Direction.downRight;
    if (dx < 0 && dy > 0) return Direction.downLeft;
    if (dx > 0) return Direction.right;
    if (dx < 0) return Direction.left;
    if (dy < 0) return Direction.up;
    return Direction.down;
  }
}
