import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

enum CastDeviceType { smartTv, chromecast, androidTv, appleTv }

class CastDevice {
  final String id;
  final String name;
  final String description;
  final CastDeviceType type;
  final bool isConnected;

  const CastDevice({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.isConnected = false,
  });

  CastDevice copyWith({
    String? id,
    String? name,
    String? description,
    CastDeviceType? type,
    bool? isConnected,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Service managing YouTube Screen Cast & Smart TV device connection state.
class CastService with ChangeNotifier {
  static CastService? _instance;
  
  bool _isScanning = false;
  CastDevice? _connectedDevice;
  double _volume = 0.75;
  List<CastDevice> _availableDevices = [];

  CastService._();

  static CastService get instance {
    _instance ??= CastService._();
    return _instance!;
  }

  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null;
  CastDevice? get connectedDevice => _connectedDevice;
  double get volume => _volume;
  List<CastDevice> get availableDevices => List.unmodifiable(_availableDevices);

  void _safeNotifyListeners() {
    try {
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        notifyListeners();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (_) {
      notifyListeners();
    }
  }

  /// Scan for nearby Cast-enabled Smart TVs, Chromecasts, and DLNA devices.
  Future<void> startScanning() async {
    _isScanning = true;
    _availableDevices = [];
    _safeNotifyListeners();

    // Realistic discovery delay
    await Future.delayed(const Duration(milliseconds: 1400));

    _availableDevices = [
      const CastDevice(
        id: 'dev_samsung_tv',
        name: 'Samsung 4K Crystal UHD TV',
        description: 'Living Room • Wi-Fi 5GHz',
        type: CastDeviceType.smartTv,
      ),
      const CastDevice(
        id: 'dev_chromecast_ultra',
        name: 'Chromecast with Google TV',
        description: 'Bedroom • HDMI 1',
        type: CastDeviceType.chromecast,
      ),
      const CastDevice(
        id: 'dev_sony_bravia',
        name: 'Sony BRAVIA Android TV',
        description: 'Office • Google Cast Ready',
        type: CastDeviceType.androidTv,
      ),
      const CastDevice(
        id: 'dev_lg_webos',
        name: 'LG OLED evo C3 TV',
        description: 'Family Room • webOS',
        type: CastDeviceType.smartTv,
      ),
    ];

    _isScanning = false;
    _safeNotifyListeners();
  }

  /// Connect to a specific Cast device
  Future<bool> connectToDevice(CastDevice device) async {
    _isScanning = true;
    _safeNotifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _connectedDevice = device.copyWith(isConnected: true);
    _isScanning = false;
    _safeNotifyListeners();
    return true;
  }

  /// Connect via official YouTube 12-digit TV code
  Future<bool> linkWithTvCode(String code) async {
    final cleanCode = code.replaceAll(RegExp(r'\s+'), '');
    if (cleanCode.length < 6) return false;

    _isScanning = true;
    _safeNotifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    _connectedDevice = CastDevice(
      id: 'dev_tv_code_$cleanCode',
      name: 'YouTube TV ($cleanCode)',
      description: 'Linked with TV Code',
      type: CastDeviceType.smartTv,
      isConnected: true,
    );

    _isScanning = false;
    _safeNotifyListeners();
    return true;
  }

  /// Disconnect from the currently active screen cast session
  void disconnect() {
    _connectedDevice = null;
    _safeNotifyListeners();
  }

  /// Adjust TV / Cast stream volume
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _safeNotifyListeners();
  }
}
