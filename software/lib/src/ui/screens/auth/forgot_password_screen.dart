// lib/src/ui/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) setState(() { _isLoading = false; _sent = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: NVColors.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      appBar: AppBar(backgroundColor: NVColors.bgDeep, surfaceTintColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: NVColors.textSecondary), onPressed: () => Navigator.pop(context))),
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      )),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: NVColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: NVColors.primary.withValues(alpha: 0.3))), child: const Icon(Icons.lock_reset_rounded, color: NVColors.primary, size: 28)),
        const SizedBox(height: 20),
        const Text('Reset Password', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 26)),
        const SizedBox(height: 8),
        const Text("Enter your institutional email and we'll send a password reset link.", style: TextStyle(color: NVColors.textMuted, fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
        TextFormField(
          controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: NVColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Email Address', hintText: 'your@institution.org', prefixIcon: Icon(Icons.email_outlined, size: 18)),
          validator: (v) { if (v == null || v.isEmpty) return 'Email required'; if (!v.contains('@')) return 'Invalid email'; return null; },
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: _isLoading ? null : _sendReset,
          style: ElevatedButton.styleFrom(backgroundColor: NVColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Send Reset Link'),
        )),
        const SizedBox(height: 16),
        Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Sign In', style: TextStyle(color: NVColors.textMuted, fontSize: 13)))),
      ]),
    );
  }

  Widget _buildSuccess() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: NVColors.success.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: NVColors.success.withValues(alpha: 0.3), width: 2)), child: const Icon(Icons.mark_email_read_rounded, color: NVColors.success, size: 40)),
      const SizedBox(height: 24),
      const Text('Email Sent!', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 24)),
      const SizedBox(height: 10),
      const Text('Check your inbox for a password reset link. It may take a few minutes to arrive.', textAlign: TextAlign.center, style: TextStyle(color: NVColors.textMuted, fontSize: 14, height: 1.5)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false), style: ElevatedButton.styleFrom(backgroundColor: NVColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w600)), child: const Text('Return to Sign In')),
    ]);
  }
}
