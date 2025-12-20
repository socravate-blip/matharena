/// Centralized constants for Firebase match/player state strings.
///
/// We keep Firestore payloads as strings for compatibility, but avoid
/// scattering "magic strings" across the codebase.
abstract final class MatchConstants {
  // Match status
  static const String matchWaiting = 'waiting';
  static const String matchStarting = 'starting';
  static const String matchPlaying = 'playing';
  static const String matchFinished = 'finished';

  // Player status
  static const String playerActive = 'active';
  static const String playerFinished = 'finished';
  static const String playerAbandoned = 'abandoned';
}
