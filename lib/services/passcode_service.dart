import 'package:flutter/material.dart';
import 'package:firegloss/services/settings_service.dart';

class PasscodeService {
  static Future<bool> showPasscodeDialog(BuildContext context) async {
    String enteredPasscode = '';

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text('Enter Passcode'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('This area contains sensitive information.'),
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Passcode',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                        onChanged: (value) {
                          enteredPasscode = value;
                        },
                        autofocus: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final isValid = await _verifyPasscode(enteredPasscode);
                        if (isValid) {
                          Navigator.of(context).pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid passcode'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Unlock'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  static Future<bool> _verifyPasscode(String passcode) async {
    final storedPasscode = await SettingsService.getPasscode();
    return passcode == storedPasscode;
  }
}
