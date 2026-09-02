import 'package:flutter/services.dart';

/// Service interfacing with native Android Picture-in-Picture (PiP) and Background Play.
class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const MethodChannel _channel = MethodChannel('com.example.tube_tune/pip');

  Function(bool isInPip)? onPipModeChanged;
  bool _isPipActive = false;
  bool get isInPip => _isPipActive;

  void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final bool inPip = call.arguments as bool? ?? false;
        _isPipActive = inPip;
        onPipModeChanged?.call(inPip);
      }
    });
  }

  /// Enable or disable background Picture-in-Picture mode
  Future<void> setPipEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setPipEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  /// Inform native layer whether a video is actively playing
  Future<void> setVideoPlaying(bool playing) async {
    try {
      await _channel.invokeMethod('setVideoPlaying', {'playing': playing});
    } catch (_) {}
  }

  /// Check if activity is currently in Picture-in-Picture mode
  Future<bool> isPipActive() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isPipActive');
      _isPipActive = result ?? false;
      return _isPipActive;
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
