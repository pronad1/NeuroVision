// lib/src/ui/screens/dashboard/radiologist/segmentation_review_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_stat_card.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _CaseItem {
  final String caseId;
  final String modality;
  final String maskType;
  final String priority;
  final Color priorityColor;

  const _CaseItem({
    required this.caseId,
    required this.modality,
    required this.maskType,
    required this.priority,
    required this.priorityColor,
  });
}

class _HistoryItem {
  final String caseId;
  final String status;
  final Color statusColor;
  final String time;

  const _HistoryItem({
    required this.caseId,
    required this.status,
    required this.statusColor,
    required this.time,
  });
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------

class SegmentationReviewScreen extends StatefulWidget {
  const SegmentationReviewScreen({super.key});

  @override
  State<SegmentationReviewScreen> createState() =>
      _SegmentationReviewScreenState();
}

class _SegmentationReviewScreenState extends State<SegmentationReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  int _selectedCaseIndex = 0;
  double _maskOpacity = 0.65;
  String _viewMode = 'Overlay'; // 'Original', 'Overlay', 'Contour Only'
  final TextEditingController _notesController = TextEditingController();

  static const _cases = [
    _CaseItem(
      caseId: 'CASE-2026-047',
      modality: 'Brain MRI',
      maskType: 'Tumor Segmentation',
      priority: 'High',
      priorityColor: NVColors.error,
    ),
    _CaseItem(
      caseId: 'CASE-2026-046',
      modality: 'Spine MRI',
      maskType: 'Disc Segmentation',
      priority: 'Medium',
      priorityColor: NVColors.warning,
    ),
    _CaseItem(
      caseId: 'CASE-2026-044',
      modality: 'CT Scan',
      maskType: 'Hemorrhage Mask',
      priority: 'High',
      priorityColor: NVColors.error,
    ),
    _CaseItem(
      caseId: 'CASE-2026-043',
      modality: 'Chest X-Ray',
      maskType: 'Lung Segmentation',
      priority: 'Low',
      priorityColor: NVColors.success,
    ),
    _CaseItem(
      caseId: 'CASE-2026-041',
      modality: 'Brain MRI',
      maskType: 'Edema Mask',
      priority: 'Medium',
      priorityColor: NVColors.warning,
    ),
    _CaseItem(
      caseId: 'CASE-2026-040',
      modality: 'Spine MRI',
      maskType: 'Vertebrae Seg.',
      priority: 'Low',
      priorityColor: NVColors.success,
    ),
    _CaseItem(
      caseId: 'CASE-2026-039',
      modality: 'Brain MRI',
      maskType: 'Lesion Boundary',
      priority: 'High',
      priorityColor: NVColors.error,
    ),
  ];

