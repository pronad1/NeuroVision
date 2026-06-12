// lib/src/ui/widgets/nv_sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

class NVSidebarItem {
  final String label;
  final IconData icon;
  final String route;
  final bool isComingSoon;

  const NVSidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    this.isComingSoon = false,
  });
}

/// Returns true when the screen is narrow (mobile-like).
bool isMobileLayout(BuildContext context) =>
    MediaQuery.of(context).size.width < 768;

/// A convenience scaffold that handles the sidebar/drawer pattern automatically.
/// On desktop it places [NVSidebar] in a [Row]; on mobile it uses a [Drawer].
class NVScaffold extends StatelessWidget {
  final String currentRoute;
  final String role;
  final String title;
  final String subtitle;
  final String userName;
  final Color roleColor;
  final Widget body;
  final Animation<double>? fadeAnimation;

  const NVScaffold({
    super.key,
    required this.currentRoute,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.roleColor,
    required this.body,
    this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = isMobileLayout(context);
    final auth = context.watch<NVAuthProvider>();
    final nvUser = auth.nvUser;

    final sidebar = NVSidebar(currentRoute: currentRoute, role: role);

    final content = fadeAnimation != null
        ? FadeTransition(opacity: fadeAnimation!, child: body)
        : body;

    if (mobile) {
      return Scaffold(
        backgroundColor: NVColors.bgDeep,
        appBar: AppBar(
          backgroundColor: NVColors.bgSurface,
          elevation: 0,
          centerTitle: false,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: NVColors.textSecondary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: NVColors.textMuted, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: NVColors.textSecondary),
              onPressed: () {},
            ),
            GestureDetector(
              onTap: () {
                if (currentRoute != '/profile') {
                  Navigator.pushReplacementNamed(context, '/profile');
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: roleColor.withValues(alpha: 0.2),
                  backgroundImage: (nvUser?.photoUrl != null && nvUser!.photoUrl!.isNotEmpty)
                      ? NetworkImage(nvUser.photoUrl!)
                      : null,
                  child: (nvUser?.photoUrl == null || nvUser!.photoUrl!.isEmpty)
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: NVColors.border),
          ),
        ),
        drawer: Drawer(
          backgroundColor: NVColors.bgSurface,
          child: sidebar,
        ),
        body: content,
      );
    }

    // Desktop / tablet: classic side-by-side layout
    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Row(
        children: [
          sidebar,
          Expanded(child: content),
        ],
      ),
    );
  }
}

class NVSidebar extends StatefulWidget {
  final String currentRoute;
  final String role;

  const NVSidebar({
    super.key,
    required this.currentRoute,
    required this.role,
  });

  @override
  State<NVSidebar> createState() => _NVSidebarState();
}

class _NVSidebarState extends State<NVSidebar> {
  bool _collapsed = false;

  static const _doctorItems = [
    NVSidebarItem(label: 'Overview', icon: Icons.dashboard_rounded, route: '/dashboard/doctor'),
    NVSidebarItem(label: 'Medical Cases', icon: Icons.cases_rounded, route: '/dashboard/doctor/cases'),
    NVSidebarItem(label: 'AI Diagnosis', icon: Icons.psychology_rounded, route: '/dashboard/doctor/ai-diagnosis'),
    NVSidebarItem(label: 'Segmentation', icon: Icons.biotech_rounded, route: '/dashboard/doctor/segmentation'),
    NVSidebarItem(label: 'Heatmaps', icon: Icons.thermostat_rounded, route: '/dashboard/doctor/heatmaps'),
    NVSidebarItem(label: 'Comparative', icon: Icons.compare_rounded, route: '/dashboard/doctor/comparative'),
    NVSidebarItem(label: 'Clinical Notes', icon: Icons.note_alt_rounded, route: '/dashboard/doctor/notes'),
  ];

  static const _radiologistItems = [
    NVSidebarItem(label: 'Overview', icon: Icons.dashboard_rounded, route: '/dashboard/radiologist'),
    NVSidebarItem(label: 'DICOM Viewer', icon: Icons.medical_information_rounded, route: '/dashboard/radiologist/dicom'),
    NVSidebarItem(label: 'Annotations', icon: Icons.draw_rounded, route: '/dashboard/radiologist/annotations'),
    NVSidebarItem(label: 'Lesion Local.', icon: Icons.location_searching_rounded, route: '/dashboard/radiologist/lesions'),
    NVSidebarItem(label: 'Segmentation', icon: Icons.layers_rounded, route: '/dashboard/radiologist/segmentation'),
    NVSidebarItem(label: 'Explainability', icon: Icons.visibility_rounded, route: '/dashboard/radiologist/explainability'),
  ];

