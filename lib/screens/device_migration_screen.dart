import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';

class DeviceMigrationScreen extends StatefulWidget {
  final String newDeviceId;
  final String baseUrl;
  const DeviceMigrationScreen({super.key, required this.newDeviceId, required this.baseUrl});
  @override
  State<DeviceMigrationScreen> createState() => _DeviceMigrationScreenState();
}

class _DeviceMigrationScreenState extends State<DeviceMigrationScreen> {
  final _phoneController = TextEditingController();
  final _oldIdController = TextEditingController();
  bool _loading = false;
  String? _error;

  // Auto-clean: removes spaces, dashes, and makes lowercase
  String _cleanId(String input) => input.toLowerCase().replaceAll(RegExp(r'[^a-f0-9]'), '');

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() => _oldIdController.text = _cleanId(data.text!));
    }
  }

  Future<void> _verifyAndMigrate() async {
    final phone = _phoneController.text.trim();
    final oldId = _cleanId(_oldIdController.text);

    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your Phone Number.');
      return;
    }
    // CHANGED: Now requires only 4 characters
    if (oldId.length < 4) {
      setState(() => _error = 'Please enter at least the last 4 characters of your Old Device ID.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final base = widget.baseUrl.endsWith('/') ? widget.baseUrl : '${widget.baseUrl}/';
      final resp = await http.post(
        Uri.parse('${base}verify_migration.php'),
        body: {
          'phone': phone,
          'old_device_suffix': oldId,
          'new_device_id': widget.newDeviceId,
        },
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(resp.body);
      
      if (resp.statusCode == 200) {
        // 🎉 SUCCESS: Show a green SnackBar and wait a moment
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Device linked successfully! Loading...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Wait 1.5 seconds so the user can read the message
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Close the screen and return true to trigger the reload
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() => _error = data['error'] ?? 'Verification failed.');
      }
    } catch (e) {
      debugPrint('Network Exception: $e');
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
	  backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Link This Device')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.security, size: 72, color: AppTheme.pink),
            const SizedBox(height: 16),
            Text(
              'To prevent account theft, please enter your Phone Number and the LAST 4 characters of your Old Device ID.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.white, fontSize: 16),
            ),
            const SizedBox(height: 28),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Registered Mobile Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _oldIdController,
              style: const TextStyle(fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.bold, color: AppTheme.gold),
              maxLength: 4, // Restrict to 4 characters for easy typing
              decoration: InputDecoration(
                labelText: 'Last 4 chars of Old Device ID',
                hintText: 'e.g. d40e',
                border: const OutlineInputBorder(),
                helperText: 'Find this in your old app: Menu -> Help',
                counterText: "", // Hides the "0/4" counter at bottom
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, size: 28),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Tap to Paste full ID',
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppTheme.pink, fontWeight: FontWeight.bold)),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyAndMigrate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Link Device'),
            ),
          ],
        ),
      ),
    );
  }
}