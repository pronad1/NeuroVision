// lib/src/ui/screens/dashboard/radiologist/lesion_localization_screen.dart
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

// ─── Data model ─────────────────────────────────────────────────────────────

class _LesionItem {
  final String id;
  final String location;
  final String? aiSize;
  final String? radSize;
  final double diceScore;
  final String matchStatus; // 'Match' | 'FP' | 'FN'

  const _LesionItem({
    required this.id,
    required this.location,
    this.aiSize,
    this.radSize,
    required this.diceScore,
    required this.matchStatus,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class LesionLocalizationScreen extends StatefulWidget {
  const LesionLocalizationScreen({super.key});

  @override
  State<LesionLocalizationScreen> createState() =>
      _LesionLocalizationScreenState();
}

class _LesionLocalizationScreenState extends State<LesionLocalizationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  int _selectedCase = 0;

  static const _caseLabels = [
    'CASE-2026-047',
    'CASE-2026-046',
    'CASE-2026-045',
    'CASE-2026-044',
    'CASE-2026-043',
  ];

  static const _lesions = [
    _LesionItem(
        id: 'L-001',
        location: 'Left Frontal',
        aiSize: '14.2mm',
        radSize: '15.1mm',
        diceScore: 0.91,
        matchStatus: 'Match'),
    _LesionItem(
        id: 'L-002',
        location: 'Right Parietal',
        aiSize: '8.7mm',
        radSize: '9.2mm',
        diceScore: 0.88,
        matchStatus: 'Match'),
    _LesionItem(
        id: 'L-003',
        location: 'Temporal',
        aiSize: '22.4mm',
        radSize: '20.8mm',
        diceScore: 0.85,
        matchStatus: 'Match'),
    _LesionItem(
        id: 'L-004',
        location: 'Cerebellar',
        aiSize: '3.1mm',
        radSize: null,
        diceScore: 0.0,
        matchStatus: 'FP'),
    _LesionItem(
        id: 'L-005',
        location: 'Occipital',
        aiSize: '18.9mm',
        radSize: '17.6mm',
        diceScore: 0.82,
        matchStatus: 'Match'),
    _LesionItem(
        id: 'L-006',
        location: 'Basal Ganglia',
        aiSize: null,
        radSize: '5.3mm',
        diceScore: 0.0,
        matchStatus: 'FN'),
  ];

  static const _regionLabels = [
    'Frontal',
    'Parietal',
    'Temporal',
    'Occipital',
    'Cerebellar',
    'Basal G.',
  ];
  static const _regionValues = [92.0, 89.0, 87.0, 85.0, 78.0, 71.0];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Row(
        children: [
          NVSidebar(
            currentRoute: '/dashboard/radiologist/lesions',
            role: AppConstants.roleRadiologist,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  NVTopBar(
                    title: 'Lesion Localization',
                    subtitle:
                        'AI vs Radiologist spatial comparison & overlap analysis',
                    user: user?.name ?? 'Radiologist',
                    roleColor: NVColors.radiologistColor,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stat cards ───────────────────────────────
                          _buildStatRow(),
                          const SizedBox(height: 20),
                          // ── Top row: scan viewer + lesion registry ───
                          _buildTopRow(),
                          const SizedBox(height: 20),
                          // ── Bottom: bar chart ────────────────────────
                          _buildBarChartCard(),
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

  // ── Stat row ─────────────────────────────────────────────────────────────

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(
          child: NVStatCard(
            label: 'Lesions Detected',
            value: '47',
            icon: Icons.location_on_rounded,
            color: NVColors.radiologistColor,
            trend: '+5',
            trendPositive: true,
            subtitle: 'This week',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NVStatCard(
            label: 'AI Agreement',
            value: '89.4%',
            icon: Icons.handshake_rounded,
            color: NVColors.success,
            trend: '+2.1%',
            trendPositive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NVStatCard(
            label: 'False Positives',
            value: '4',
            icon: Icons.cancel_rounded,
            color: NVColors.error,
            subtitle: 'AI overcalls',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NVStatCard(
            label: 'Avg Dice Score',
            value: '0.873',
            icon: Icons.calculate_rounded,
            color: NVColors.warning,
          ),
        ),
      ],
    );
  }

  // ── Top row (scan viewer + lesion registry) ───────────────────────────────

  Widget _buildTopRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 900;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildScanCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildLesionRegistry()),
          ],
        );
      }
      return Column(
        children: [
          _buildScanCard(),
          const SizedBox(height: 16),
          _buildLesionRegistry(),
        ],
      );
    });
  }

  // ── Spatial localization card ─────────────────────────────────────────────

  Widget _buildScanCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.center_focus_strong_rounded,
                  color: NVColors.radiologistColor, size: 16),
              const SizedBox(width: 8),
              const Text('Spatial Localization Comparison',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: NVColors.radiologistColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: NVColors.radiologistColor.withValues(alpha: 0.4)),
                ),
                child: Text(_caseLabels[_selectedCase],
                    style: const TextStyle(
                        color: NVColors.radiologistColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Case selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_caseLabels.length, (i) {
                final active = i == _selectedCase;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCase = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? NVColors.radiologistColor.withValues(alpha: 0.18)
                            : NVColors.bgDeep,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? NVColors.radiologistColor
                              : NVColors.border,
                        ),
                      ),
                      child: Text(
                        _caseLabels[i],
                        style: TextStyle(
                          color: active
                              ? NVColors.radiologistColor
                              : NVColors.textMuted,
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          // Dual scan views
          Row(
            children: [
              Expanded(child: _buildScanView(isAI: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildScanView(isAI: false)),
            ],
          ),
          const SizedBox(height: 16),
          // Dice score display
          _buildDiceDisplay(),
        ],
      ),
    );
  }

  Widget _buildScanView({required bool isAI}) {
    final label = isAI ? 'AI Detection' : 'Radiologist Mark';
    final labelColor =
        isAI ? NVColors.error : NVColors.radiologistColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: labelColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        // Scan canvas
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NVColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Background gradient simulating MRI scan
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 0.75,
                      colors: [
                        const Color(0xFF1a1a2e).withValues(alpha: 0.95),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
                // Heatmap overlay
                if (isAI)
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                            0.15 + _selectedCase * 0.04,
                            -0.1 + _selectedCase * 0.03),
                        radius: 0.28,
                        colors: [
                          NVColors.error.withValues(alpha: 0.22),
                          NVColors.warning.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                // Brain + bounding box painter
                CustomPaint(
                  painter: _BrainScanPainter(
                    isAI: isAI,
                    caseIndex: _selectedCase,
                  ),
                  size: Size.infinite,
                ),
                // Corner label badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: labelColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: labelColor, fontSize: 9)),
                  ),
                ),
                // Slice info badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Axial · Slice 42',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 9)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiceDisplay() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NVColors.border),
      ),
      child: Row(
        children: [
          // Big Dice score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '0.873',
                style: const TextStyle(
                  color: NVColors.radiologistColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Text('Overlap Score (Dice)',
                  style:
                      TextStyle(color: NVColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 20),
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Spatial Agreement',
                        style: TextStyle(
                            color: NVColors.textSecondary, fontSize: 11)),
                    const Text('87.3%',
                        style: TextStyle(
                            color: NVColors.radiologistColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.873,
                    backgroundColor: NVColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        NVColors.radiologistColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _diceLegend(NVColors.success, 'Excellent (>0.9)'),
                    const SizedBox(width: 12),
                    _diceLegend(NVColors.radiologistColor, 'Good (>0.8)'),
                    const SizedBox(width: 12),
                    _diceLegend(NVColors.warning, 'Fair (>0.7)'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diceLegend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: NVColors.textMuted, fontSize: 9)),
      ],
    );
  }

  // ── Lesion registry card ──────────────────────────────────────────────────

  Widget _buildLesionRegistry() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.list_alt_rounded,
                  color: NVColors.radiologistColor, size: 16),
              const SizedBox(width: 8),
              const Text('Lesion Registry',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: NVColors.radiologistColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_lesions.length} found',
                    style: const TextStyle(
                        color: NVColors.radiologistColor, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: const [
                SizedBox(width: 80, child: Text('ID / Region', style: TextStyle(color: NVColors.textMuted, fontSize: 10))),
                Expanded(child: Text('AI · Rad', style: TextStyle(color: NVColors.textMuted, fontSize: 10))),
                SizedBox(width: 60, child: Text('Dice', style: TextStyle(color: NVColors.textMuted, fontSize: 10))),
                SizedBox(width: 44, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(color: NVColors.textMuted, fontSize: 10))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: NVColors.border, height: 1),
          const SizedBox(height: 6),
          // Lesion rows
          ..._lesions.map((l) => _buildLesionRow(l)),
        ],
      ),
    );
  }

  Widget _buildLesionRow(_LesionItem l) {
    final statusColor = l.matchStatus == 'Match'
        ? NVColors.success
        : l.matchStatus == 'FP'
            ? NVColors.error
            : NVColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ID + location
          SizedBox(
            width: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 3, right: 6),
                  decoration: BoxDecoration(
                      color: statusColor, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.id,
                          style: const TextStyle(
                              color: NVColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      Text(l.location,
                          style: const TextStyle(
                              color: NVColors.textMuted, fontSize: 9),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // AI · Rad sizes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.memory_rounded,
                      color: NVColors.error, size: 10),
                  const SizedBox(width: 3),
                  Text(l.aiSize ?? '—',
                      style: TextStyle(
                          color: l.aiSize != null
                              ? NVColors.textSecondary
                              : NVColors.textMuted,
                          fontSize: 10)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.person_rounded,
                      color: NVColors.radiologistColor, size: 10),
                  const SizedBox(width: 3),
                  Text(l.radSize ?? '—',
                      style: TextStyle(
                          color: l.radSize != null
                              ? NVColors.textSecondary
                              : NVColors.textMuted,
                          fontSize: 10)),
                ]),
              ],
            ),
          ),
          // Dice bar
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.diceScore > 0 ? l.diceScore.toStringAsFixed(2) : '—',
                  style: TextStyle(
                      color: l.diceScore > 0
                          ? NVColors.radiologistColor
                          : NVColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: l.diceScore,
                    backgroundColor: NVColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        l.diceScore >= 0.9
                            ? NVColors.success
                            : l.diceScore >= 0.8
                                ? NVColors.radiologistColor
                                : NVColors.warning),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          SizedBox(
            width: 44,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  l.matchStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart card ────────────────────────────────────────────────────────

  Widget _buildBarChartCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: NVColors.radiologistColor, size: 16),
              const SizedBox(width: 8),
              const Text('Localization Accuracy by Brain Region',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const Spacer(),
              _buildLegendChip(NVColors.success, '>85%'),
              const SizedBox(width: 8),
              _buildLegendChip(NVColors.radiologistColor, '>75%'),
              const SizedBox(width: 8),
              _buildLegendChip(NVColors.warning, '≤75%'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_regionLabels[groupIndex]}\n${rod.toY.toInt()}%',
                        const TextStyle(
                            color: NVColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _regionLabels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_regionLabels[idx],
                              style: const TextStyle(
                                  color: NVColors.textMuted, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        if (value % 25 != 0) return const SizedBox();
                        return Text('${value.toInt()}%',
                            style: const TextStyle(
                                color: NVColors.textMuted, fontSize: 9));
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: NVColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_regionValues.length, (i) {
                  final v = _regionValues[i];
                  final color = v > 85
                      ? NVColors.success
                      : v > 75
                          ? NVColors.radiologistColor
                          : NVColors.warning;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        color: color,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: color.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Summary row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NVColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NVColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryStat('Best Region', 'Frontal', NVColors.success),
                _divider(),
                _summaryStat('Avg Agreement', '83.7%', NVColors.radiologistColor),
                _divider(),
                _summaryStat('Lowest', 'Basal G.', NVColors.warning),
                _divider(),
                _summaryStat('Above 85%', '4 / 6', NVColors.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: NVColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: NVColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 30, color: NVColors.border);
  }
}

// ─── Brain scan CustomPainter ────────────────────────────────────────────────

class _BrainScanPainter extends CustomPainter {
  final bool isAI;
  final int caseIndex;

  const _BrainScanPainter({required this.isAI, required this.caseIndex});

  // Per-case bounding box offsets (normalised 0-1 fractions of size)
  static const _aiBoxes = [
    [0.32, 0.22, 0.38, 0.30],
    [0.52, 0.28, 0.36, 0.28],
    [0.42, 0.38, 0.32, 0.26],
    [0.28, 0.45, 0.30, 0.24],
    [0.55, 0.42, 0.34, 0.28],
  ];
  static const _radBoxes = [
    [0.30, 0.21, 0.40, 0.32],
    [0.54, 0.27, 0.34, 0.30],
    [0.44, 0.36, 0.34, 0.28],
    [0.27, 0.43, 0.32, 0.26],
    [0.53, 0.40, 0.36, 0.30],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;

    // ── Brain outer shape ────────────────────────────────────────────────
    final brainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer ellipse
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.62,
          height: size.height * 0.72),
      brainPaint,
    );

    // Midline fissure
    final midlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(cx, cy - size.height * 0.33),
        Offset(cx, cy + size.height * 0.33),
        midlinePaint);

    // Gyri suggestion lines
    final gyriPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var i = 0; i < 4; i++) {
      final yOff = (i - 1.5) * size.height * 0.12;
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx - size.width * 0.06, cy + yOff),
            width: size.width * 0.38,
            height: size.height * 0.14),
        0.4,
        2.4,
        false,
        gyriPaint,
      );
    }

    // Lateral ventricle hints
    final ventPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - 12, cy),
            width: size.width * 0.12,
            height: size.height * 0.18),
        ventPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + 12, cy),
            width: size.width * 0.12,
            height: size.height * 0.18),
        ventPaint);

    // ── Bounding box ─────────────────────────────────────────────────────
    final boxes = isAI ? _aiBoxes : _radBoxes;
    final b = boxes[caseIndex.clamp(0, boxes.length - 1)];
    final rect = Rect.fromLTWH(
      b[0] * size.width,
      b[1] * size.height,
      b[2] * size.width,
      b[3] * size.height,
    );

    final boxColor = isAI ? NVColors.error : NVColors.radiologistColor;

    // Fill
    canvas.drawRect(
      rect,
      Paint()
        ..color = boxColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );

    if (isAI) {
      // Dashed outline for AI
      _drawDashedRect(canvas, rect, boxColor);
    } else {
      // Solid outline for radiologist
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Corner handles
    _drawCornerHandle(canvas, rect.topLeft, boxColor, isAI);
    _drawCornerHandle(canvas, rect.topRight, boxColor, isAI);
    _drawCornerHandle(canvas, rect.bottomLeft, boxColor, isAI);
    _drawCornerHandle(canvas, rect.bottomRight, boxColor, isAI);

    // Center cross-hair
    final crossPaint = Paint()
      ..color = boxColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;
    final ctrX = rect.center.dx;
    final ctrY = rect.center.dy;
    canvas.drawLine(Offset(ctrX - 8, ctrY), Offset(ctrX + 8, ctrY), crossPaint);
    canvas.drawLine(Offset(ctrX, ctrY - 8), Offset(ctrX, ctrY + 8), crossPaint);

    // Label above box
    _drawBoxLabel(canvas, rect, isAI ? 'AI ROI' : 'RAD ROI', boxColor);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Color color) {
    const dashLen = 5.0;
    const gapLen = 3.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    void drawDashedLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = (end - start).distance;
      final unitX = dx / length;
      final unitY = dy / length;
      double d = 0;
      bool drawing = true;
      while (d < length) {
        final segEnd = (d + (drawing ? dashLen : gapLen)).clamp(0, length);
        if (drawing) {
          canvas.drawLine(
            Offset(start.dx + unitX * d, start.dy + unitY * d),
            Offset(start.dx + unitX * segEnd, start.dy + unitY * segEnd),
            paint,
          );
        }
        d += drawing ? dashLen : gapLen;
        drawing = !drawing;
      }
    }

    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomRight, rect.bottomLeft);
    drawDashedLine(rect.bottomLeft, rect.topLeft);
  }

  void _drawCornerHandle(
      Canvas canvas, Offset pos, Color color, bool isAI) {
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(pos, isAI ? 3.5 : 4, fill);
    canvas.drawCircle(pos, isAI ? 3.5 : 4, stroke);
  }

  void _drawBoxLabel(Canvas canvas, Rect rect, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, rect.topLeft + const Offset(0, -14));
  }

  @override
  bool shouldRepaint(covariant _BrainScanPainter old) =>
      old.isAI != isAI || old.caseIndex != caseIndex;
}
