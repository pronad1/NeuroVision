// lib/src/ui/screens/dashboard/researcher/metrics_screen.dart
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
// Route constant
// ---------------------------------------------------------------------------
class MetricsScreen extends StatefulWidget {
  static const String routeName = '/dashboard/researcher/metrics';

  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class _MetricsScreenState extends State<MetricsScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  // ── Selector state ─────────────────────────────────────────────────────────
  String _selectedModel = 'DERNet v2.1';
  String _selectedDataset = 'Brain MRI Test Set';

  // ── Static mock data ────────────────────────────────────────────────────────
  static const _models = [
    'DERNet v2.1',
    'SegResNet',
    'EfficientNetV2',
    'Attention U-Net',
  ];

  static const _datasets = [
    'Brain MRI Test Set',
    'Spine MRI Test Set',
  ];

  static const _classes = ['Normal', 'Ischemic', 'Glioblastoma', 'Hemorrhage'];

  static const _precision = [0.97, 0.94, 0.96, 0.91];
  static const _recall = [0.95, 0.93, 0.94, 0.89];
  static const _f1 = [0.960, 0.935, 0.950, 0.900];

  // Table data: [class, TP, FP, FN, TN, precision, recall, f1, support]
  static const _tableRows = [
    ['Normal', '142', '7', '8', '843', '0.953', '0.947', '0.950', '150'],
    ['Ischemic Stroke', '187', '11', '13', '789', '0.944', '0.935', '0.939', '200'],
    ['Glioblastoma', '94', '4', '6', '896', '0.959', '0.940', '0.949', '100'],
    ['Hemorrhage', '71', '7', '9', '913', '0.910', '0.887', '0.898', '80'],
  ];

  // ROC curve data (FPR, TPR) per class
  static const _rocCurves = [
    // Normal
    [[0.0, 0.0], [0.03, 0.82], [0.1, 0.93], [0.3, 0.97], [1.0, 1.0]],
    // Ischemic
    [[0.0, 0.0], [0.05, 0.72], [0.15, 0.88], [0.4, 0.95], [1.0, 1.0]],
    // Glioblastoma
    [[0.0, 0.0], [0.04, 0.78], [0.12, 0.91], [0.35, 0.96], [1.0, 1.0]],
    // Hemorrhage
    [[0.0, 0.0], [0.07, 0.65], [0.18, 0.83], [0.45, 0.92], [1.0, 1.0]],
  ];

  static const _aucValues = [0.987, 0.962, 0.974, 0.941];

  static const _rocColors = [
    NVColors.success,
    NVColors.researcherColor,
    NVColors.info,
    NVColors.error,
  ];

