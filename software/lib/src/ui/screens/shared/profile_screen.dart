// lib/src/ui/screens/shared/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/nv_sidebar.dart';
import '../../widgets/nv_top_bar.dart';
import '../../widgets/nv_glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _editMode = false;
  final _nameCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); _nameCtrl.dispose(); _institutionCtrl.dispose(); _specializationCtrl.dispose(); super.dispose(); }

  Color get _roleColor {
    final user = Provider.of<NVAuthProvider>(context, listen: false).nvUser;
    return switch (user?.role) {
      AppConstants.roleDoctor => NVColors.doctorColor,
      AppConstants.roleRadiologist => NVColors.radiologistColor,
      AppConstants.roleResearcher => NVColors.researcherColor,
      _ => NVColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<NVAuthProvider>(context);
    final user = auth.nvUser;

    if (user != null) {
      _nameCtrl.text = user.name;
      _institutionCtrl.text = user.institution ?? '';
      _specializationCtrl.text = user.specialization ?? '';
    }

    final roleColor = _roleColor;

    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Row(
        children: [
          NVSidebar(currentRoute: '/profile', role: user?.role ?? AppConstants.roleDoctor),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: Column(children: [
                NVTopBar(title: 'My Profile', subtitle: 'Account information and preferences', user: user?.name ?? '', roleColor: roleColor),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(children: [
                      // Profile header card
                      NVGlassCard(
                        padding: const EdgeInsets.all(28),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Avatar
                          Stack(children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: roleColor.withValues(alpha: 0.2),
                              child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U', style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 42)),
                            ),
                            Positioned(bottom: 0, right: 0, child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle, border: Border.all(color: NVColors.bgDeep, width: 2)),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 14),
                            )),
                          ]),
                          const SizedBox(width: 24),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(user?.name ?? 'Unknown', style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '', style: const TextStyle(color: NVColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 10),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: roleColor.withValues(alpha: 0.4))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(_roleIcon(user?.role ?? ''), color: roleColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text(user?.roleDisplayName ?? '', style: TextStyle(color: roleColor, fontWeight: FontWeight.w600, fontSize: 12)),
                                ]),
                              ),
                              const SizedBox(width: 10),
                              if (user?.approved == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: NVColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: NVColors.success.withValues(alpha: 0.3))),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_rounded, color: NVColors.success, size: 13), SizedBox(width: 5), Text('Approved', style: TextStyle(color: NVColors.success, fontWeight: FontWeight.w600, fontSize: 11))]),
                                ),
                            ]),
                          ])),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _editMode = !_editMode),
                            icon: Icon(_editMode ? Icons.close_rounded : Icons.edit_rounded, size: 16),
                            label: Text(_editMode ? 'Cancel' : 'Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _editMode ? NVColors.bgCard : roleColor,
                              foregroundColor: _editMode ? NVColors.textSecondary : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: _editMode ? const BorderSide(color: NVColors.border) : BorderSide.none),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Info cards row
                      Row(children: [
                        Expanded(child: _InfoCard(icon: Icons.business_rounded, label: 'Institution', value: user?.institution ?? 'Not set', color: roleColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoCard(icon: Icons.school_rounded, label: 'Specialization', value: user?.specialization ?? 'Not set', color: roleColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoCard(icon: Icons.email_rounded, label: 'Email Verified', value: 'Active', color: NVColors.success)),
                      ]),
                      const SizedBox(height: 16),

                      // Edit form
                      if (_editMode)
                        NVGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Row(children: [Icon(Icons.edit_rounded, color: NVColors.textMuted, size: 16), SizedBox(width: 8), Text('Edit Information', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]),
                            const SizedBox(height: 16),
                            TextFormField(controller: _nameCtrl, style: const TextStyle(color: NVColors.textPrimary), decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded, size: 18))),
                            const SizedBox(height: 12),
                            TextFormField(controller: _institutionCtrl, style: const TextStyle(color: NVColors.textPrimary), decoration: const InputDecoration(labelText: 'Institution', prefixIcon: Icon(Icons.business_rounded, size: 18))),
                            const SizedBox(height: 12),
                            TextFormField(controller: _specializationCtrl, style: const TextStyle(color: NVColors.textPrimary), decoration: const InputDecoration(labelText: 'Specialization', prefixIcon: Icon(Icons.school_rounded, size: 18))),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _editMode = false),
                              icon: const Icon(Icons.save_rounded, size: 16),
                              label: const Text('Save Changes'),
                              style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), textStyle: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ),

                      const SizedBox(height: 16),
                      // Security
                      NVGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [Icon(Icons.security_rounded, color: NVColors.textMuted, size: 16), SizedBox(width: 8), Text('Security', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]),
                          const SizedBox(height: 16),
                          _SecurityRow(icon: Icons.lock_reset_rounded, label: 'Change Password', subtitle: 'Update your account password', onTap: () {}),
                          const Divider(color: NVColors.border),
                          _SecurityRow(icon: Icons.logout_rounded, label: 'Sign Out', subtitle: 'Sign out from all devices', color: NVColors.error, onTap: () async {
                            await auth.signOut();
                            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                          }),
                        ]),
                      ),
                    ]),
                  )),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) => switch (role) {
    AppConstants.roleDoctor => Icons.medical_services_rounded,
    AppConstants.roleRadiologist => Icons.scanner_rounded,
    AppConstants.roleResearcher => Icons.science_rounded,
    _ => Icons.person_rounded,
  };
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _InfoCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => NVGlassCard(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(value, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)]))]));
}

class _SecurityRow extends StatelessWidget {
  final IconData icon; final String label, subtitle; final Color color; final VoidCallback onTap;
  const _SecurityRow({required this.icon, required this.label, required this.subtitle, this.color = NVColors.textSecondary, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)), Text(subtitle, style: const TextStyle(color: NVColors.textMuted, fontSize: 11))])), Icon(Icons.chevron_right_rounded, color: color, size: 18)])));
}
