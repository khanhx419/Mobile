import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer delays execution until a duration has elapsed since the last call.
/// Used in search bars and auto-save just like in Cashew architecture.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler limits execution to at most once per duration.
/// Used to prevent double-tap or redundant triggers.
class Throttler {
  final Duration delay;
  Timer? _timer;
  bool _isThrottling = false;

  Throttler({required this.delay});

  void run(VoidCallback action) {
    if (!_isThrottling) {
      action();
      _isThrottling = true;
      _timer = Timer(delay, () {
        _isThrottling = false;
      });
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
