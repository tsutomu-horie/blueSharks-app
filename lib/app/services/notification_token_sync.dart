import 'dart:async';

enum NotificationSyncOutcome { synced, deferred, cancelled }

class _Cancelled implements Exception {}

/// One app-owned worker, shared by startup/login/registration. No listeners,
/// credentials, recursive retries, or response/exception logging live here.
class NotificationTokenSync {
  NotificationTokenSync({
    required this.currentSession,
    required this.readToken,
    required this.sendToken,
    this.cacheToken,
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.stepTimeout = const Duration(seconds: 5),
  });

  final int Function() currentSession;
  final Future<String?> Function() readToken;
  final Future<bool> Function(
      String token, int session, bool Function() isActive) sendToken;
  final Future<void> Function(String token)? cacheToken;
  final int maxAttempts;
  final Duration retryDelay;
  final Duration stepTimeout;
  Future<NotificationSyncOutcome>? _running;
  int? _runningSession;
  int? _attemptSession;
  final _attempts = <String, NotificationSyncOutcome>{};
  Completer<void>? _cancelSignal;
  int _generation = 0;
  bool _disposed = false;

  void cancel() {
    _generation++;
    final signal = _cancelSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
    _running = null;
    _runningSession = null;
  }

  void dispose() {
    _disposed = true;
    cancel();
    _attempts.clear();
  }

  Future<NotificationSyncOutcome> sync() {
    if (_disposed) return Future.value(NotificationSyncOutcome.cancelled);
    final session = currentSession();
    if (_running != null && _runningSession == session) return _running!;
    cancel();
    if (_attemptSession != session) {
      _attempts.clear();
      _attemptSession = session;
    }
    final generation = _generation;
    final signal = Completer<void>();
    _cancelSignal = signal;
    _runningSession = session;
    return _running = _run(session, generation, signal).whenComplete(() {
      if (_generation == generation) {
        _running = null;
        _runningSession = null;
      }
    });
  }

  bool _active(int session, int generation) =>
      !_disposed && _generation == generation && currentSession() == session;

  Future<T> _step<T>(Future<T> work, Completer<void> signal) {
    final result = Completer<T>();
    late Timer timer;
    void fail(Object error, [StackTrace? stack]) {
      if (result.isCompleted) return;
      timer.cancel();
      result.completeError(error, stack);
    }

    timer = Timer(stepTimeout, () => fail(TimeoutException('Step deadline')));
    work.then((value) {
      if (result.isCompleted) return;
      timer.cancel();
      result.complete(value);
    }, onError: (Object error, StackTrace stack) => fail(error, stack));
    signal.future.then((_) => fail(_Cancelled()));
    return result.future;
  }

  Future<NotificationSyncOutcome> _run(
      int session, int generation, Completer<void> signal) async {
    var leaseOpen = true;
    bool active() => leaseOpen && _active(session, generation);
    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (!active()) {
          return NotificationSyncOutcome.cancelled;
        }
        String? token;
        try {
          token = await _step(readToken(), signal);
        } on TimeoutException {
          rethrow;
        } on _Cancelled {
          rethrow;
        } catch (_) {
          // Native token acquisition can fail before APNs is ready.
          // Retry only after that attempt has actually settled.
        }
        if (!active()) {
          return NotificationSyncOutcome.cancelled;
        }
        if (token != null && token.trim().isNotEmpty) {
          final cache = cacheToken;
          if (cache != null) await _step(cache(token), signal);
          if (!active()) {
            return NotificationSyncOutcome.cancelled;
          }
          final previous = _attempts[token];
          if (previous != null) return previous;
          // Mark before sending: a timed-out native/HTTP operation cannot be
          // physically cancelled. Never launch a duplicate send for this pair.
          _attempts[token] = NotificationSyncOutcome.deferred;
          final sent =
              await _step(sendToken(token, session, () => active()), signal);
          if (!active()) {
            return NotificationSyncOutcome.cancelled;
          }
          if (sent) {
            _attempts[token] = NotificationSyncOutcome.synced;
            return NotificationSyncOutcome.synced;
          }
          // Only a settled failure is retried. A timeout keeps the marker,
          // because the original operation may still be in flight.
          _attempts.remove(token);
        }
        if (attempt + 1 < maxAttempts) {
          await _step(Future<void>.delayed(retryDelay), signal);
        }
      }
      return NotificationSyncOutcome.deferred;
    } on _Cancelled {
      return NotificationSyncOutcome.cancelled;
    } catch (_) {
      // A stalled read/send terminates this worker; it never spawns retries
      // behind the timeout. Late completion has no continuation or side effect.
      return active()
          ? NotificationSyncOutcome.deferred
          : NotificationSyncOutcome.cancelled;
    } finally {
      leaseOpen = false;
    }
  }
}

/// Shared by worker-owned and legacy (No14) provider entrypoints. A lease closes
/// when its deadline expires, the worker cancels, or the auth session changes.
/// The operation must check canSend immediately before starting HTTP work.
class NotificationTokenRegistration<T> {
  NotificationTokenRegistration({
    required this.currentSession,
    this.deadline = const Duration(seconds: 5),
  });
  final int Function() currentSession;
  final Duration deadline;
  int? _session;
  final _attempts = <String, Future<T?>>{};

  Future<T?> send(
    String token, {
    required int expectedSession,
    required bool Function() isActive,
    required Future<T?> Function(bool Function() canSend) operation,
  }) {
    if (currentSession() != expectedSession || !isActive()) {
      return Future.value();
    }
    if (_session != expectedSession) {
      _attempts.clear();
      _session = expectedSession;
    }
    return _attempts.putIfAbsent(token, () {
      var retryable = false;
      late final Future<T?> pending;
      pending = _send(expectedSession, isActive, operation, () {
        retryable = true;
      }).then((value) {
        if (retryable && identical(_attempts[token], pending)) {
          _attempts.remove(token);
        }
        return value;
      });
      return pending;
    });
  }

  Future<T?> _send(
      int session,
      bool Function() isActive,
      Future<T?> Function(bool Function()) operation,
      void Function() onSettledFailure) async {
    var open = true;
    final watch = Stopwatch()..start();
    bool canSend() =>
        open &&
        watch.elapsed < deadline &&
        currentSession() == session &&
        isActive();
    try {
      if (!canSend()) return null;
      final result = await Future<T?>.sync(() => operation(canSend))
          .timeout(deadline, onTimeout: () => null);
      if (result == null && canSend()) onSettledFailure();
      return result;
    } catch (_) {
      if (canSend()) onSettledFailure();
      return null;
    } finally {
      open = false;
      watch.stop();
    }
  }
}
