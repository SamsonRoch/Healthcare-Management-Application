import 'package:flutter/material.dart';
import 'package:patient_management_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({Key? key}) : super(key: key);

  @override
  _ServerConfigScreenState createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serverAddressController = TextEditingController();
  final TextEditingController _serverPortController = TextEditingController();
  bool _isLoading = true;
  bool _testingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverAddressController.text = prefs.getString('server_address') ?? ApiService.getRecommendedServerAddress();
      _serverPortController.text = prefs.getInt('server_port')?.toString() ?? '3000';
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_address', _serverAddressController.text);
    await prefs.setInt('server_port', int.parse(_serverPortController.text));

    // Configure the API service with the new settings
    ApiService.configureServer(
      address: _serverAddressController.text,
      port: int.parse(_serverPortController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server configuration saved')),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = null;
    });

    try {
      // Configure the API service temporarily for testing
      ApiService.configureServer(
        address: _serverAddressController.text,
        port: int.parse(_serverPortController.text),
      );

      // Try to connect to the server
      final response = await ApiService.testConnection();
      
      setState(() {
        _testingConnection = false;
        _connectionStatus = 'Connection successful! Server is running.';
      });
    } catch (e) {
      setState(() {
        _testingConnection = false;
        _connectionStatus = 'Connection failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Configure the connection to your server',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'For emulators: Use 10.0.2.2 (Android) or localhost (iOS)\n'
                'For physical devices: Use your computer\'s IP address (e.g., 192.168.1.5)',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _serverAddressController,
                decoration: const InputDecoration(
                  labelText: 'Server Address',
                  hintText: 'e.g., 10.0.2.2 or 192.168.1.5',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a server address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serverPortController,
                decoration: const InputDecoration(
                  labelText: 'Server Port',
                  hintText: 'e.g., 3000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid port number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _testingConnection ? null : _testConnection,
                      child: _testingConnection
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveConfig,
                      child: const Text('Save Configuration'),
                    ),
                  ),
                ],
              ),
              if (_connectionStatus != null) ...[  
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _connectionStatus!.contains('successful')
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _connectionStatus!,
                    style: TextStyle(
                      color: _connectionStatus!.contains('successful')
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverAddressController.dispose();
    _serverPortController.dispose();
    super.dispose();
  }
}