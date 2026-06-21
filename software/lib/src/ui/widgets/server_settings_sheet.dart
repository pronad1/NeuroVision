// lib/src/ui/widgets/server_settings_sheet.dart
// Bottom-sheet dialog that lets the user change the AI server IP at runtime
// without rebuilding the app.  Open it from any screen via:
//   ServerSettingsSheet.show(context);

import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/server_config.dart';

class ServerSettingsSheet extends StatefulWidget {
  const ServerSettingsSheet._();

  /// Show the settings sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ServerSettingsSheet._(),
    );
  }

  @override
  State<ServerSettingsSheet> createState() => _ServerSettingsSheetState();
}

class _ServerSettingsSheetState extends State<ServerSettingsSheet> {
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the current saved values
    final uri = Uri.tryParse(ServerConfig.instance.baseUrl);
    _ipCtrl.text = uri?.host ?? '192.168.0.196';
    _portCtrl.text = (uri?.port ?? 8000).toString();
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final ip = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8000;
    final url = 'http://$ip:$port/api/v1/health';

    try {
      // Simple GET with a short timeout
      final response = await Future.any([
        _doGet(url),
        Future.delayed(const Duration(seconds: 8), () => null),
      ]);

      if (response == null) {
        setState(() {
          _testing = false;
          _testOk = false;
          _testResult = 'Timed out — server not reachable at $ip:$port';
        });
      } else if (response >= 200 && response < 300) {
        setState(() {
          _testing = false;
          _testOk = true;
          _testResult = '✓  Server reachable at $ip:$port';
        });
      } else {
        setState(() {
          _testing = false;
          _testOk = false;
          _testResult = 'Server responded with HTTP $response';
        });
      }
    } catch (e) {
      setState(() {
        _testing = false;
        _testOk = false;
        _testResult = 'Error: $e';
      });
    }
  }

  Future<int?> _doGet(String url) async {
    try {
      // ignore: avoid_web_libraries_in_flutter
      final uri = Uri.parse(url);
      final req = await HttpClient().getUrl(uri);
      final res = await req.close();
      await res.drain<void>();
      return res.statusCode;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ip = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8000;
    await ServerConfig.instance.setServer(ip, port: port);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server updated → $ip:$port'),
          backgroundColor: NVColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _reset() async {
    await ServerConfig.instance.resetToDefault();
    if (mounted) {
      final uri = Uri.tryParse(ServerConfig.instance.baseUrl);
      setState(() {
        _ipCtrl.text = uri?.host ?? '192.168.0.196';
        _portCtrl.text = (uri?.port ?? 8000).toString();
        _testResult = null;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: NVColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: NVColors.border),
          left: BorderSide(color: NVColors.border),
          right: BorderSide(color: NVColors.border),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: NVColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [NVColors.primary, NVColors.accent]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wifi_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Settings',
                      style: TextStyle(
                        color: NVColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Change server IP when on a new Wi-Fi',
                      style: TextStyle(
                          color: NVColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current server badge
            AnimatedBuilder(
              animation: ServerConfig.instance,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: NVColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: NVColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dns_rounded,
                        color: NVColors.primary, size: 14),
                    const SizedBox(width: 8),
                    const Text('Current: ',
                        style: TextStyle(
                            color: NVColors.textMuted, fontSize: 12)),
                    Text(
                      ServerConfig.instance.hostPort,
                      style: const TextStyle(
                        color: NVColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // IP + Port row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IP field
                Expanded(
                  flex: 4,
                  child: _buildField(
                    controller: _ipCtrl,
                    label: 'PC IP Address',
                    hint: '192.168.x.x',
                    icon: Icons.computer_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      if (!ServerConfig.isValidIp(v.trim())) {
                        return 'Invalid IP';
                      }
                      return null;
                    },
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                // Port field
                SizedBox(
                  width: 90,
                  child: _buildField(
                    controller: _portCtrl,
                    label: 'Port',
                    hint: '8000',
                    icon: Icons.settings_ethernet_rounded,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 65535) {
                        return '1-65535';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Test result banner
            if (_testResult != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (_testOk ? NVColors.success : NVColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_testOk ? NVColors.success : NVColors.error)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testOk
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: _testOk ? NVColors.success : NVColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testOk ? NVColors.success : NVColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // How to find IP hint
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: NVColors.bgCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: NVColors.textMuted, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Find PC IP: open PowerShell → type ipconfig → look for "IPv4 Address" under your Wi-Fi adapter.',
                      style: TextStyle(
                          color: NVColors.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                // Reset
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restore_rounded, size: 15),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: NVColors.textMuted,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const Spacer(),
                // Test
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NVColors.primary),
                        )
                      : const Icon(Icons.network_check_rounded, size: 15),
                  label: Text(_testing ? 'Testing…' : 'Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NVColors.primary,
                    side: const BorderSide(
                        color: NVColors.primary, width: 1),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                // Save
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, size: 15),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.primary,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: NVColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(icon, color: NVColors.textMuted, size: 16),
        labelStyle:
            const TextStyle(color: NVColors.textMuted, fontSize: 12),
        hintStyle:
            const TextStyle(color: NVColors.border, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: NVColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: NVColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: NVColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: NVColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: NVColors.bgCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
