import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Modal dialog for PIN entry and verification (Parental/Master Control)
class PinDialog extends StatefulWidget {
  final String title;
  final String description;
  final String? expectedPin;
  final bool isSettingNewPin;

  const PinDialog({
    super.key,
    required this.title,
    this.description = 'Enter your 4-digit security PIN',
    this.expectedPin,
    this.isSettingNewPin = false,
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorMessage;

  void _verifyOrSubmit() {
    final enteredPin = _pinController.text.trim();
    if (enteredPin.length < 4) {
      setState(() => _errorMessage = 'Please enter a 4-digit PIN');
      return;
    }

    if (widget.isSettingNewPin) {
      Navigator.of(context).pop(enteredPin);
      return;
    }

    if (widget.expectedPin != null && widget.expectedPin!.isNotEmpty) {
      if (enteredPin == widget.expectedPin) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _errorMessage = 'Incorrect PIN. Try again.');
      }
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.youtubeRed),
          const SizedBox(width: 10),
          Text(widget.title, style: const TextStyle(fontSize: 18, color: AppColors.textPrimary)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.youtubeRed, width: 2),
              ),
            ),
            onSubmitted: (_) => _verifyOrSubmit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _verifyOrSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.youtubeRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(widget.isSettingNewPin ? 'Save PIN' : 'Unlock'),
        ),
      ],
    );
  }
}
