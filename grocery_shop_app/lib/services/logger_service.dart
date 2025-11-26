import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'session_service.dart';

class LoggerService {
  static const _serverUrl = "http://10.0.2.2:6969/log";

  static Future<void> addImpression({
    required String eventType,
    required String productId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final sessionId = await SessionService.getSessionId();

    final logData = {
      "event": eventType,
      "product_id": productId,
      "user_id": userId,
      "session_id": sessionId,
      "timestamp": DateTime.now().toIso8601String()
    };

    try {
      await http.post(
        Uri.parse(_serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(logData),
      );
    } catch (e) {
      print("❌ Error sending log to Python server: $e");
    }
  }
}
