import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for directly dispatching user feedback and recommendations to developer inbox.
class FeedbackService {
  FeedbackService._();

  static const String developerEmail = 'hossainahammed627@gmail.com';
  static const String _endpoint = 'https://formsubmit.co/ajax/$developerEmail';

  /// Sends recommendation/feedback directly to developer's email inbox without requiring an external email app.
  static Future<bool> sendFeedback({
    required String message,
    String? senderName,
    String? senderEmail,
    String? category,
  }) async {
    try {
      final payload = {
        'name': (senderName != null && senderName.trim().isNotEmpty)
            ? senderName.trim()
            : 'TubeTune User',
        'email': (senderEmail != null && senderEmail.trim().isNotEmpty)
            ? senderEmail.trim()
            : 'noreply@tubetune.app',
        '_subject': 'TubeTune [${category ?? 'Recommendation'}]: New User Message',
        'message': message.trim(),
        'category': category ?? 'Feature Recommendation',
        'platform': kIsWeb ? 'Web Browser' : defaultTargetPlatform.name,
        'app_version': 'TubeTune 1.0.0',
        'submitted_at': DateTime.now().toLocal().toString(),
        '_captcha': 'false',
        '_template': 'table',
      };

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('FeedbackService direct send error: $e');
      return false;
    }
  }
}
