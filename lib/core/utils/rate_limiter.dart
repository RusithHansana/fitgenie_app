import 'dart:async';

/// Simple in-memory rate limiter for sequential request throttling.
///
/// Ensures no more than [maxRequests] are executed within the [window].
/// Calls are serialized to avoid races and to enforce ordering.
class RateLimiter {
  RateLimiter({required this.maxRequests, required this.window});

  /// Maximum number of allowed requests per window.
  final int maxRequests;

  /// Sliding time window for the limit.
  final Duration window;

  final List<DateTime> _timestamps = [];
  Future<void> _queue = Future.value();

  /// Waits until a request slot is available.
  Future<void> acquire() {
    _queue = _queue.then((_) => _acquireInternal());
    return _queue;
  }

  Future<void> _acquireInternal() async {
    while (true) {
      final now = DateTime.now();
      _timestamps.removeWhere((t) => now.difference(t) >= window);

      if (_timestamps.length < maxRequests) {
        _timestamps.add(now);
        return;
      }

      final earliest = _timestamps.first;
      final wait = window - now.difference(earliest);
      if (wait.isNegative) {
        continue;
      }

      await Future.delayed(wait);
    }
  }
}
