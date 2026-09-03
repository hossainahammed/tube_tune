import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native Android Picture-in-Picture (PiP) and Background Play.
class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const MethodChannel _channel = MethodChannel('com.tubetune.app/pip');

  Function(bool isInPip)? onPipModeChanged;
  void Function()? onScreenOff;
  void Function()? onScreenOn;
  void Function(bool isPlaying)? onPipPlayPause;
  void Function()? onPipNext;
  void Function()? onPipPrev;
  bool _isPipActive = false;
  bool get isInPip => _isPipActive;

  void init() {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final bool inPip = call.arguments as bool? ?? false;
        _isPipActive = inPip;
        onPipModeChanged?.call(inPip);
      } else if (call.method == 'onScreenOff') {
        onScreenOff?.call();
      } else if (call.method == 'onScreenOn') {
        onScreenOn?.call();
      } else if (call.method == 'onPipPlayPause') {
        final bool isPlaying = call.arguments as bool? ?? false;
        onPipPlayPause?.call(isPlaying);
      } else if (call.method == 'onPipNext') {
        onPipNext?.call();
      } else if (call.method == 'onPipPrev') {
        onPipPrev?.call();
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
