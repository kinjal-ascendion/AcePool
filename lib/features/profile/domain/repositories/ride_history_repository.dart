abstract class RideHistoryRepository {
  /// Combined driver + rider ride history, newest first. Each entry is the
  /// raw merged ride doc shape expected by `RideHistoryDetailPage` (which
  /// takes a `Map<String, dynamic>` directly, not a domain entity).
  Future<List<Map<String, dynamic>>> getHistory();
}