  static const _researcherItems = [
    NVSidebarItem(label: 'Overview', icon: Icons.dashboard_rounded, route: '/dashboard/researcher'),
    NVSidebarItem(label: 'Model Monitor', icon: Icons.monitor_heart_rounded, route: '/dashboard/researcher/models'),
    NVSidebarItem(label: 'Metrics', icon: Icons.bar_chart_rounded, route: '/dashboard/researcher/metrics'),
    NVSidebarItem(label: 'Confusion Matrix', icon: Icons.grid_on_rounded, route: '/dashboard/researcher/confusion'),
    NVSidebarItem(label: 'Experiments', icon: Icons.science_rounded, route: '/dashboard/researcher/experiments'),
    NVSidebarItem(label: 'Datasets', icon: Icons.storage_rounded, route: '/dashboard/researcher/datasets'),
    NVSidebarItem(label: 'GPU Monitor', icon: Icons.memory_rounded, route: '/dashboard/researcher/gpu'),
  ];

  List<NVSidebarItem> get _items {
    switch (widget.role) {
      case AppConstants.roleDoctor: return _doctorItems;
      case AppConstants.roleRadiologist: return _radiologistItems;
      case AppConstants.roleResearcher: return _researcherItems;
      default: return _doctorItems;
    }
  }

  Color get _roleColor {
    switch (widget.role) {
      case AppConstants.roleDoctor: return NVColors.doctorColor;
      case AppConstants.roleRadiologist: return NVColors.radiologistColor;
      case AppConstants.roleResearcher: return NVColors.researcherColor;
      default: return NVColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<NVAuthProvider>(context);
    final user = auth.nvUser;
    final isMobile = isMobileLayout(context);
    // On mobile inside a Drawer we always show expanded; no collapse button needed
    final collapsed = isMobile ? false : _collapsed;
    final width = collapsed ? 72.0 : 240.0;

    final sidebarContent = Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: NVColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [NVColors.primary, Color(0xFF0090B8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.biotech_rounded, color: Colors.black, size: 20),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NeuroVision',
                        style: TextStyle(
                          color: NVColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'AI Platform',
                        style: TextStyle(
                          color: NVColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── New Analysis CTA ────────────────────────────────────────
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: GestureDetector(
              onTap: () {
                if (isMobileLayout(context)) Navigator.pop(context);
                if (widget.currentRoute != '/analysis') {
                  Navigator.pushReplacementNamed(context, '/analysis');
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NVColors.primary.withValues(alpha: widget.currentRoute == '/analysis' ? 0.4 : 0.22),
                      NVColors.accent.withValues(alpha: widget.currentRoute == '/analysis' ? 0.3 : 0.14),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: NVColors.primary.withValues(alpha: widget.currentRoute == '/analysis' ? 0.7 : 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NVColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [NVColors.primary, NVColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Analysis',
                            style: TextStyle(
                              color: NVColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Upload & analyze image',
                            style: TextStyle(
                              color: NVColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: NVColors.primary, size: 11),
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Tooltip(
              message: 'New Analysis',
              child: GestureDetector(
                onTap: () {
                  if (widget.currentRoute != '/analysis') {
                    Navigator.pushReplacementNamed(context, '/analysis');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NVColors.primary, NVColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: NVColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _items.map((item) => _buildNavItem(item, collapsed)).toList(),
          ),
        ),

        // Bottom: User profile + collapse toggle
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: NVColors.border)),
          ),
          child: Column(
            children: [
              if (!collapsed && user != null)
                InkWell(
                  onTap: () {
                    if (isMobile) Navigator.pop(context);
                    if (widget.currentRoute != '/profile') {
                      Navigator.pushReplacementNamed(context, '/profile');
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _roleColor.withValues(alpha: 0.2),
                          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: TextStyle(color: _roleColor, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: NVColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _roleColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.roleDisplayName,
                                  style: TextStyle(color: _roleColor, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Sign out + collapse button row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (!collapsed)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            await auth.signOut();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 16, color: NVColors.error),
                          label: const Text('Sign Out', style: TextStyle(color: NVColors.error, fontSize: 13)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ),
                    // Only show collapse toggle on desktop
                    if (!isMobile)
                      IconButton(
                        icon: Icon(
                          collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                          color: NVColors.textMuted,
                        ),
                        onPressed: () => setState(() => _collapsed = !_collapsed),
                        tooltip: collapsed ? 'Expand' : 'Collapse',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      // Inside a Drawer, fill full height
      return SafeArea(child: sidebarContent);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: NVColors.bgSurface,
        border: Border(
          right: BorderSide(color: NVColors.border),
        ),
      ),
      child: sidebarContent,
    );
  }

  Widget _buildNavItem(NVSidebarItem item, bool collapsed) {
    final isActive = widget.currentRoute == item.route;
    final roleColor = _roleColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? roleColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: roleColor.withValues(alpha: 0.3)) : null,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Icon(
            item.icon,
            color: isActive ? roleColor : NVColors.textMuted,
            size: 20,
          ),
          title: collapsed
              ? null
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: isActive ? NVColors.textPrimary : NVColors.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (item.isComingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: NVColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Soon', style: TextStyle(color: NVColors.warning, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
          onTap: item.isComingSoon
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.label} is coming soon!'),
                      backgroundColor: NVColors.bgCard,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : () {
                  // Close drawer on mobile before navigating
                  if (isMobileLayout(context)) Navigator.pop(context);
                  if (widget.currentRoute != item.route) {
                    Navigator.pushReplacementNamed(context, item.route);
                  }
                },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
