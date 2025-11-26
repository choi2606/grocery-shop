import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  static const _key = "session_id";

  static Future<String> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString(_key);

    if (sessionId == null) {
      sessionId = const Uuid().v4();
      await prefs.setString(_key, sessionId);
    }

    return sessionId;
  }
}
