// lib/src/ui/screens/dashboard/doctor/comparative_analysis_screen.dart
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

class _CompCase {
  final String id;
  final String label;
  final String date;
  final String prediction;
  final String confidence;
  final String severity;
  final String model;
  final String processingTime;

  const _CompCase({
    required this.id,
    required this.label,
    required this.date,
    required this.prediction,
    required this.confidence,
    required this.severity,
    required this.model,
    required this.processingTime,
  });
}

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

const _caseAOptions = <_CompCase>[
  _CompCase(
    id: 'CASE-2026-047',
    label: 'CASE-2026-047',
    date: 'Jan 2026',
    prediction: 'Ischemic',
    confidence: '88.7%',
    severity: 'High',
    model: 'DERNet v2.1',
    processingTime: '2.3 s',
  ),
  _CompCase(
    id: 'CASE-2026-046',
    label: 'CASE-2026-046',
    date: 'Jan 2026',
    prediction: 'Glioblastoma',
    confidence: '91.2%',
    severity: 'Critical',
    model: 'SegResNet',
    processingTime: '3.1 s',
  ),
  _CompCase(
    id: 'CASE-2026-045',
    label: 'CASE-2026-045',
    date: 'Jan 2026',
    prediction: 'Hemorrhage',
    confidence: '85.4%',
    severity: 'High',
    model: 'DERNet v2.1',
    processingTime: '2.8 s',
  ),
];

const _caseBOptions = <_CompCase>[
  _CompCase(
    id: 'CASE-2026-047-FU',
    label: 'CASE-2026-047 (Follow-up)',
    date: 'May 2026',
    prediction: 'Ischemic',
    confidence: '94.2%',
    severity: 'Medium',
    model: 'DERNet v2.1',
    processingTime: '2.1 s',
  ),
  _CompCase(
    id: 'CASE-2026-046-FU',
    label: 'CASE-2026-046 (Follow-up)',
    date: 'May 2026',
    prediction: 'Glioblastoma',
    confidence: '93.8%',
    severity: 'High',
    model: 'SegResNet',
    processingTime: '2.9 s',
  ),
];

// Lesion progression data: [Jan, Feb, Mar, Apr, May, Jun]
const _lesionVolumes = <double>[4.2, 4.5, 4.1, 3.8, 3.4, 3.1];
const _targetThreshold = <double>[3.0, 3.0, 3.0, 3.0, 3.0, 3.0];
const _monthLabels = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

// ---------------------------------------------------------------------------
// Main screen widget
// ---------------------------------------------------------------------------

class ComparativeAnalysisScreen extends StatefulWidget {
  const ComparativeAnalysisScreen({super.key});

  @override
  State<ComparativeAnalysisScreen> createState() =>
      _ComparativeAnalysisScreenState();
}

