import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cast_service.dart';
import 'app_snackbar.dart';

/// Modal bottom sheet matching official YouTube "Connect to a device" interface.
class CastBottomSheet extends StatefulWidget {
  const CastBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CastBottomSheet(),
    );
  }

  @override
  State<CastBottomSheet> createState() => _CastBottomSheetState();
}

class _CastBottomSheetState extends State<CastBottomSheet> {
  final CastService _castService = CastService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_castService.isConnected && _castService.availableDevices.isEmpty) {
        _castService.startScanning();
      }
    });
  }

  void _showLinkWithTvCodeDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tv_rounded, color: AppColors.accentCyan),
            SizedBox(width: 10),
            Text(
              'Link with TV code',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open the YouTube app on your TV, go to Settings > Link with TV code, and enter the code shown on your TV screen.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 123 456 789 012',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14, letterSpacing: 0),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length >= 6) {
                Navigator.pop(dialogCtx);
                final success = await _castService.linkWithTvCode(code);
                if (mounted) {
                  if (success) {
                    Navigator.pop(context);
                    AppSnackBar.showSuccess(
                      context,
                      'Connected to YouTube TV! Screen Cast active.',
                      icon: Icons.cast_connected_rounded,
                    );
                  } else {
                    AppSnackBar.showError(context, 'Invalid TV code. Please check your TV screen.');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Link TV'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(CastDevice device) async {
    final success = await _castService.connectToDevice(device);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      AppSnackBar.showSuccess(
        context,
        'Connected to ${device.name}! Casting enabled.',
        icon: Icons.cast_connected_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _castService,
      builder: (ctx, child) {
        final isConnected = _castService.isConnected;
        final connectedDevice = _castService.connectedDevice;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isConnected ? 'Cast to TV' : 'Connect to a device',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isConnected && !_castService.isScanning)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 22),
                      tooltip: 'Refresh devices',
                      onPressed: () => _castService.startScanning(),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (isConnected && connectedDevice != null) ...[
                // Active connected state card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15263F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.4), width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4285F4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cast_connected_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connectedDevice.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Connected • Casting in 1080p Full HD',
                                  style: TextStyle(
                                    color: Color(0xFF81D4FA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Volume Slider
                      Row(
                        children: [
                          const Icon(Icons.volume_down_rounded, color: AppColors.textSecondary, size: 20),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF4285F4),
                                inactiveTrackColor: AppColors.surfaceLight,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _castService.volume,
                                onChanged: (val) => _castService.setVolume(val),
                              ),
                            ),
                          ),
                          const Icon(Icons.volume_up_rounded, color: AppColors.textSecondary, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Disconnect Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cast_rounded, size: 18),
                          label: const Text('Disconnect from TV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF8A80),
                            side: BorderSide(color: const Color(0xFFFF8A80).withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _castService.disconnect();
                            Navigator.pop(context);
                            AppSnackBar.showInfo(
                              context,
                              'Disconnected from ${connectedDevice.name}',
                              icon: Icons.cast_rounded,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (_castService.isScanning) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Searching for TVs & devices on Wi-Fi...',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // List of available devices
                  ..._castService.availableDevices.map((device) {
                    final isSmartTv = device.type == CastDeviceType.smartTv || device.type == CastDeviceType.androidTv;
                    return InkWell(
                      onTap: () => _connectToDevice(device),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSmartTv ? Icons.tv_rounded : Icons.cast_rounded,
                                color: const Color(0xFF4285F4),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    device.description,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const Divider(color: AppColors.surfaceLight, height: 24),

                // Link with TV code option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.dialpad_rounded, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    'Link with TV code',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Pair with your TV using a 12-digit code',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                  onTap: _showLinkWithTvCodeDialog,
                ),

                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.wifi_rounded, color: AppColors.textMuted, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ensure your phone and TV are connected to the same Wi-Fi.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
