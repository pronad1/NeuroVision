// lib/src/ui/screens/dashboard/radiologist/explainability_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/analysis_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_stat_card.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _CaseData {
  final String id;
  final String modality;
  final String prediction;
  final int confidence;
  const _CaseData(this.id, this.modality, this.prediction, this.confidence);
}

class _AttentionRegion {
  final String name;
  final double weight;
  final Color color;
  const _AttentionRegion(this.name, this.weight, this.color);
}

class _FeatureRow {
  final String feature;
  final double attribution;
  final String contribution;
  final String direction;
  final String significance;
  const _FeatureRow(this.feature, this.attribution, this.contribution,
      this.direction, this.significance);
}

class _ConfidenceBand {
  final String label;
  final int count;
  final Color color;
  const _ConfidenceBand(this.label, this.count, this.color);
}

// ---------------------------------------------------------------------------
// Main screen widget
// ---------------------------------------------------------------------------
class ExplainabilityScreen extends StatefulWidget {
  const ExplainabilityScreen({super.key});

  @override
  State<ExplainabilityScreen> createState() => _ExplainabilityScreenState();
}

class _ExplainabilityScreenState extends State<ExplainabilityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  int _selectedCase = 0;
  int _selectedMethod = 0;

  // ── Static demo data ──────────────────────────────────────────────────────
  static const _cases = [
    _CaseData('CASE-047', 'MRI', 'Glioblastoma', 94),
    _CaseData('CASE-051', 'CT', 'Hemorrhage', 87),
    _CaseData('CASE-063', 'MRI', 'Meningioma', 82),
    _CaseData('CASE-078', 'PET', 'Metastasis', 76),
    _CaseData('CASE-091', 'MRI', 'Normal', 91),
  ];

  static const _methods = ['Grad-CAM', 'Grad-CAM++', 'SmoothGrad'];

  static const _regions = [
    _AttentionRegion('Left Frontal', 0.91, NVColors.error),
    _AttentionRegion('Right Frontal', 0.78, NVColors.warning),
    _AttentionRegion('Parietal', 0.64, NVColors.warning),
    _AttentionRegion('Temporal', 0.48, NVColors.radiologistColor),
    _AttentionRegion('Occipital', 0.31, NVColors.info),
    _AttentionRegion('Cerebellar', 0.19, NVColors.success),
  ];

  static const _features = [
    _FeatureRow('Hypointense Region', 0.847, '28.4%', 'Positive', 'Critical'),
    _FeatureRow('Sulcal Widening', 0.623, '20.9%', 'Positive', 'High'),
    _FeatureRow('White Matter Change', 0.541, '18.1%', 'Positive', 'High'),
    _FeatureRow('Midline Shift', 0.412, '13.8%', 'Positive', 'Medium'),
    _FeatureRow('Ventricle Size', 0.289, '9.7%', 'Negative', 'Medium'),
    _FeatureRow('Signal Intensity', 0.198, '6.6%', 'Positive', 'Low'),
    _FeatureRow('Cortex Thickness', 0.142, '4.8%', 'Negative', 'Low'),
    _FeatureRow('Baseline Symmetry', -0.052, '-1.7%', 'Negative', 'Minimal'),
  ];

  static const _confidenceBands = [
    _ConfidenceBand('90-100%', 42, NVColors.success),
    _ConfidenceBand('80-89%', 38, NVColors.radiologistColor),
    _ConfidenceBand('70-79%', 22, NVColors.warning),
    _ConfidenceBand('<70%', 8, NVColors.error),
  ];

  static const _timelineX = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'];
  static const _timelineY = [84.2, 85.1, 86.7, 87.4, 88.9, 89.6, 90.4, 91.2];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    final analysisProvider = Provider.of<AnalysisProvider>(context);
    final result = analysisProvider.result;

    return NVScaffold(
      currentRoute: '/dashboard/radiologist/explainability',
      role: AppConstants.roleRadiologist,
      title: 'Explainability Analysis',
      subtitle: 'Grad-CAM, attention weights & XAI visualization for AI predictions',
      userName: user?.name ?? 'Radiologist',
      roleColor: NVColors.radiologistColor,
      fadeAnimation: _fade,
      body: Column(
        children: [
          NVTopBar(
            title: 'Explainability Analysis',
            subtitle: 'Grad-CAM, attention weights & XAI visualization for AI predictions',
            user: user?.name ?? 'Radiologist',
            roleColor: NVColors.radiologistColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Live AI result banner
                  if (result != null)
                    _buildLiveResultBanner(result)
                  else
                    _buildNoResultBanner(),
                  const SizedBox(height: 16),
                  // Heatmap / XAI visualization
                  if (result?.heatmapBase64 != null)
                    _buildLiveHeatmapCard(result!),
                  if (result?.heatmapBase64 != null)
                    const SizedBox(height: 20),
                  _buildStatsRow(result),
                  const SizedBox(height: 20),
                  _buildTopRow(),
                  const SizedBox(height: 20),
                  _buildFeatureAttributionTable(),
                  const SizedBox(height: 20),
                  _buildBottomRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveResultBanner(dynamic result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NVColors.radiologistColor.withValues(alpha: 0.15),
            NVColors.radiologistColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NVColors.radiologistColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, color: NVColors.radiologistColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live Grad-CAM Explanation',
                    style: TextStyle(
                        color: NVColors.radiologistColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${result.prediction} · ${result.confidence.toStringAsFixed(1)}% confidence · ${result.modelUsed}',
                  style: const TextStyle(color: NVColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NVColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NVColors.success.withValues(alpha: 0.3)),
            ),
            child: const Text('Live',
                style: TextStyle(
                    color: NVColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NVColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NVColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: NVColors.textMuted, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Run an AI analysis first to see live Grad-CAM heatmaps here.',
              style: TextStyle(color: NVColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/analysis'),
            style: TextButton.styleFrom(
                foregroundColor: NVColors.radiologistColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            child: const Text('Run Analysis →', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHeatmapCard(dynamic result) {
    try {
      final bytes = base64Decode(result.heatmapBase64 as String);
      return NVGlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.whatshot_rounded,
                    color: NVColors.warning, size: 14),
                const SizedBox(width: 6),
                const Text('Grad-CAM Heatmap (Live)',
                    style: TextStyle(
                        color: NVColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  result.modelUsed as String,
                  style: const TextStyle(
                      color: NVColors.accent, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lesion segmentation mask — Red regions indicate AI-detected lesion areas',
              style: TextStyle(
                  color: NVColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 10),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow([dynamic result]) {
    final casesValue = result != null ? '1' : '156';
    final gradCamScore = result?.confidence != null
        ? (result!.confidence / 100.0).toStringAsFixed(3)
        : '0.847';
    final xaiRate = result?.confidence != null
        ? '${result!.confidence.toStringAsFixed(1)}%'
        : '91.2%';

    final card1 = NVStatCard(
      label: 'Cases Analyzed',
      value: casesValue,
      icon: Icons.visibility_rounded,
      color: NVColors.radiologistColor,
      trend: '+14',
      trendPositive: true,
    );
    final card2 = NVStatCard(
      label: 'Avg Grad-CAM Score',
      value: gradCamScore,
      icon: Icons.whatshot_rounded,
      color: NVColors.warning,
    );
    const card3 = NVStatCard(
      label: 'Attention Regions',
      value: '3.2 avg',
      icon: Icons.center_focus_strong_rounded,
      color: NVColors.info,
      subtitle: 'Per case',
    );
    final card4 = NVStatCard(
      label: 'XAI Validation Rate',
      value: xaiRate,
      icon: Icons.verified_rounded,
      color: NVColors.success,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
                const SizedBox(width: 12),
                Expanded(child: card3),
                const SizedBox(width: 12),
                Expanded(child: card4),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 12),
                    Expanded(child: card2),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: card3),
                    const SizedBox(width: 12),
                    Expanded(child: card4),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // ── Top row: Grad-CAM + Attention Weights ─────────────────────────────────
  Widget _buildTopRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildGradCamCard()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildAttentionWeightsCard()),
            ],
          );
        }
        return Column(
          children: [
            _buildGradCamCard(),
            const SizedBox(height: 20),
            _buildAttentionWeightsCard(),
          ],
        );
      },
    );
  }

  // ── Grad-CAM card ─────────────────────────────────────────────────────────
  Widget _buildGradCamCard() {
    final caseData = _cases[_selectedCase];
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.radiologistColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gradient_rounded,
                    color: NVColors.radiologistColor, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Grad-CAM Visualization',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),

          // Case selector chips
          const Text('Select Case',
              style: TextStyle(
                  color: NVColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_cases.length, (i) {
              final isSelected = i == _selectedCase;
              return GestureDetector(
                onTap: () => setState(() => _selectedCase = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NVColors.radiologistColor.withValues(alpha: 0.18)
                        : NVColors.bgDeep,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected
                            ? NVColors.radiologistColor
                            : NVColors.border),
                  ),
                  child: Text(
                    _cases[i].id,
                    style: TextStyle(
                      color: isSelected
                          ? NVColors.radiologistColor
                          : NVColors.textSecondary,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Method selector chips
          const Text('XAI Method',
              style: TextStyle(
                  color: NVColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_methods.length, (i) {
              final isSelected = i == _selectedMethod;
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NVColors.radiologistColor.withValues(alpha: 0.18)
                        : NVColors.bgDeep,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected
                            ? NVColors.radiologistColor
                            : NVColors.border),
                  ),
                  child: Text(
                    _methods[i],
                    style: TextStyle(
                      color: isSelected
                          ? NVColors.radiologistColor
                          : NVColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Grad-CAM viewer
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Black background
                  Container(color: Colors.black),
                  // Brain outline painter
                  CustomPaint(painter: _BrainOutlinePainter()),
                  // Heatmap overlay — main hotspot
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.15, 0.1),
                        radius: 0.38,
                        colors: [
                          NVColors.error.withValues(alpha: 0.65),
                          NVColors.warning.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Second smaller hotspot
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.3, 0.2),
                        radius: 0.15,
                        colors: [
                          NVColors.warning.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  // Badge: modality (top-left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _ViewerBadge(
                        label: caseData.modality,
                        color: NVColors.radiologistColor),
                  ),
                  // Badge: method (top-right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _ViewerBadge(
                        label: _methods[_selectedMethod],
                        color: NVColors.warning),
                  ),
                  // Bottom info bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        'AI: ${caseData.prediction} · ${caseData.confidence}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Color gradient legend
          Row(
            children: [
              const Text('Low',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // blue
                        Color(0xFF06B6D4), // cyan
                        Color(0xFF10B981), // green
                        Color(0xFFF59E0B), // yellow
                        Color(0xFFEF4444), // red
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('High',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Attention Weights card ────────────────────────────────────────────────
  Widget _buildAttentionWeightsCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.center_focus_strong_rounded,
                    color: NVColors.info, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attention Weights',
                        style: TextStyle(
                            color: NVColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text('6 brain regions',
                        style: TextStyle(
                            color: NVColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._regions.map((r) => _buildRegionBar(r)),
        ],
      ),
    );
  }

  Widget _buildRegionBar(_AttentionRegion region) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                region.name,
                style: const TextStyle(
                    color: NVColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                region.weight.toStringAsFixed(2),
                style: TextStyle(
                    color: region.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: region.weight,
              minHeight: 8,
              backgroundColor: NVColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(region.color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature Attribution Table ─────────────────────────────────────────────
  Widget _buildFeatureAttributionTable() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: NVColors.accent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Feature Attribution Analysis',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal scroll wrapper for mobile views
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 650,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: NVColors.bgDeep,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NVColors.border),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('Feature',
                                style: TextStyle(
                                    color: NVColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5))),
                        Expanded(
                            flex: 2,
                            child: Text('Attribution Score',
                                style: TextStyle(
                                    color: NVColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5))),
                        Expanded(
                            flex: 2,
                            child: Text('Contribution %',
                                style: TextStyle(
                                    color: NVColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5))),
                        Expanded(
                            flex: 2,
                            child: Text('Direction',
                                style: TextStyle(
                                    color: NVColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5))),
                        Expanded(
                            flex: 2,
                            child: Text('Significance',
                                style: TextStyle(
                                    color: NVColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Table rows
                  ..._features.asMap().entries.map((entry) =>
                      _buildFeatureRow(entry.value, entry.key.isEven)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_FeatureRow row, bool isEven) {
    final isPositive = row.direction == 'Positive';
    final dirColor = isPositive ? NVColors.success : NVColors.error;
    final sigColor = _significanceColor(row.significance);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isEven
            ? NVColors.bgCard.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NVColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Feature name
          Expanded(
            flex: 3,
            child: Text(
              row.feature,
              style: const TextStyle(
                  color: NVColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          // Attribution score
          Expanded(
            flex: 2,
            child: Text(
              row.attribution.toStringAsFixed(3),
              style: TextStyle(
                color: row.attribution >= 0
                    ? NVColors.radiologistColor
                    : NVColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Contribution %
          Expanded(
            flex: 2,
            child: Text(
              row.contribution,
              style: const TextStyle(
                  color: NVColors.textSecondary, fontSize: 12),
            ),
          ),
          // Direction
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: dirColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  row.direction,
                  style: TextStyle(
                      color: dirColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Significance badge
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sigColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sigColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                row.significance,
                style: TextStyle(
                    color: sigColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _significanceColor(String sig) {
    switch (sig) {
      case 'Critical':
        return NVColors.error;
      case 'High':
        return NVColors.warning;
      case 'Medium':
        return NVColors.info;
      case 'Low':
        return NVColors.textSecondary;
      default:
        return NVColors.textMuted;
    }
  }

  // ── Bottom row: Confidence Distribution + XAI Timeline ───────────────────
  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildConfidenceDistributionCard()),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _buildXAITimelineCard()),
            ],
          );
        }
        return Column(
          children: [
            _buildConfidenceDistributionCard(),
            const SizedBox(height: 20),
            _buildXAITimelineCard(),
          ],
        );
      },
    );
  }

  // ── Confidence Pie Chart ──────────────────────────────────────────────────
  Widget _buildConfidenceDistributionCard() {
    final total =
        _confidenceBands.fold<int>(0, (s, b) => s + b.count);

    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: NVColors.success, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Confidence Distribution',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: _confidenceBands.map((b) {
                  final pct = b.count / total;
                  return PieChartSectionData(
                    value: b.count.toDouble(),
                    color: b.color,
                    radius: 56,
                    showTitle: true,
                    title: '${(pct * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _confidenceBands.map((b) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: b.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${b.label} (${b.count})',
                    style: const TextStyle(
                        color: NVColors.textSecondary, fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── XAI Validation Timeline ───────────────────────────────────────────────
  Widget _buildXAITimelineCard() {
    final spots = List.generate(
      _timelineY.length,
      (i) => FlSpot(i.toDouble(), _timelineY[i]),
    );

    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NVColors.radiologistColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: NVColors.radiologistColor, size: 16),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('XAI Validation Timeline',
                      style: TextStyle(
                          color: NVColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text('Weekly validation score trend',
                      style: TextStyle(
                          color: NVColors.textMuted, fontSize: 11)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NVColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: NVColors.success.withValues(alpha: 0.4)),
                ),
                child: const Text('+7.0 pts',
                    style: TextStyle(
                        color: NVColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 82,
                maxY: 94,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: NVColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                            color: NVColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _timelineX.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _timelineX[idx],
                            style: const TextStyle(
                                color: NVColors.textMuted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: NVColors.radiologistColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: NVColors.radiologistColor,
                        strokeWidth: 2,
                        strokeColor: NVColors.bgCard,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          NVColors.radiologistColor.withValues(alpha: 0.22),
                          NVColors.radiologistColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        NVColors.bgCardHover,
                    tooltipBorder: const BorderSide(color: NVColors.border),
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(1)}%',
                              const TextStyle(
                                color: NVColors.radiologistColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painters
// ---------------------------------------------------------------------------

/// Draws a stylised brain outline with hemisphere divider and hemisphere arcs.
class _BrainOutlinePainter extends CustomPainter {
  const _BrainOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Outer brain oval
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy - 10),
          width: size.width * 0.68,
          height: size.height * 0.78),
      outerPaint,
    );

    // Medial fissure (vertical line)
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.34),
      Offset(cx, cy + size.height * 0.28),
      outerPaint..strokeWidth = 0.6,
    );

    // Left hemisphere sulci arcs
    final leftPath = Path()
      ..moveTo(cx - size.width * 0.15, cy - size.height * 0.25)
      ..quadraticBezierTo(cx - size.width * 0.28, cy - size.height * 0.05,
          cx - size.width * 0.18, cy + size.height * 0.12);
    canvas.drawPath(leftPath, innerPaint);

    final leftPath2 = Path()
      ..moveTo(cx - size.width * 0.08, cy - size.height * 0.3)
      ..quadraticBezierTo(cx - size.width * 0.22, cy - size.height * 0.15,
          cx - size.width * 0.25, cy + size.height * 0.05);
    canvas.drawPath(leftPath2, innerPaint);

    // Right hemisphere sulci arcs
    final rightPath = Path()
      ..moveTo(cx + size.width * 0.15, cy - size.height * 0.25)
      ..quadraticBezierTo(cx + size.width * 0.28, cy - size.height * 0.05,
          cx + size.width * 0.18, cy + size.height * 0.12);
    canvas.drawPath(rightPath, innerPaint);

    final rightPath2 = Path()
      ..moveTo(cx + size.width * 0.08, cy - size.height * 0.3)
      ..quadraticBezierTo(cx + size.width * 0.22, cy - size.height * 0.15,
          cx + size.width * 0.25, cy + size.height * 0.05);
    canvas.drawPath(rightPath2, innerPaint);

    // Cerebellum oval (bottom)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.31),
          width: size.width * 0.3,
          height: size.height * 0.14),
      outerPaint..strokeWidth = 1.0,
    );

    // Brain stem
    canvas.drawLine(
      Offset(cx, cy + size.height * 0.24),
      Offset(cx, cy + size.height * 0.38),
      outerPaint..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant _BrainOutlinePainter old) => false;
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _ViewerBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ViewerBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 0)
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