class _ComparativeAnalysisScreenState extends State<ComparativeAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  String _selectedCaseAId = _caseAOptions.first.id;
  String _selectedCaseBId = _caseBOptions.first.id;
  bool _comparisonActive = true;

  _CompCase get _caseA =>
      _caseAOptions.firstWhere((c) => c.id == _selectedCaseAId,
          orElse: () => _caseAOptions.first);

  _CompCase get _caseB =>
      _caseBOptions.firstWhere((c) => c.id == _selectedCaseBId,
          orElse: () => _caseBOptions.first);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return NVScaffold(
      currentRoute: '/dashboard/doctor/comparative',
      role: AppConstants.roleDoctor,
      title: 'Comparative Scan Analysis',
      subtitle: 'Multi-timepoint imaging comparison & progression tracking',
      userName: user?.name ?? 'Doctor',
      roleColor: NVColors.doctorColor,
      fadeAnimation: _fade,
      body: Column(
        children: [
          NVTopBar(
            title: 'Comparative Scan Analysis',
            subtitle: 'Multi-timepoint imaging comparison & progression tracking',
            user: user?.name ?? 'Doctor',
            roleColor: NVColors.doctorColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildCaseSelector(),
                  const SizedBox(height: 20),
                  _buildDualScanViewer(),
                  const SizedBox(height: 20),
                  _buildComparisonResultsGrid(),
                  const SizedBox(height: 20),
                  _buildDiagnosisTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Stats row
  // -------------------------------------------------------------------------

  Widget _buildStats() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final count = w > 800 ? 4 : w > 400 ? 2 : 1;
      final itemWidth = w / count;
      final ratio = w > 400 ? 1.6 : (itemWidth / 160.0);
      return GridView.count(
        crossAxisCount: count, crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: ratio, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: const [
          NVStatCard(
            label: 'Cases Compared',
            value: '34',
            icon: Icons.compare_rounded,
            color: NVColors.doctorColor,
            trend: '+8%',
            trendPositive: true,
          ),
          NVStatCard(
            label: 'Progression Detected',
            value: '12',
            icon: Icons.trending_up_rounded,
            color: NVColors.warning,
          ),
          NVStatCard(
            label: 'Improved Cases',
            value: '18',
            icon: Icons.trending_down_rounded,
            color: NVColors.success,
            subtitle: 'Lesion reduction',
          ),
          NVStatCard(
            label: 'Follow-Up Due',
            value: '6',
            icon: Icons.schedule_rounded,
            color: NVColors.info,
          ),
        ],
      );
    });
  }

  // -------------------------------------------------------------------------
  // Case selector
  // -------------------------------------------------------------------------

  Widget _buildCaseSelector() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Comparison Cases',
            style: TextStyle(
              color: NVColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: _buildDropdown(
                    label: 'Baseline Scan (Jan 2026)',
                    value: _selectedCaseAId,
                    items: _caseAOptions.map((c) => DropdownMenuItem(value: c.id, child: Text(c.label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NVColors.textPrimary, fontSize: 13)))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedCaseAId = v); },
                  )),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: NVColors.doctorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NVColors.doctorColor.withValues(alpha: 0.4)),
                    ),
                    child: const Text('VS', style: TextStyle(color: NVColors.doctorColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown(
                    label: 'Follow-up Scan (May 2026)',
                    value: _selectedCaseBId,
                    items: _caseBOptions.map((c) => DropdownMenuItem(value: c.id, child: Text(c.label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NVColors.textPrimary, fontSize: 13)))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _selectedCaseBId = v); },
                  )),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _comparisonActive = true),
                    icon: const Icon(Icons.compare_rounded, size: 16),
                    label: const Text('Compare'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NVColors.doctorColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDropdown(
                  label: 'Baseline Scan (Jan 2026)',
                  value: _selectedCaseAId,
                  items: _caseAOptions.map((c) => DropdownMenuItem(value: c.id, child: Text(c.label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NVColors.textPrimary, fontSize: 13)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedCaseAId = v); },
                ),
                const SizedBox(height: 10),
                _buildDropdown(
                  label: 'Follow-up Scan (May 2026)',
                  value: _selectedCaseBId,
                  items: _caseBOptions.map((c) => DropdownMenuItem(value: c.id, child: Text(c.label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NVColors.textPrimary, fontSize: 13)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedCaseBId = v); },
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () => setState(() => _comparisonActive = true),
                  icon: const Icon(Icons.compare_rounded, size: 16),
                  label: const Text('Compare'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.doctorColor, foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                )),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: NVColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: NVColors.bgDeep,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NVColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: NVColors.bgCard,
              iconEnabledColor: NVColors.textMuted,
              style: const TextStyle(color: NVColors.textPrimary, fontSize: 13),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Dual scan viewer
  // -------------------------------------------------------------------------

  Widget _buildDualScanViewer() {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          // Scan A panel
          Expanded(child: _ScanPanel(
            label: 'Scan A – Jan 2026',
            caseLabel: _caseA.id,
            prediction: _caseA.prediction,
            confidence: _caseA.confidence,
            gradientColors: [
              const Color(0xFF0D1B2A),
              const Color(0xFF1A2A40),
              Colors.black,
            ],
            gradientCenter: const Alignment(-0.3, -0.2),
            heatmapColor: NVColors.warning,
            heatmapAlpha: 0.3,
            role: 'baseline',
          )),

          // VS divider
          _VsDivider(),

          // Scan B panel
          Expanded(child: _ScanPanel(
            label: 'Scan B – May 2026',
            caseLabel: _caseB.id,
            prediction: _caseB.prediction,
            confidence: _caseB.confidence,
            gradientColors: [
              const Color(0xFF0A1A10),
              const Color(0xFF152B1E),
              Colors.black,
            ],
            gradientCenter: const Alignment(0.2, -0.1),
            heatmapColor: NVColors.success,
            heatmapAlpha: 0.18,
            role: 'followup',
          )),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Comparison results grid
  // -------------------------------------------------------------------------

  Widget _buildComparisonResultsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 650;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildLesionVolumeCard(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildChangeSummaryCard(),
            ),
          ],
        );
      }
      return Column(children: [
        _buildLesionVolumeCard(),
        const SizedBox(height: 16),
        _buildChangeSummaryCard(),
      ]);
    });
  }

  Widget _buildLesionVolumeCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NVColors.doctorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.show_chart_rounded, color: NVColors.doctorColor, size: 16),
            ),
            const Text('Lesion Volume Progression', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            _LegendDot(color: NVColors.doctorColor, label: 'Volume (cm³)'),
            _LegendDot(color: NVColors.success, label: 'Target', dashed: true),
          ]),
          const SizedBox(height: 8),
          const Text('Y axis: cm³', style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _buildLesionChart()),
        ],
      ),
    );
  }

  Widget _buildChangeSummaryCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NVColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.compare_arrows_rounded, color: NVColors.success, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Change Summary', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 20),
          _buildChangeSummary(),
        ],
      ),
    );
  }

  Widget _buildLesionChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: NVColors.border,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _monthLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_monthLabels[idx],
                      style: const TextStyle(
                          color: NVColors.textMuted, fontSize: 10)),
                );
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 1,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style:
                    const TextStyle(color: NVColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 2,
        maxY: 5,
        lineBarsData: [
          // Lesion volume line (solid, doctorColor)
          LineChartBarData(
            spots: List.generate(_lesionVolumes.length,
                (i) => FlSpot(i.toDouble(), _lesionVolumes[i])),
            isCurved: true,
            color: NVColors.doctorColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3.5,
                color: NVColors.doctorColor,
                strokeWidth: 1.5,
                strokeColor: NVColors.bgCard,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NVColors.doctorColor.withValues(alpha: 0.25),
                  NVColors.doctorColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Target threshold line (dashed, success)
          LineChartBarData(
            spots: List.generate(_targetThreshold.length,
                (i) => FlSpot(i.toDouble(), _targetThreshold[i])),
            isCurved: false,
            color: NVColors.success,
            barWidth: 1.5,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            dashArray: [6, 4],
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => NVColors.bgCard,
            getTooltipItems: (spots) => spots.map((s) {
              final isVolume = s.barIndex == 0;
              return LineTooltipItem(
                isVolume
                    ? '${s.y.toStringAsFixed(1)} cm³'
                    : 'Target: ${s.y.toStringAsFixed(1)}',
                TextStyle(
                  color: isVolume ? NVColors.doctorColor : NVColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChangeSummary() {
    const metrics = <_MetricChange>[
      _MetricChange(
          label: 'Lesion Volume',
          before: '4.2 cm³',
          after: '3.1 cm³',
          improved: true),
      _MetricChange(
          label: 'AI Confidence',
          before: '88.7%',
          after: '94.2%',
          improved: true,
          higherIsBetter: true),
      _MetricChange(
          label: 'Severity',
          before: 'High',
          after: 'Medium',
          improved: true),
      _MetricChange(
          label: 'Prediction',
          before: 'Ischemic',
          after: 'Ischemic',
          improved: null),
    ];
    return Column(
      children: metrics
          .map((m) => _MetricChangeRow(metric: m))
          .toList(),
    );
  }

  // -------------------------------------------------------------------------
  // AI Diagnosis Comparison table
  // -------------------------------------------------------------------------

  Widget _buildDiagnosisTable() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NVColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: NVColors.secondary, size: 16),
            ),
            const Text(
              'AI Diagnosis Comparison',
              style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NVColors.doctorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: NVColors.doctorColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${_caseA.id}  →  ${_caseB.id}',
                style: const TextStyle(
                    color: NVColors.doctorColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildTableHeader(),
          const Divider(color: NVColors.border, height: 1),
          _buildTableRow(
            parameter: 'Prediction',
            baseline: _caseA.prediction,
            followup: _caseB.prediction,
            change: 'No change',
            status: _TableStatus.stable,
          ),
          _buildTableRow(
            parameter: 'Confidence',
            baseline: _caseA.confidence,
            followup: _caseB.confidence,
            change: '+5.5%',
            status: _TableStatus.improved,
          ),
          _buildTableRow(
            parameter: 'Severity',
            baseline: _caseA.severity,
            followup: _caseB.severity,
            change: '↓ 1 level',
            status: _TableStatus.improved,
          ),
          _buildTableRow(
            parameter: 'Model',
            baseline: _caseA.model,
            followup: _caseB.model,
            change: 'Same',
            status: _TableStatus.stable,
          ),
          _buildTableRow(
            parameter: 'Processing Time',
            baseline: _caseA.processingTime,
            followup: _caseB.processingTime,
            change: '−0.2 s',
            status: _TableStatus.improved,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const headers = [
      'Parameter',
      'Baseline',
      'Follow-up',
      'Change',
      'Status',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: headers.map((h) {
          return Expanded(
            child: Text(h,
                style: const TextStyle(
                    color: NVColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow({
    required String parameter,
    required String baseline,
    required String followup,
    required String change,
    required _TableStatus status,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(parameter,
                    style: const TextStyle(
                        color: NVColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Text(baseline,
                    style: const TextStyle(
                        color: NVColors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Text(followup,
                    style: const TextStyle(
                        color: NVColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(change,
                    style: TextStyle(
                        color: _changeColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: _StatusBadge(status: status),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(color: NVColors.border, height: 1),
      ],
    );
  }

  Color _changeColor(_TableStatus s) {
    switch (s) {
      case _TableStatus.improved:
        return NVColors.success;
      case _TableStatus.worsened:
        return NVColors.error;
      case _TableStatus.stable:
        return NVColors.textMuted;
    }
  }
}

// ---------------------------------------------------------------------------
// Supporting enums & data classes
// ---------------------------------------------------------------------------

enum _TableStatus { improved, stable, worsened }

class _MetricChange {
  final String label;
  final String before;
  final String after;
  /// null = neutral/same
  final bool? improved;
  final bool higherIsBetter;

  const _MetricChange({
    required this.label,
    required this.before,
    required this.after,
    required this.improved,
    this.higherIsBetter = false,
  });
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ScanPanel extends StatelessWidget {
  final String label;
  final String caseLabel;
  final String prediction;
  final String confidence;
  final List<Color> gradientColors;
  final Alignment gradientCenter;
  final Color heatmapColor;
  final double heatmapAlpha;
  final String role;

  const _ScanPanel({
    required this.label,
    required this.caseLabel,
    required this.prediction,
    required this.confidence,
    required this.gradientColors,
    required this.gradientCenter,
    required this.heatmapColor,
    required this.heatmapAlpha,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return NVGlassCard(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Simulated MRI gradient background
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: gradientCenter,
                  radius: 0.75,
                  colors: gradientColors,
                ),
              ),
            ),
            // Brain outline painter
            CustomPaint(painter: _BrainOutlinePainter(role: role)),
            // Heatmap overlay
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: gradientCenter,
                  radius: 0.32,
                  colors: [
                    heatmapColor.withValues(alpha: heatmapAlpha),
                    heatmapColor.withValues(alpha: heatmapAlpha * 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Top label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            // Case ID badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NVColors.doctorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: NVColors.doctorColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  caseLabel,
                  style: const TextStyle(
                      color: NVColors.doctorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // Scan tools row
            Positioned(
              bottom: 44,
              right: 12,
              child: Row(
                children: [
                  _IconTool(icon: Icons.zoom_in_rounded),
                  const SizedBox(width: 5),
                  _IconTool(icon: Icons.brightness_6_rounded),
                  const SizedBox(width: 5),
                  _IconTool(icon: Icons.fullscreen_rounded),
                ],
              ),
            ),
            // Bottom AI prediction bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded,
                        color: NVColors.doctorColor, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'AI: $prediction',
                        style: const TextStyle(
                            color: NVColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: NVColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        confidence,
                        style: const TextStyle(
                            color: NVColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 1,
            color: NVColors.border,
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: NVColors.bgCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: NVColors.borderBright),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                  color: NVColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChangeRow extends StatelessWidget {
  final _MetricChange metric;
  const _MetricChangeRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final Color arrowColor;
    final IconData arrowIcon;

    if (metric.improved == null) {
      arrowColor = NVColors.textMuted;
      arrowIcon = Icons.remove_rounded;
    } else if (metric.improved!) {
      arrowColor = NVColors.success;
      arrowIcon = metric.higherIsBetter
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
    } else {
      arrowColor = NVColors.error;
      arrowIcon = metric.higherIsBetter
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(metric.label,
                style: const TextStyle(
                    color: NVColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(metric.before,
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 12)),
          ),
          Icon(arrowIcon, color: arrowColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(metric.after,
                style: TextStyle(
                    color: arrowColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _TableStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case _TableStatus.improved:
        color = NVColors.success;
        label = 'Improved';
        break;
      case _TableStatus.worsened:
        color = NVColors.error;
        label = 'Worsened';
        break;
      case _TableStatus.stable:
        color = NVColors.info;
        label = 'Stable';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 2.5,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
            border: dashed ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: NVColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _IconTool extends StatelessWidget {
  final IconData icon;
  const _IconTool({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: Colors.white70, size: 14),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painters
// ---------------------------------------------------------------------------

class _BrainOutlinePainter extends CustomPainter {
  final String role;
  const _BrainOutlinePainter({required this.role});

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final hemPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width * 0.5;
    final cy = size.height * 0.44;

    // Outer brain oval
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.56,
          height: size.height * 0.70),
      outlinePaint,
    );

    // Midline fissure
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.35),
      Offset(cx, cy + size.height * 0.35),
      outlinePaint..strokeWidth = 0.7,
    );

    // Left hemisphere gyrus curves
    final path1 = Path()
      ..moveTo(cx - size.width * 0.12, cy - size.height * 0.22)
      ..cubicTo(
          cx - size.width * 0.22,
          cy - size.height * 0.12,
          cx - size.width * 0.18,
          cy + size.height * 0.05,
          cx - size.width * 0.09,
          cy + size.height * 0.18);
    canvas.drawPath(path1, hemPaint);

    // Right hemisphere gyrus curves
    final path2 = Path()
      ..moveTo(cx + size.width * 0.10, cy - size.height * 0.20)
      ..cubicTo(
          cx + size.width * 0.20,
          cy - size.height * 0.10,
          cx + size.width * 0.16,
          cy + size.height * 0.06,
          cx + size.width * 0.08,
          cy + size.height * 0.16);
    canvas.drawPath(path2, hemPaint);

    // Lesion ellipse — slightly different position per role
    final lesionOffset = role == 'baseline'
        ? Offset(cx - size.width * 0.1, cy - size.height * 0.08)
        : Offset(cx - size.width * 0.08, cy - size.height * 0.07);
    final lesionColor = role == 'baseline' ? NVColors.warning : NVColors.success;
    final lesionRadius = role == 'baseline' ? 18.0 : 13.0;

    final lesionFill = Paint()
      ..color = lesionColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final lesionBorder = Paint()
      ..color = lesionColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
        Rect.fromCenter(
            center: lesionOffset, width: lesionRadius * 2, height: lesionRadius * 1.3),
        lesionFill);
    canvas.drawOval(
        Rect.fromCenter(
            center: lesionOffset, width: lesionRadius * 2, height: lesionRadius * 1.3),
        lesionBorder);

    // Pointer line from lesion
    canvas.drawLine(
      Offset(lesionOffset.dx + lesionRadius, lesionOffset.dy),
      Offset(lesionOffset.dx + lesionRadius + 30, lesionOffset.dy - 18),
      Paint()
        ..color = lesionColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BrainOutlinePainter old) =>
      old.role != role;
}
