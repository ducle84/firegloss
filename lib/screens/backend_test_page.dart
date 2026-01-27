import 'package:flutter/material.dart';
import 'package:firegloss/services/backend_service.dart';

class BackendTestPage extends StatefulWidget {
  const BackendTestPage({super.key});

  @override
  State<BackendTestPage> createState() => _BackendTestPageState();
}

class _BackendTestPageState extends State<BackendTestPage> {
  String _backendStatus = 'Not tested';
  bool _isLoading = false;

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _backendStatus = 'Testing connection...';
    });

    try {
      final result = await BackendService.testFirebaseConnection();

      setState(() {
        _isLoading = false;
        _backendStatus = result['message'];
      });

      if (mounted) {
        _showResultDialog(
          result['success'] ? 'Success' : 'Error',
          result['message'],
          result['data'],
          result['success'],
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _backendStatus = 'Connection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _createTestUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await BackendService.createTestUser();

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showResultDialog(
          result['success'] ? 'User Created' : 'Error',
          result['message'],
          result['data'],
          result['success'],
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showResultDialog('Error', 'Failed: ${e.toString()}', null, false);
      }
    }
  }

  Future<void> _getAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await BackendService.getAllUsers();

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showResultDialog(
          result['success'] ? 'Users Retrieved' : 'Error',
          result['message'],
          result['data'],
          result['success'],
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showResultDialog('Error', 'Failed: ${e.toString()}', null, false);
      }
    }
  }

  void _showResultDialog(
      String title, String message, dynamic data, bool isSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (data != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Response Data:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend API Testing'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_queue,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              Text(
                'Backend API Testing',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Test the connection between Flutter and Python backend',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backend Status: $_backendStatus',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),

                      // Instructions for starting backend
                      if (_backendStatus.contains('Connection failed') ||
                          _backendStatus == 'Not tested') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Start Backend Server:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1. Open terminal in project root\n2. Run: start_backend.bat\n3. Wait for server to start\n4. Click "Test Connection"',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Backend Test Buttons
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _testBackendConnection,
                                icon: const Icon(Icons.wifi_tethering),
                                label: const Text('Test Connection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _createTestUser,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Create User'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _getAllUsers,
                            icon: const Icon(Icons.people),
                            label: const Text('Get All Users'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
