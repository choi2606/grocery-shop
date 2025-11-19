import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Đăng nhập anonymous với error handling tốt hơn cho web
  static Future<User?> signInAnonymously() async {
    // Trên web, bỏ qua auth nếu có lỗi IndexedDB
    if (kIsWeb) {
      try {
        // Kiểm tra xem đã có user chưa (không cần delay)
        if (_auth.currentUser != null) {
          print('✓ Đã có user đăng nhập: ${_auth.currentUser?.uid}');
          return _auth.currentUser;
        }

        // Thử đăng nhập anonymous với timeout ngắn để không block
        final userCredential = await _auth.signInAnonymously().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Authentication timeout - bỏ qua');
          },
        );
        print(
            '✓ Đã đăng nhập anonymous thành công: ${userCredential.user?.uid}');
        return userCredential.user;
      } on FirebaseAuthException catch (e) {
        // Xử lý các lỗi cụ thể của Firebase Auth
        if (e.code == 'operation-not-allowed') {
          print(
              '⚠ Anonymous authentication chưa được bật trong Firebase Console');
        } else {
          print('⚠ Lỗi đăng nhập anonymous: ${e.code} - ${e.message}');
        }
        return null;
      } catch (e) {
        // Xử lý lỗi IndexedDB và các lỗi khác
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('indexeddb') ||
            errorString.contains('cannot be invoked without') ||
            errorString.contains('timeout')) {
          print(
              '⚠ Lỗi IndexedDB trên web (bỏ qua - rules có thể ở test mode): $e');
          // Trả về null nhưng không crash app
          return null;
        }
        print('⚠ Lỗi không mong đợi khi đăng nhập: $e');
        return null;
      }
    } else {
      // Trên mobile, xử lý bình thường
      try {
        if (_auth.currentUser != null) {
          print('✓ Đã có user đăng nhập: ${_auth.currentUser?.uid}');
          return _auth.currentUser;
        }

        final userCredential = await _auth.signInAnonymously();
        print(
            '✓ Đã đăng nhập anonymous thành công: ${userCredential.user?.uid}');
        return userCredential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'operation-not-allowed') {
          print(
              '⚠ Anonymous authentication chưa được bật trong Firebase Console');
        } else {
          print('⚠ Lỗi đăng nhập anonymous: ${e.code} - ${e.message}');
        }
        return null;
      } catch (e) {
        print('⚠ Lỗi không mong đợi khi đăng nhập: $e');
        return null;
      }
    }
  }

  /// Kiểm tra xem user đã đăng nhập chưa
  static User? get currentUser => _auth.currentUser;

  /// Kiểm tra xem có user đã đăng nhập không
  static bool get isAuthenticated => _auth.currentUser != null;

  /// Đăng xuất
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✓ Đã đăng xuất thành công');
    } catch (e) {
      print('✗ Lỗi khi đăng xuất: $e');
    }
  }
}
