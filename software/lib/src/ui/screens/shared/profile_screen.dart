// lib/src/ui/screens/shared/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/supabase_image_service.dart';
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

  // Tabs: 'profile', 'preferences', 'security'
  String _activeTab = 'profile';

  bool _isSaving = false;
  bool _isUploading = false;

  final _nameCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();

  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _imageService = SupabaseImageService();
  final _picker = ImagePicker();

  bool _themeMode = true;
  bool _emailNotifications = true;
  bool _urgentAlerts = true;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _themeMode = prefs.getBool('pref_theme_mode') ?? true;
        _emailNotifications = prefs.getBool('pref_email_notifications') ?? true;
        _urgentAlerts = prefs.getBool('pref_urgent_alerts') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Preference updated successfully'),
            duration: const Duration(milliseconds: 500),
            backgroundColor: NVColors.success,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 70,
              left: 24,
              right: 24,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    _loadPreferences();

    // Populate controllers with user profile state once after frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<NVAuthProvider>(context, listen: false).nvUser;
      if (user != null) {
        _nameCtrl.text = user.name;
        _institutionCtrl.text = user.institution ?? '';
        _specializationCtrl.text = user.specialization ?? '';
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _institutionCtrl.dispose();
    _specializationCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Color get _roleColor {
    final user = Provider.of<NVAuthProvider>(context, listen: false).nvUser;
    return switch (user?.role) {
      AppConstants.roleDoctor => NVColors.doctorColor,
      AppConstants.roleRadiologist => NVColors.radiologistColor,
      AppConstants.roleResearcher => NVColors.researcherColor,
      _ => NVColors.primary,
    };
  }

  Future<void> _pickAndUploadImage() async {
    final auth = Provider.of<NVAuthProvider>(context, listen: false);
    final user = auth.nvUser;
    if (user == null) return;

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: NVColors.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: NVColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(color: NVColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: NVColors.primary),
                title: const Text('Take a Photo', style: TextStyle(color: NVColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // 1. Upload file to Supabase Storage
      final result = await _imageService.uploadProfileImage(
        uid: user.uid,
        file: image,
      );

      // 2. Persist updated image URL to database profile
      final error = await auth.updateProfile(
        name: _nameCtrl.text.trim(),
        institution: _institutionCtrl.text.trim(),
        specialization: _specializationCtrl.text.trim(),
        photoUrl: result.publicUrl,
      );

      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: NVColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw error;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: NVColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfileDetails() async {
    final name = _nameCtrl.text.trim();
    final institution = _institutionCtrl.text.trim();
    final specialization = _specializationCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: NVColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<NVAuthProvider>(context, listen: false);
    final error = await auth.updateProfile(
      name: name,
      institution: institution,
      specialization: specialization,
    );
    setState(() => _isSaving = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile details updated successfully!'), backgroundColor: NVColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: NVColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password cannot be empty'), backgroundColor: NVColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: NVColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: NVColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<NVAuthProvider>(context, listen: false);
    final error = await auth.changePassword(newPassword);
    setState(() => _isSaving = false);

    if (error == null) {
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: NVColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: NVColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<NVAuthProvider>(context);
    final user = auth.nvUser;
    final isMobile = isMobileLayout(context);
    final roleColor = _roleColor;

    return NVScaffold(
      currentRoute: '/profile',
      role: user?.role ?? AppConstants.roleDoctor,
      title: 'My Profile',
      subtitle: 'Account information and settings',
      userName: user?.name ?? '',
      roleColor: roleColor,
      fadeAnimation: _fade,
      body: Column(
        children: [
          NVTopBar(title: 'My Profile', subtitle: 'Account information and preferences', user: user?.name ?? '', roleColor: roleColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildLeftPanel(user, roleColor),
                            const SizedBox(height: 20),
                            _buildRightPanel(roleColor, auth),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 320, child: _buildLeftPanel(user, roleColor)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildRightPanel(roleColor, auth)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(dynamic user, Color roleColor) {
    return NVGlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Avatar + Edit Camera Overlay
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                    ? Text(
                        user?.name.isNotEmpty == true ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 44),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: roleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: NVColors.bgDeep, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16),
                    ),
                  ),
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(NVColors.primary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user?.name ?? 'Clinical Staff',
            textAlign: TextAlign.center,
            style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: NVColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(color: NVColors.border),
          const SizedBox(height: 16),
          
          // Role Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_roleIcon(user?.role ?? ''), color: roleColor, size: 14),
                    const SizedBox(width: 6),
                    Text(user?.roleDisplayName ?? '', style: TextStyle(color: roleColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (user?.approved == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: NVColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NVColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: NVColors.success, size: 13),
                      SizedBox(width: 5),
                      Text('Approved', style: TextStyle(color: NVColors.success, fontWeight: FontWeight.w600, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Static Institution/Specialization cards
          _buildInfoTile(Icons.business_rounded, 'Institution', user?.institution ?? 'Not configured', roleColor),
          const SizedBox(height: 8),
          _buildInfoTile(Icons.school_rounded, 'Specialization', user?.specialization ?? 'Not configured', roleColor),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NVColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRightPanel(Color roleColor, NVAuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selectors
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTabButton('profile', 'Clinical Profile', Icons.person_outline_rounded, roleColor),
              const SizedBox(width: 8),
              _buildTabButton('preferences', 'Preferences', Icons.settings_rounded, roleColor),
              const SizedBox(width: 8),
              _buildTabButton('security', 'Security & Account', Icons.security_rounded, roleColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Active tab container
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildActiveTabContent(roleColor, auth),
        ),
      ],
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon, Color roleColor) {
    final active = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? roleColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active ? Border.all(color: roleColor.withValues(alpha: 0.3)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? roleColor : NVColors.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? NVColors.textPrimary : NVColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(Color roleColor, NVAuthProvider auth) {
    switch (_activeTab) {
      case 'profile':
        return NVGlassCard(
          key: const ValueKey('profile_tab'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_rounded, color: NVColors.textSecondary, size: 18),
                  SizedBox(width: 8),
                  Text('Modify Clinical Profile', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Inputs
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: NVColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _institutionCtrl,
                style: const TextStyle(color: NVColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Institution',
                  prefixIcon: Icon(Icons.business_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specializationCtrl,
                style: const TextStyle(color: NVColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Specialization / Medical Field',
                  prefixIcon: Icon(Icons.school_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfileDetails,
                  icon: _isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_isSaving ? 'Saving Changes...' : 'Save Profile Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'preferences':
        return NVGlassCard(
          key: const ValueKey('preferences_tab'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: NVColors.textSecondary, size: 18),
                  SizedBox(width: 8),
                  Text('App Preferences', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Theme display
              _buildPreferenceToggle(
                Icons.dark_mode_rounded,
                'Theme Mode',
                _themeMode ? 'Professional Dark (Active)' : 'Standard Light (Inactive)',
                _themeMode,
                (val) {
                  setState(() => _themeMode = val);
                  _savePreference('pref_theme_mode', val);
                },
              ),
              const SizedBox(height: 12),
              _buildPreferenceToggle(
                Icons.mark_email_read_rounded,
                'Email Notifications',
                'Receive verification and clinical activity summaries',
                _emailNotifications,
                (val) {
                  setState(() => _emailNotifications = val);
                  _savePreference('pref_email_notifications', val);
                },
              ),
              const SizedBox(height: 12),
              _buildPreferenceToggle(
                Icons.circle_notifications_rounded,
                'Urgent Analysis Alerts',
                'Highlight high-severity AI detections immediately',
                _urgentAlerts,
                (val) {
                  setState(() => _urgentAlerts = val);
                  _savePreference('pref_urgent_alerts', val);
                },
              ),
              const SizedBox(height: 24),
              
              // Info App Version
              const Center(
                child: Text(
                  'NeuroVision Platform v1.0.0+1',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        );

      case 'security':
        return NVGlassCard(
          key: const ValueKey('security_tab'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_rounded, color: NVColors.textSecondary, size: 18),
                  SizedBox(width: 8),
                  Text('Update Account Security', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Password Forms
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: NVColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: NVColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _updatePassword,
                  icon: const Icon(Icons.security_rounded, size: 16),
                  label: const Text('Update Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.warning,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: NVColors.border),
              const SizedBox(height: 16),
              
              // Logout Actions
              InkWell(
                onTap: () async {
                  await auth.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: NVColors.error.withValues(alpha: 0.1),
                    border: Border.all(color: NVColors.error.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: NVColors.error, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sign Out of Application', style: TextStyle(color: NVColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Securely close your current active session', style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: NVColors.error, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPreferenceToggle(IconData icon, String title, String subtitle, bool val, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NVColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: NVColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeThumbColor: NVColors.primary,
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
