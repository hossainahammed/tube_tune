import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Modal dialog for picking a custom watch duration (Hours and Minutes).
class CustomTimerDialog extends StatefulWidget {
  final int initialMinutes;

  const CustomTimerDialog({super.key, required this.initialMinutes});

  @override
  State<CustomTimerDialog> createState() => _CustomTimerDialogState();
}

class _CustomTimerDialogState extends State<CustomTimerDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialMinutes ~/ 60;
    _minutes = widget.initialMinutes % 60;
    if (_hours == 0 && _minutes == 0) {
      _minutes = 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (_hours * 60) + _minutes;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.hourglass_bottom_rounded, color: AppColors.accentAmber),
          SizedBox(width: 10),
          Text('Set Custom Watch Limit', style: TextStyle(fontSize: 17, color: AppColors.textPrimary)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose exact watch duration limit before the app auto-locks:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Pickers Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              _buildNumberColumn(
                label: 'Hours',
                value: _hours,
                max: 12,
                onChanged: (val) => setState(() => _hours = val),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              // Minutes
              _buildNumberColumn(
                label: 'Minutes',
                value: _minutes,
                max: 59,
                step: 5,
                onChanged: (val) => setState(() => _minutes = val),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Summary Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.youtubeRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total Limit: $totalMinutes Minutes (${_hours > 0 ? '$_hours hr ' : ''}$_minutes min)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.youtubeRedLight,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: totalMinutes > 0 ? () => Navigator.of(context).pop(totalMinutes) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.youtubeRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Set Limit'),
        ),
      ],
    );
  }

  Widget _buildNumberColumn({
    required String label,
    required int value,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: AppColors.textPrimary),
          onPressed: () {
            final next = (value + step).clamp(0, max);
            onChanged(next);
          },
        ),
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
          onPressed: () {
            final prev = (value - step).clamp(0, max);
            onChanged(prev);
          },
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
