import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  static const String _settingsCollection = 'system_settings';
  static const String _settingsDocument = 'security';
  static const String _passcodeField = 'passcode';
  static const String _defaultPasscode = '1234';

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Get the current passcode from Firebase
  static Future<String> getPasscode() async {
    try {
      final doc = await _firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .get();

      if (doc.exists && doc.data()?[_passcodeField] != null) {
        return doc.data()![_passcodeField] as String;
      } else {
        // If document doesn't exist, create it with default passcode
        await _initializePasscode();
        return _defaultPasscode;
      }
    } catch (e) {
      print('Error getting passcode: $e');
      return _defaultPasscode;
    }
  }

  // Set a new passcode in Firebase
  static Future<bool> setPasscode(String newPasscode) async {
    if (newPasscode.isEmpty || newPasscode.length < 4) {
      return false; // Minimum 4 digits required
    }

    try {
      await _firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .set({
        _passcodeField: newPasscode,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error setting passcode: $e');
      return false;
    }
  }

  // Reset passcode to default in Firebase
  static Future<bool> resetPasscode() async {
    try {
      await _firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .set({
        _passcodeField: _defaultPasscode,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error resetting passcode: $e');
      return false;
    }
  }

  // Check if passcode is set to default
  static Future<bool> isDefaultPasscode() async {
    final currentPasscode = await getPasscode();
    return currentPasscode == _defaultPasscode;
  }

  // Initialize passcode document in Firebase if it doesn't exist
  static Future<void> _initializePasscode() async {
    try {
      await _firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .set({
        _passcodeField: _defaultPasscode,
        'created': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error initializing passcode: $e');
    }
  }
}