  // PR curve points (recall, precision)
  static const _prCurve = [
    [0.0, 1.0], [0.2, 0.98], [0.4, 0.97],
    [0.6, 0.95], [0.8, 0.91], [0.9, 0.88], [1.0, 0.84],
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<NVAuthProvider>();
    final userName = auth.nvUser?.name ?? 'Researcher';

    return NVScaffold(
      currentRoute: MetricsScreen.routeName,
      role: AppConstants.roleResearcher,
      title: 'Performance Metrics',
      subtitle: 'Detailed precision, recall, F1-score & AUC-ROC analysis per class',
      userName: userName,
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'Performance Metrics',
            subtitle: 'Detailed precision, recall, F1-score & AUC-ROC analysis per class',
            user: userName,
            roleColor: NVColors.researcherColor,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(),
                    const SizedBox(height: 20),
                    _buildSelectorCard(),
                    const SizedBox(height: 20),
                    _buildPerClassCharts(),
                    const SizedBox(height: 20),
                    _buildMetricsTable(),
                    const SizedBox(height: 20),
                    _buildCurveRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // 1 ─ Stat row
  // ---------------------------------------------------------------------------
  Widget _buildStatRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final count = constraints.maxWidth > 700 ? 4 : 2;
      return GridView.count(
        crossAxisCount: count,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: constraints.maxWidth > 700 ? 1.7 : 1.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          NVStatCard(
            label: 'Avg Precision',
            value: '0.941',
            icon: Icons.precision_manufacturing_rounded,
            color: NVColors.researcherColor,
            trend: '+0.009',
            trendPositive: true,
          ),
          NVStatCard(
            label: 'Avg Recall',
            value: '0.928',
            icon: Icons.manage_search_rounded,
            color: NVColors.success,
          ),
          NVStatCard(
            label: 'Macro F1',
            value: '0.934',
            icon: Icons.star_rounded,
            color: NVColors.warning,
            trend: '+0.008',
            trendPositive: true,
          ),
          NVStatCard(
            label: 'Best AUC-ROC',
            value: '0.987',
            icon: Icons.show_chart_rounded,
            color: NVColors.info,
            subtitle: 'DERNet v2.1',
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // 2 ─ Selector card
  // ---------------------------------------------------------------------------
  Widget _buildSelectorCard() {
    const labelStyle = TextStyle(
      color: NVColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    Widget dropdown<T>({
      required T value,
      required List<T> items,
      required ValueChanged<T?> onChanged,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: NVColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NVColors.borderBright),
        ),
        child: DropdownButton<T>(
          value: value,
          dropdownColor: NVColors.bgCard,
          underline: const SizedBox.shrink(),
          style: const TextStyle(
            color: NVColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.expand_more_rounded,
              color: NVColors.textMuted, size: 18),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );
    }

    return NVGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded,
              color: NVColors.researcherColor, size: 18),
          const SizedBox(width: 10),
          const Text('Model:', style: labelStyle),
          const SizedBox(width: 8),
          dropdown<String>(
            value: _selectedModel,
            items: _models,
            onChanged: (v) => setState(() => _selectedModel = v ?? _selectedModel),
          ),
          const SizedBox(width: 24),
          const Text('Dataset:', style: labelStyle),
          const SizedBox(width: 8),
          dropdown<String>(
            value: _selectedDataset,
            items: _datasets,
            onChanged: (v) =>
                setState(() => _selectedDataset = v ?? _selectedDataset),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NVColors.researcherColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: NVColors.researcherColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: NVColors.researcherColor, size: 14),
                const SizedBox(width: 5),
                Text(
                  _selectedModel,
                  style: const TextStyle(
                    color: NVColors.researcherColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3 ─ Per-class charts (grouped bar + F1 bar)
  // ---------------------------------------------------------------------------
  Widget _buildPerClassCharts() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: grouped bar chart
              Expanded(
                flex: 3,
                child: NVGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Per-Class Precision & Recall',
                          Icons.bar_chart_rounded),
                      const SizedBox(height: 4),
                      Text(
                        _selectedModel,
                        style: const TextStyle(
                            color: NVColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: _buildGroupedBarChart(),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(NVColors.researcherColor, 'Precision'),
                          const SizedBox(width: 20),
                          _legendDot(NVColors.doctorColor, 'Recall'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Right: F1 per class
              Expanded(
                flex: 2,
                child: NVGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                          'F1 Score per Class', Icons.stacked_bar_chart_rounded),
                      const SizedBox(height: 4),
                      Text(
                        _selectedModel,
                        style: const TextStyle(
                            color: NVColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: _buildF1BarChart(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(NVColors.success, '> 0.95'),
                          const SizedBox(width: 12),
                          _legendDot(NVColors.researcherColor, '> 0.92'),
                          const SizedBox(width: 12),
                          _legendDot(NVColors.warning, '≤ 0.92'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        // Mobile: stacked
        return Column(children: [
          NVGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Per-Class Precision & Recall', Icons.bar_chart_rounded),
                const SizedBox(height: 4),
                Text(_selectedModel, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
                const SizedBox(height: 20),
                SizedBox(height: 220, child: _buildGroupedBarChart()),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _legendDot(NVColors.researcherColor, 'Precision'),
                  const SizedBox(width: 20),
                  _legendDot(NVColors.doctorColor, 'Recall'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NVGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('F1 Score per Class', Icons.stacked_bar_chart_rounded),
                const SizedBox(height: 4),
                Text(_selectedModel, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
                const SizedBox(height: 20),
                SizedBox(height: 220, child: _buildF1BarChart()),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _legendDot(NVColors.success, '> 0.95'),
                  const SizedBox(width: 12),
                  _legendDot(NVColors.researcherColor, '> 0.92'),
                  const SizedBox(width: 12),
                  _legendDot(NVColors.warning, '≤ 0.92'),
                ]),
              ],
            ),
          ),
        ]);
      },
    );
  }

  // ── Grouped BarChart (Precision vs Recall) ─────────────────────────────────
  Widget _buildGroupedBarChart() {
    final groups = List.generate(_classes.length, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: _precision[i],
            color: NVColors.researcherColor,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: _recall[i],
            color: NVColors.doctorColor,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.05,
        minY: 0.85,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.05,
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
              reservedSize: 42,
              interval: 0.05,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= _classes.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _classes[idx],
                    style: const TextStyle(
                        color: NVColors.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => NVColors.bgCard,
            tooltipBorder:
                const BorderSide(color: NVColors.borderBright),
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final label = rodIdx == 0 ? 'Precision' : 'Recall';
              return BarTooltipItem(
                '$label\n${rod.toY.toStringAsFixed(3)}',
                const TextStyle(
                    color: NVColors.textPrimary, fontSize: 11),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── F1 BarChart (vertical, color-coded) ────────────────────────────────────
  Widget _buildF1BarChart() {
    Color f1Color(double v) {
      if (v > 0.95) return NVColors.success;
      if (v > 0.92) return NVColors.researcherColor;
      return NVColors.warning;
    }

    final groups = List.generate(_classes.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: _f1[i],
            color: f1Color(_f1[i]),
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.02,
        minY: 0.88,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.05,
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
              reservedSize: 42,
              interval: 0.05,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= _classes.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _classes[idx],
                    style: const TextStyle(
                        color: NVColors.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => NVColors.bgCard,
            tooltipBorder:
                const BorderSide(color: NVColors.borderBright),
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              return BarTooltipItem(
                '${_classes[groupIdx]}\nF1: ${rod.toY.toStringAsFixed(3)}',
                const TextStyle(
                    color: NVColors.textPrimary, fontSize: 11),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4 ─ Detailed metrics table
  // ---------------------------------------------------------------------------
  Widget _buildMetricsTable() {
    const columns = [
      'Class', 'TP', 'FP', 'FN', 'TN',
      'Precision', 'Recall', 'F1-Score', 'Support'
    ];

    // Metric columns indices (0-indexed) — 5,6,7
    const metricCols = {5, 6, 7};

    Color metricColor(double v) {
      if (v >= 0.95) return NVColors.success;
      if (v >= 0.93) return NVColors.researcherColor;
      if (v >= 0.90) return NVColors.warning;
      return NVColors.error;
    }

    Widget headerCell(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            text,
            style: const TextStyle(
              color: NVColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        );

    Widget dataCell(String text, {bool isMetric = false}) {
      Color textColor = NVColors.textSecondary;
      Color? bgColor;
      if (isMetric) {
        final v = double.tryParse(text) ?? 0;
        textColor = metricColor(v);
        bgColor = metricColor(v).withValues(alpha: 0.1);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Container(
          padding: isMetric
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : EdgeInsets.zero,
          decoration: isMetric
              ? BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: textColor.withValues(alpha: 0.25), width: 0.8),
                )
              : null,
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight:
                  isMetric ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return NVGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
              'Detailed Classification Report', Icons.table_chart_rounded),
          const SizedBox(height: 4),
          Text(
            '$_selectedModel  ·  $_selectedDataset',
            style: const TextStyle(color: NVColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          // Table
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(
                    color: NVColors.border, width: 0.8),
                top: BorderSide(color: NVColors.borderBright, width: 0.8),
                bottom: BorderSide(color: NVColors.borderBright, width: 0.8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1.3),
                6: FlexColumnWidth(1.3),
                7: FlexColumnWidth(1.3),
                8: FlexColumnWidth(1),
              },
              children: [
                // Header
                TableRow(
                  decoration:
                      const BoxDecoration(color: NVColors.bgSurface),
                  children: columns.map(headerCell).toList(),
                ),
                // Data rows
                ..._tableRows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  final rowBg = i.isEven
                      ? NVColors.bgCard
                      : NVColors.bgSurface;
                  return TableRow(
                    decoration: BoxDecoration(color: rowBg),
                    children: List.generate(row.length, (colIdx) {
                      // First cell: class name bold
                      if (colIdx == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Text(
                            row[colIdx],
                            style: const TextStyle(
                              color: NVColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return dataCell(
                        row[colIdx],
                        isMetric: metricCols.contains(colIdx),
                      );
                    }),
                  );
                }),
                // Macro avg footer
                TableRow(
                  decoration: BoxDecoration(
                    color: NVColors.researcherColor.withValues(alpha: 0.06),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: const Text(
                        'Macro Average',
                        style: TextStyle(
                          color: NVColors.researcherColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    dataCell('—'),
                    dataCell('—'),
                    dataCell('—'),
                    dataCell('—'),
                    dataCell('0.941', isMetric: true),
                    dataCell('0.928', isMetric: true),
                    dataCell('0.934', isMetric: true),
                    dataCell('530'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5 ─ ROC + PR curves
  // ---------------------------------------------------------------------------
  Widget _buildCurveRow() {
    final rocCard = NVGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ROC Curves (per class)', Icons.timeline_rounded),
          const SizedBox(height: 4),
          Text('$_selectedModel  ·  $_selectedDataset', style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(height: 260, child: _buildRocChart()),
          const SizedBox(height: 14),
          Wrap(spacing: 16, runSpacing: 6, children: List.generate(_classes.length, (i) => Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 16, height: 3, decoration: BoxDecoration(color: _rocColors[i], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 5),
            Text('${_classes[i]} (AUC ${_aucValues[i].toStringAsFixed(3)})', style: const TextStyle(color: NVColors.textSecondary, fontSize: 11)),
          ]))),
        ],
      ),
    );
    final prCard = NVGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Precision-Recall Curve', Icons.show_chart_rounded),
          const SizedBox(height: 4),
          Text('$_selectedModel  ·  DERNet v2.1', style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(height: 260, child: _buildPrChart()),
          const SizedBox(height: 14),
          Row(children: [
            Container(width: 16, height: 3, decoration: BoxDecoration(color: NVColors.researcherColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            const Text('DERNet v2.1', style: TextStyle(color: NVColors.textSecondary, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: NVColors.researcherColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: NVColors.researcherColor.withValues(alpha: 0.3))),
              child: const Text('Avg Precision: 0.941', style: TextStyle(color: NVColors.researcherColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 700) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: rocCard),
          const SizedBox(width: 16),
          Expanded(child: prCard),
        ]);
      }
      return Column(children: [rocCard, const SizedBox(height: 16), prCard]);
    });
  }


  // ── ROC LineChart ──────────────────────────────────────────────────────────
  Widget _buildRocChart() {
    List<LineChartBarData> lines = [];

    // Class curves
    for (int i = 0; i < _rocCurves.length; i++) {
      final pts = _rocCurves[i]
          .map((p) => FlSpot(p[0], p[1]))
          .toList();
      lines.add(LineChartBarData(
        spots: pts,
        isCurved: true,
        color: _rocColors[i],
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }

    // Diagonal baseline (dashed)
    lines.add(LineChartBarData(
      spots: const [FlSpot(0, 0), FlSpot(1, 1)],
      isCurved: false,
      color: NVColors.border,
      barWidth: 1,
      dashArray: [5, 5],
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    ));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        lineBarsData: lines,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.25,
          verticalInterval: 0.25,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: NVColors.border, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: NVColors.border, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: NVColors.borderBright, width: 0.8),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const Text('TPR',
                style: TextStyle(
                    color: NVColors.textMuted, fontSize: 10)),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 0.25,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('FPR',
                style: TextStyle(
                    color: NVColors.textMuted, fontSize: 10)),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 0.25,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 9),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => NVColors.bgCard,
            tooltipBorder:
                const BorderSide(color: NVColors.borderBright),
            getTooltipItems: (spots) => spots.map((s) {
              final classIdx = s.barIndex;
              if (classIdx >= _classes.length) {
                return LineTooltipItem(
                  'Baseline',
                  const TextStyle(
                      color: NVColors.textMuted, fontSize: 10),
                );
              }
              return LineTooltipItem(
                '${_classes[classIdx]}\nFPR: ${s.x.toStringAsFixed(2)}  TPR: ${s.y.toStringAsFixed(2)}',
                TextStyle(color: _rocColors[classIdx], fontSize: 10),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── PR LineChart ───────────────────────────────────────────────────────────
  Widget _buildPrChart() {
    final pts = _prCurve.map((p) => FlSpot(p[0], p[1])).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0.8,
        maxY: 1.02,
        lineBarsData: [
          LineChartBarData(
            spots: pts,
            isCurved: true,
            color: NVColors.researcherColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) =>
                  FlDotCirclePainter(
                radius: 3,
                color: NVColors.researcherColor,
                strokeWidth: 1,
                strokeColor: NVColors.bgCard,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: NVColors.researcherColor.withValues(alpha: 0.12),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.05,
          verticalInterval: 0.25,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: NVColors.border, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: NVColors.border, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: NVColors.borderBright, width: 0.8),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Precision',
                style: TextStyle(
                    color: NVColors.textMuted, fontSize: 10)),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 0.05,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Recall',
                style: TextStyle(
                    color: NVColors.textMuted, fontSize: 10)),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 0.25,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 9),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => NVColors.bgCard,
            tooltipBorder:
                const BorderSide(color: NVColors.borderBright),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      'Recall: ${s.x.toStringAsFixed(2)}\nPrec: ${s.y.toStringAsFixed(3)}',
                      const TextStyle(
                          color: NVColors.researcherColor, fontSize: 10),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: NVColors.researcherColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: NVColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
              color: NVColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