  static const _history = [
    _HistoryItem(
      caseId: 'CASE-2026-048',
      status: 'Approved',
      statusColor: NVColors.success,
      time: '2h ago',
    ),
    _HistoryItem(
      caseId: 'CASE-2026-045',
      status: 'Approved',
      statusColor: NVColors.success,
      time: '3h ago',
    ),
    _HistoryItem(
      caseId: 'CASE-2026-042',
      status: 'Corrected',
      statusColor: NVColors.warning,
      time: '5h ago',
    ),
    _HistoryItem(
      caseId: 'CASE-2026-038',
      status: 'Rejected',
      statusColor: NVColors.error,
      time: '1d ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onApprove() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: NVColors.success, size: 18),
            const SizedBox(width: 10),
            const Text(
              'Segmentation mask approved successfully',
              style: TextStyle(color: NVColors.textPrimary),
            ),
          ],
        ),
        backgroundColor: NVColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onReject() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: NVColors.error, size: 18),
            const SizedBox(width: 10),
            const Text(
              'Mask rejected - sent back to AI pipeline',
              style: TextStyle(color: NVColors.textPrimary),
            ),
          ],
        ),
        backgroundColor: NVColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;

    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Row(
        children: [
          NVSidebar(
            currentRoute: '/dashboard/radiologist/segmentation',
            role: AppConstants.roleRadiologist,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  NVTopBar(
                    title: 'Segmentation Review',
                    subtitle:
                        'Validate and approve AI-generated segmentation masks',
                    user: user?.name ?? 'Radiologist',
                    roleColor: NVColors.radiologistColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stats Row ──────────────────────────────────────
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                          // ── Main Content ───────────────────────────────────
                          Expanded(child: _buildMainContent()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: NVStatCard(
            label: 'Masks Generated',
            value: '312',
            icon: Icons.layers_rounded,
            color: NVColors.radiologistColor,
            subtitle: 'Total AI masks',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NVStatCard(
            label: 'Approved',
            value: '287',
            icon: Icons.check_circle_rounded,
            color: NVColors.success,
            trend: '91.9%',
            trendPositive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NVStatCard(
            label: 'Rejected',
            value: '18',
            icon: Icons.cancel_rounded,
            color: NVColors.error,
            subtitle: 'Needed correction',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NVStatCard(
            label: 'Pending Review',
            value: '7',
            icon: Icons.pending_rounded,
            color: NVColors.warning,
          ),
        ),
      ],
    );
  }

  // ─── Main 3-column layout ──────────────────────────────────────────────────

  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left – Queue panel
        SizedBox(width: 280, child: _buildQueuePanel()),
        const SizedBox(width: 16),
        // Center – Viewer + stats
        Expanded(child: _buildCenterPanel()),
        const SizedBox(width: 16),
        // Right – Actions + history
        SizedBox(width: 260, child: _buildRightPanel()),
      ],
    );
  }

  // ─── Left: Pending Review Queue ────────────────────────────────────────────

  Widget _buildQueuePanel() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: NVColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.pending_rounded,
                    color: NVColors.warning, size: 16),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Review Queue',
                    style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '7 cases awaiting',
                    style: TextStyle(
                        color: NVColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: NVColors.border, height: 1),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _cases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _buildQueueItem(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(int index) {
    final c = _cases[index];
    final isSelected = _selectedCaseIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedCaseIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? NVColors.radiologistColor.withValues(alpha: 0.12)
              : NVColors.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? NVColors.radiologistColor.withValues(alpha: 0.5)
                : NVColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 46,
              decoration: BoxDecoration(
                color: c.priorityColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.caseId,
                          style: TextStyle(
                            color: isSelected
                                ? NVColors.radiologistColor
                                : NVColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: c.priorityColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          c.priority,
                          style: TextStyle(
                            color: c.priorityColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.modality,
                    style: const TextStyle(
                        color: NVColors.textSecondary, fontSize: 10),
                  ),
                  Text(
                    c.maskType,
                    style: const TextStyle(
                        color: NVColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Center panel ──────────────────────────────────────────────────────────

  Widget _buildCenterPanel() {
    return Column(
      children: [
        // Segmentation Viewer
        NVGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: NVColors.radiologistColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              NVColors.radiologistColor.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.biotech_rounded,
                        color: NVColors.radiologistColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Segmentation Viewer',
                    style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // View mode chips
                  ...[
                    'Original',
                    'Overlay',
                    'Contour Only',
                  ].map((mode) => _ViewModeChip(
                        label: mode,
                        selected: _viewMode == mode,
                        onTap: () => setState(() => _viewMode = mode),
                      )),
                ],
              ),
              const SizedBox(height: 12),

              // Opacity toolbar row
              Row(
                children: [
                  const Icon(Icons.opacity_rounded,
                      color: NVColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Mask Opacity',
                    style: TextStyle(
                        color: NVColors.textMuted, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: NVColors.radiologistColor,
                        inactiveTrackColor: NVColors.border,
                        thumbColor: NVColors.radiologistColor,
                        overlayColor:
                            NVColors.radiologistColor.withValues(alpha: 0.1),
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _maskOpacity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (v) =>
                            setState(() => _maskOpacity = v),
                      ),
                    ),
                  ),
                  Text(
                    '${(_maskOpacity * 100).round()}%',
                    style: const TextStyle(
                        color: NVColors.radiologistColor, fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Viewer canvas
              _buildViewerCanvas(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Mask Statistics
        _buildMaskStatistics(),
      ],
    );
  }

  Widget _buildViewerCanvas() {
    final activeCase = _cases[_selectedCaseIndex];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NVColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background radial gradient simulating dark scan
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF16213E).withValues(alpha: 0.98),
                    const Color(0xFF0A0A1A),
                  ],
                ),
              ),
            ),

            // Brain outline layer
            CustomPaint(
              painter: _BrainOutlinePainter(),
              size: Size.infinite,
            ),

            // Segmentation mask overlay (conditional by view mode)
            if (_viewMode != 'Original')
              CustomPaint(
                painter: _SegmentationMaskPainter(
                  opacity: _maskOpacity,
                  contourOnly: _viewMode == 'Contour Only',
                ),
                size: Size.infinite,
              ),

            // Case ID badge (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color:
                          NVColors.radiologistColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: NVColors.radiologistColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeCase.caseId,
                      style: const TextStyle(
                        color: NVColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activeCase.maskType,
                      style: const TextStyle(
                          color: NVColors.textMuted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),

            // Legend (bottom-right)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NVColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(
                        color: NVColors.radiologistColor, label: 'Tumor'),
                    const SizedBox(height: 5),
                    _LegendDot(color: NVColors.warning, label: 'Edema'),
                    const SizedBox(height: 5),
                    _LegendDot(color: NVColors.success, label: 'Normal'),
                  ],
                ),
              ),
            ),

            // View mode badge (top-right)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NVColors.radiologistColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color:
                          NVColors.radiologistColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _viewMode,
                  style: const TextStyle(
                    color: NVColors.radiologistColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaskStatistics() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: NVColors.info.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: NVColors.info, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Mask Statistics',
                style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _MetricBox(
                label: 'Coverage Area',
                value: '14.7%',
                color: NVColors.radiologistColor,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricBox(
                label: 'Boundary Accuracy',
                value: '92.3%',
                color: NVColors.success,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricBox(
                label: 'Dice Score',
                value: '0.891',
                color: NVColors.info,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _MetricBox(
                label: 'IoU Score',
                value: '0.847',
                color: NVColors.warning,
              )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Right panel ───────────────────────────────────────────────────────────

  Widget _buildRightPanel() {
    return Column(
      children: [
        // Review Actions card
        NVGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: NVColors.radiologistColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: NVColors.radiologistColor
                              .withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.rate_review_rounded,
                        color: NVColors.radiologistColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Review Actions',
                    style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Approve
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onApprove,
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Approve Mask'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Request Correction
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: NVColors.warning, size: 18),
                            SizedBox(width: 10),
                            Text('Correction request sent to AI pipeline',
                                style:
                                    TextStyle(color: NVColors.textPrimary)),
                          ],
                        ),
                        backgroundColor: NVColors.bgCard,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon:
                      const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Request Correction'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NVColors.warning,
                    side: const BorderSide(color: NVColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Reject
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onReject,
                  icon:
                      const Icon(Icons.cancel_rounded, size: 16),
                  label: const Text('Reject Mask'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NVColors.error,
                    side: const BorderSide(color: NVColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Notes field
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(
                    color: NVColors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Add review notes...',
                  hintStyle: const TextStyle(
                      color: NVColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: NVColors.bgDeep,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: NVColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: NVColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: NVColors.radiologistColor, width: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Review History card
        Expanded(child: _buildHistoryCard()),
      ],
    );
  }

  Widget _buildHistoryCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: NVColors.border),
                ),
                child: const Icon(Icons.history_rounded,
                    color: NVColors.textSecondary, size: 16),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review History',
                    style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Recent Reviews',
                    style: TextStyle(
                        color: NVColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: NVColors.border, height: 1),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _history.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final h = _history[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: NVColors.bgDeep,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NVColors.border),
                  ),
                  child: Row(
                    children: [
                      // Status dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: h.statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: h.statusColor
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.caseId,
                              style: const TextStyle(
                                color: NVColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: h.statusColor
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                              color: h.statusColor
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          h.status,
                          style: TextStyle(
                            color: h.statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        h.time,
                        style: const TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 9),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting Widgets
// ---------------------------------------------------------------------------

class _ViewModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(left: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? NVColors.radiologistColor.withValues(alpha: 0.15)
              : NVColors.bgDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? NVColors.radiologistColor.withValues(alpha: 0.7)
                : NVColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? NVColors.radiologistColor
                : NVColors.textMuted,
            fontSize: 10,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              color: NVColors.textSecondary, fontSize: 9),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NVColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NVColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainters
// ---------------------------------------------------------------------------

/// Draws a stylised brain outline (cranial silhouette + fissure + gyri hints)
class _BrainOutlinePainter extends CustomPainter {
  const _BrainOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    // Outer cranial oval
    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.60,
          height: size.height * 0.78),
      outerPaint,
    );

    // Inner fill (very faint brain tissue feel)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.60,
          height: size.height * 0.78),
      Paint()
        ..color = const Color(0xFF1E2A4A).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );

    // Central longitudinal fissure
    final fissurePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.36),
      Offset(cx, cy + size.height * 0.36),
      fissurePaint,
    );

    // Gyri hints (small curved strokes)
    final gyriPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void gyriArc(double x, double y, double w, double h,
        double startAngle, double sweep) {
      final rect = Rect.fromCenter(
          center: Offset(x, y), width: w, height: h);
      canvas.drawArc(rect, startAngle, sweep, false, gyriPaint);
    }

    gyriArc(cx - size.width * 0.08, cy - size.height * 0.10,
        size.width * 0.12, size.height * 0.14, -pi * 0.8, pi * 0.6);
    gyriArc(cx + size.width * 0.08, cy - size.height * 0.10,
        size.width * 0.12, size.height * 0.14, -pi * 0.2, pi * 0.6);
    gyriArc(cx - size.width * 0.06, cy + size.height * 0.08,
        size.width * 0.14, size.height * 0.12, -pi * 0.5, pi * 0.5);
    gyriArc(cx + size.width * 0.06, cy + size.height * 0.08,
        size.width * 0.14, size.height * 0.12, -pi * 0.5, pi * 0.5);

    // Cerebellum hint (bottom oval)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.32),
          width: size.width * 0.22,
          height: size.height * 0.12),
      outerPaint..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _BrainOutlinePainter old) => false;
}

