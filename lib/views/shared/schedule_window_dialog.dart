import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/timer_model.dart';

/// Dialog for adding or editing an allowed Daily Usage Schedule Window.
class ScheduleWindowDialog extends StatefulWidget {
  final ScheduleWindow? initialWindow;

  const ScheduleWindowDialog({super.key, this.initialWindow});

  @override
  State<ScheduleWindowDialog> createState() => _ScheduleWindowDialogState();
}

class _ScheduleWindowDialogState extends State<ScheduleWindowDialog> {
  late TextEditingController _nameController;
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;

  @override
  void initState() {
    super.initState();
    final win = widget.initialWindow;
    _nameController = TextEditingController(text: win?.name ?? 'Daily Window');
    _startHour = win?.startHour ?? 16;
    _startMinute = win?.startMinute ?? 0;
    _endHour = win?.endHour ?? 20;
    _endMinute = win?.endMinute ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _startHour, minute: _startMinute),
    );
    if (picked != null) {
      setState(() {
        _startHour = picked.hour;
        _startMinute = picked.minute;
      });
    }
  }

  void _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _endHour, minute: _endMinute),
    );
    if (picked != null) {
      setState(() {
        _endHour = picked.hour;
        _endMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final startTimeFormatted = TimeOfDay(hour: _startHour, minute: _startMinute).format(context);
    final endTimeFormatted = TimeOfDay(hour: _endHour, minute: _endMinute).format(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.more_time_rounded, color: AppColors.accentCyan),
          const SizedBox(width: 10),
          Text(
            widget.initialWindow != null ? 'Edit Schedule Window' : 'Add Schedule Window',
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Window Label / Name:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Afternoon Study, Evening Free',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Allowed Time Range:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickStartTime,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined, size: 14, color: AppColors.accentAmber),
                            SizedBox(width: 4),
                            Text('START TIME', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(startTimeFormatted, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _pickEndTime,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.nights_stay_outlined, size: 14, color: AppColors.accentCyan),
                            SizedBox(width: 4),
                            Text('END TIME', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(endTimeFormatted, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.accentCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'YouTube will only be accessible between $startTimeFormatted and $endTimeFormatted during this window.',
                    style: const TextStyle(fontSize: 11, color: AppColors.accentCyan),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final window = ScheduleWindow(
              id: widget.initialWindow?.id ?? 'win_${DateTime.now().millisecondsSinceEpoch}',
              name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Allowed Window',
              startHour: _startHour,
              startMinute: _startMinute,
              endHour: _endHour,
              endMinute: _endMinute,
              isEnabled: widget.initialWindow?.isEnabled ?? true,
            );
            Navigator.of(context).pop(window);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.youtubeRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(widget.initialWindow != null ? 'Save Changes' : 'Add Window'),
        ),
      ],
    );
  }
}
