import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native Android Picture-in-Picture (PiP) and Background Play.
class PipService with ChangeNotifier {
  PipService._();
  static final PipService instance = PipService._();

  static const MethodChannel _channel = MethodChannel('com.tubetune.app/pip');

  final Set<Function(bool)> _pipModeListeners = {};
  final Set<VoidCallback> _screenOffListeners = {};
  final Set<VoidCallback> _screenOnListeners = {};
  final Set<Function(bool)> _pipPlayPauseListeners = {};
  final Set<VoidCallback> _pipNextListeners = {};
  final Set<VoidCallback> _pipPrevListeners = {};

  bool _isPipActive = false;
  bool get isInPip => _isPipActive;

  void addPipModeListener(Function(bool) listener) => _pipModeListeners.add(listener);
  void removePipModeListener(Function(bool) listener) => _pipModeListeners.remove(listener);

  void addScreenOffListener(VoidCallback listener) => _screenOffListeners.add(listener);
  void removeScreenOffListener(VoidCallback listener) => _screenOffListeners.remove(listener);

  void addScreenOnListener(VoidCallback listener) => _screenOnListeners.add(listener);
  void removeScreenOnListener(VoidCallback listener) => _screenOnListeners.remove(listener);

  void addPipPlayPauseListener(Function(bool) listener) => _pipPlayPauseListeners.add(listener);
  void removePipPlayPauseListener(Function(bool) listener) => _pipPlayPauseListeners.remove(listener);

  void addPipNextListener(VoidCallback listener) => _pipNextListeners.add(listener);
  void removePipNextListener(VoidCallback listener) => _pipNextListeners.remove(listener);

  void addPipPrevListener(VoidCallback listener) => _pipPrevListeners.add(listener);
  void removePipPrevListener(VoidCallback listener) => _pipPrevListeners.remove(listener);

  set onPipModeChanged(Function(bool isInPip)? cb) {
    if (cb != null) _pipModeListeners.add(cb);
  }
  set onScreenOff(VoidCallback? cb) {
    if (cb != null) _screenOffListeners.add(cb);
  }
  set onScreenOn(VoidCallback? cb) {
    if (cb != null) _screenOnListeners.add(cb);
  }
  set onPipPlayPause(Function(bool isPlaying)? cb) {
    if (cb != null) _pipPlayPauseListeners.add(cb);
  }
  set onPipNext(VoidCallback? cb) {
    if (cb != null) _pipNextListeners.add(cb);
  }
  set onPipPrev(VoidCallback? cb) {
    if (cb != null) _pipPrevListeners.add(cb);
  }

  void init() {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final bool inPip = call.arguments as bool? ?? false;
        _isPipActive = inPip;
        for (final l in _pipModeListeners.toList()) {
          l(inPip);
        }
        notifyListeners();
      } else if (call.method == 'onScreenOff') {
        for (final l in _screenOffListeners.toList()) {
          l();
        }
      } else if (call.method == 'onScreenOn') {
        for (final l in _screenOnListeners.toList()) {
          l();
        }
      } else if (call.method == 'onPipPlayPause') {
        final bool isPlaying = call.arguments as bool? ?? false;
        for (final l in _pipPlayPauseListeners.toList()) {
          l(isPlaying);
        }
      } else if (call.method == 'onPipNext') {
        for (final l in _pipNextListeners.toList()) {
          l();
        }
      } else if (call.method == 'onPipPrev') {
        for (final l in _pipPrevListeners.toList()) {
          l();
        }
      }
    });
  }

  /// Enable or disable background Picture-in-Picture mode
  Future<void> setPipEnabled(bool enabled) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setPipEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  /// Inform native layer whether a video is actively playing
  Future<void> setVideoPlaying(bool playing) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setVideoPlaying', {'playing': playing});
    } catch (_) {}
  }

  /// Check if activity is currently in Picture-in-Picture mode
  Future<bool> isPipActive() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('isPipActive');
      _isPipActive = result ?? false;
      return _isPipActive;
    } catch (_) {
      return false;
    }
  }

  /// Check if device is locked (Keyguard) or screen is powered off
  Future<bool> isDeviceLockedOrScreenOff() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isDeviceLockedOrScreenOff');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Explicitly enter PiP floating window
  Future<bool> enterPip() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