/// Draws segmentation mask (filled tumor oval + edema oval + dashed contours)
class _SegmentationMaskPainter extends CustomPainter {
  final double opacity;
  final bool contourOnly;

  const _SegmentationMaskPainter({
    required this.opacity,
    required this.contourOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    // ── Tumor region ─────────────────────────────────────────────────────
    final tumorRect = Rect.fromCenter(
      center: Offset(cx - size.width * 0.06, cy - size.height * 0.08),
      width: size.width * 0.20,
      height: size.height * 0.22,
    );

    if (!contourOnly) {
      canvas.drawOval(
        tumorRect,
        Paint()
          ..color = NVColors.radiologistColor
              .withValues(alpha: 0.30 * opacity)
          ..style = PaintingStyle.fill,
      );
    }

    // Solid border for tumor
    canvas.drawOval(
      tumorRect,
      Paint()
        ..color =
            NVColors.radiologistColor.withValues(alpha: 0.85 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Dashed border for tumor (drawn on top)
    _drawDashedOval(
      canvas,
      tumorRect,
      NVColors.radiologistColor.withValues(alpha: 0.55 * opacity),
      dashLength: 6,
      gapLength: 4,
      strokeWidth: 1.0,
    );

    // Glow dot at centroid
    canvas.drawCircle(
      tumorRect.center,
      4,
      Paint()
        ..color =
            NVColors.radiologistColor.withValues(alpha: 0.6 * opacity)
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // ── Edema region (larger, lower opacity) ─────────────────────────────
    final edemaRect = Rect.fromCenter(
      center: Offset(cx - size.width * 0.04, cy - size.height * 0.05),
      width: size.width * 0.33,
      height: size.height * 0.37,
    );

    if (!contourOnly) {
      canvas.drawOval(
        edemaRect,
        Paint()
          ..color =
              NVColors.warning.withValues(alpha: 0.18 * opacity)
          ..style = PaintingStyle.fill,
      );
    }

    // Edema contour
    canvas.drawOval(
      edemaRect,
      Paint()
        ..color = NVColors.warning.withValues(alpha: 0.6 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawDashedOval(
      canvas,
      edemaRect,
      NVColors.warning.withValues(alpha: 0.35 * opacity),
      dashLength: 8,
      gapLength: 5,
      strokeWidth: 0.8,
    );
  }

  /// Approximates a dashed oval by sampling points around the ellipse
  void _drawDashedOval(
    Canvas canvas,
    Rect rect,
    Color color, {
    required double dashLength,
    required double gapLength,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final a = rect.width / 2;
    final b = rect.height / 2;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // Circumference approximation
    final circumference = pi * (3 * (a + b) - sqrt((3 * a + b) * (a + 3 * b)));
    final totalDash = dashLength + gapLength;
    final steps = (circumference / totalDash).ceil() * 60;

    bool drawing = true;
    double accumulated = 0;
    Offset? lastPoint;

    for (int i = 0; i <= steps; i++) {
      final angle = 2 * pi * i / steps;
      final x = cx + a * cos(angle);
      final y = cy + b * sin(angle);
      final pt = Offset(x, y);

      if (lastPoint != null) {
        final segLen = (pt - lastPoint).distance;
        accumulated += segLen;

        if (drawing) {
          canvas.drawLine(lastPoint, pt, paint);
          if (accumulated >= dashLength) {
            accumulated -= dashLength;
            drawing = false;
          }
        } else {
          if (accumulated >= gapLength) {
            accumulated -= gapLength;
            drawing = true;
          }
        }
      }
      lastPoint = pt;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentationMaskPainter old) =>
      old.opacity != opacity || old.contourOnly != contourOnly;
}
