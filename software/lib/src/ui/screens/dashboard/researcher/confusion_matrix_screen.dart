// lib/src/ui/screens/dashboard/researcher/confusion_matrix_screen.dart
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
// Route: /dashboard/researcher/confusion
// ---------------------------------------------------------------------------

class ConfusionMatrixScreen extends StatefulWidget {
  const ConfusionMatrixScreen({super.key});

  @override
  State<ConfusionMatrixScreen> createState() => _ConfusionMatrixScreenState();
}

class _ConfusionMatrixScreenState extends State<ConfusionMatrixScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  // ── State ──────────────────────────────────────────────────────────────────
  String _selectedModel = 'DERNet v2.1';
  bool _showNormalized = false;
  int? _tappedRow;
  int? _tappedCol;

  // ── Static data ────────────────────────────────────────────────────────────
  static const List<String> _models = [
    'DERNet v2.1',
    'SegResNet',
    'EfficientNetV2',
  ];

  static const List<String> _classNames = [
    'Normal',
    'Ischemic',
    'Glioblastoma',
    'Hemorrhage',
  ];

  /// Raw confusion matrix — rows = actual, cols = predicted
  static const List<List<int>> _rawMatrix = [
    [142, 5, 2, 1],
    [8, 187, 3, 2],
    [3, 2, 94, 1],
    [4, 3, 1, 71],
  ];

  static const List<Color> _classColors = [
    NVColors.success,
    NVColors.researcherColor,
    NVColors.info,
    NVColors.error,
  ];

  // Per-class recall / precision / counts
  static const List<double> _recalls = [94.7, 93.5, 94.0, 88.7];
  static const List<double> _precisions = [92.8, 93.1, 96.9, 91.0];
  static const List<int> _classTotals = [150, 200, 100, 79];

  // Error pairs: label, count
  static const List<_ErrorPair> _errorPairs = [
    _ErrorPair('Ischemic → Normal', 8),
    _ErrorPair('Normal → Ischemic', 5),
    _ErrorPair('Hemorrhage → Normal', 4),
    _ErrorPair('Ischemic → Glioblastoma', 3),
    _ErrorPair('Normal → Glioblastoma', 2),
  ];

  // Classification report rows
  static const List<_ReportRow> _reportRows = [
    _ReportRow('Accuracy', '93.2%'),
    _ReportRow('Macro Precision', '93.4%'),
    _ReportRow('Macro Recall', '92.7%'),
    _ReportRow('Macro F1', '93.0%'),
    _ReportRow('Weighted F1', '93.4%'),
    _ReportRow("Cohen's Kappa", '0.908'),
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Row sums for normalisation
  List<int> get _rowSums =>
      _rawMatrix.map((row) => row.reduce((a, b) => a + b)).toList();

  double _normalized(int r, int c) =>
      _rowSums[r] == 0 ? 0 : _rawMatrix[r][c] / _rowSums[r];

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Row(
        children: [
          NVSidebar(
            currentRoute: '/dashboard/researcher/confusion',
            role: AppConstants.roleResearcher,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  NVTopBar(
                    title: 'Confusion Matrix',
                    subtitle:
                        'Interactive classification error analysis & per-class performance breakdown',
                    user: user?.name ?? 'Researcher',
                    roleColor: NVColors.researcherColor,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stats row ─────────────────────────────────────
                          _buildStatsRow(),
                          const SizedBox(height: 24),

                          // ── Model + mode selectors ─────────────────────────
                          _buildSelectors(),
                          const SizedBox(height: 24),

                          // ── Matrix + Per-class side by side ────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(flex: 3, child: _buildMatrixCard()),
                              const SizedBox(width: 16),
                              Flexible(flex: 2, child: _buildPerClassCard()),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Error analysis + Report ────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                  flex: 3,
                                  child: _buildMisclassificationCard()),
                              const SizedBox(width: 16),
                              Flexible(flex: 2, child: _buildReportCard()),
                            ],
                          ),
                          const SizedBox(height: 24),
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

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, c) {
        return GridView.count(
          crossAxisCount: c.maxWidth > 700 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            NVStatCard(
              label: 'Total Predictions',
              value: '530',
              icon: Icons.analytics_rounded,
              color: NVColors.researcherColor,
            ),
            NVStatCard(
              label: 'Correct',
              value: '494',
              icon: Icons.check_circle_rounded,
              color: NVColors.success,
              subtitle: '93.2% accuracy',
            ),
            NVStatCard(
              label: 'Misclassified',
              value: '36',
              icon: Icons.cancel_rounded,
              color: NVColors.error,
              subtitle: '6.8% error rate',
            ),
            NVStatCard(
              label: 'Worst Class',
              value: 'Hemorrhage',
              icon: Icons.warning_rounded,
              color: NVColors.warning,
              subtitle: '10.0% error',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectors() {
    return NVGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Model icon
          const Icon(Icons.model_training_rounded,
              color: NVColors.researcherColor, size: 18),
          const SizedBox(width: 10),
          const Text(
            'Model:',
            style: TextStyle(
                color: NVColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          // Model dropdown
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: NVColors.bgCard,
            ),
            child: DropdownButton<String>(
              value: _selectedModel,
              underline: const SizedBox.shrink(),
              dropdownColor: NVColors.bgCard,
              style: const TextStyle(
                  color: NVColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: NVColors.researcherColor, size: 18),
              items: _models
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedModel = v);
              },
            ),
          ),
          const SizedBox(width: 32),
          const Text(
            'Display:',
            style: TextStyle(
                color: NVColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          // Mode toggle chips
          _ModeChip(
            label: 'Raw Counts',
            active: !_showNormalized,
            onTap: () => setState(() => _showNormalized = false),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: 'Normalized (%)',
            active: _showNormalized,
            onTap: () => setState(() => _showNormalized = true),
          ),
          const Spacer(),
          // Tapped cell info
          if (_tappedRow != null && _tappedCol != null)
            _buildTappedCellInfo(),
        ],
      ),
    );
  }

  Widget _buildTappedCellInfo() {
    final r = _tappedRow!;
    final c = _tappedCol!;
    final raw = _rawMatrix[r][c];
    final norm = (_normalized(r, c) * 100).toStringAsFixed(1);
    final isCorrect = r == c;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isCorrect ? NVColors.success : NVColors.error)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isCorrect ? NVColors.success : NVColors.error)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? NVColors.success : NVColors.error,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Actual ${_classNames[r]} → Predicted ${_classNames[c]}: $raw ($norm%)',
            style: TextStyle(
              color: isCorrect ? NVColors.success : NVColors.error,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _tappedRow = null;
              _tappedCol = null;
            }),
            child: const Icon(Icons.close_rounded,
                color: NVColors.textMuted, size: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.grid_on_rounded,
                  color: NVColors.researcherColor, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Confusion Matrix',
                style: TextStyle(
                    color: NVColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
              const Spacer(),
              Text(
                _showNormalized ? 'Normalized (%)' : 'Raw Counts',
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_selectedModel · Brain MRI Test Set (530 predictions)',
            style: const TextStyle(color: NVColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 20),

          // Axis label: "Predicted →"
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Predicted Class →',
                      style: TextStyle(
                          color: NVColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Column headers
          Row(
            children: [
              // Spacer for row label column + "Actual" label
              const SizedBox(width: 72),
              ...List.generate(4, (c) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _classNames[c],
                      style: TextStyle(
                          color: _classColors[c],
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),

          // Actual label + matrix rows
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rotated "Actual Class ↓" label
              SizedBox(
                width: 16,
                height: 4 * 58.0,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: const Text(
                    'Actual Class ↓',
                    style: TextStyle(
                        color: NVColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: List.generate(4, (r) => _buildMatrixRow(r)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Legend
          _buildMatrixLegend(),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(int r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Row label
          SizedBox(
            width: 52,
            child: Text(
              _classNames[r],
              style: TextStyle(
                  color: _classColors[r],
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          ...List.generate(4, (c) => Expanded(child: _buildCell(r, c))),
        ],
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    final rawVal = _rawMatrix[r][c];
    final normVal = _normalized(r, c);
    final isDiagonal = r == c;
    final isTapped = _tappedRow == r && _tappedCol == c;

    // Max value in row for diagonal intensity; max off-diag overall for error intensity
    final rowMax =
        _rawMatrix[r].reduce((a, b) => a > b ? a : b).toDouble();
    final intensity = isDiagonal
        ? (rawVal / rowMax).clamp(0.0, 1.0)
        : (rawVal / 8.0).clamp(0.0, 1.0); // max off-diag = 8

    final baseColor =
        isDiagonal ? NVColors.researcherColor : NVColors.error;
    final bgAlpha = isDiagonal
        ? 0.08 + intensity * 0.55
        : (rawVal == 0 ? 0.0 : 0.05 + intensity * 0.40);

    final borderColor = isTapped
        ? (isDiagonal ? NVColors.researcherColor : NVColors.error)
        : baseColor.withValues(alpha: isDiagonal ? 0.25 : 0.15);

    return GestureDetector(
      onTap: () => setState(() {
        if (_tappedRow == r && _tappedCol == c) {
          _tappedRow = null;
          _tappedCol = null;
        } else {
          _tappedRow = r;
          _tappedCol = c;
        }
      }),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: rawVal == 0
                ? NVColors.bgDeep
                : baseColor.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: isTapped ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _showNormalized
                    ? '${(normVal * 100).toStringAsFixed(1)}%'
                    : '$rawVal',
                style: TextStyle(
                  color: rawVal == 0
                      ? NVColors.textMuted
                      : (isDiagonal
                          ? NVColors.researcherColor
                          : NVColors.error),
                  fontSize: isDiagonal ? 13 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_showNormalized && rawVal > 0 && isDiagonal)
                Text(
                  '($rawVal)',
                  style: const TextStyle(
                      color: NVColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w400),
                ),
              if (!_showNormalized && rawVal > 0)
                Text(
                  '${(normVal * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: (isDiagonal
                              ? NVColors.researcherColor
                              : NVColors.error)
                          .withValues(alpha: 0.6),
                      fontSize: 8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixLegend() {
    return Row(
      children: [
        _buildLegendGradient(
          label: 'Correct',
          fromColor: NVColors.researcherColor.withValues(alpha: 0.08),
          toColor: NVColors.researcherColor.withValues(alpha: 0.63),
          textColor: NVColors.researcherColor,
        ),
        const SizedBox(width: 16),
        _buildLegendGradient(
          label: 'Misclassified',
          fromColor: NVColors.error.withValues(alpha: 0.05),
          toColor: NVColors.error.withValues(alpha: 0.45),
          textColor: NVColors.error,
        ),
      ],
    );
  }

  Widget _buildLegendGradient({
    required String label,
    required Color fromColor,
    required Color toColor,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(colors: [fromColor, toColor]),
            border: Border.all(color: textColor.withValues(alpha: 0.2)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        const SizedBox(width: 4),
        Text(
          '(low → high)',
          style: const TextStyle(color: NVColors.textMuted, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildPerClassCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: NVColors.researcherColor, size: 16),
              SizedBox(width: 8),
              Text(
                'Per-Class Analysis',
                style: TextStyle(
                    color: NVColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Recall & precision breakdown per class',
            style: TextStyle(color: NVColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (i) => _buildClassCard(
              name: _classNames[i],
              color: _classColors[i],
              recall: _recalls[i],
              precision: _precisions[i],
              count: _classTotals[i],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required String name,
    required Color color,
    required double recall,
    required double precision,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'n=$count',
                style: const TextStyle(color: NVColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMetricBar(label: 'Recall', value: recall, color: color),
          const SizedBox(height: 6),
          _buildMetricBar(
              label: 'Precision',
              value: precision,
              color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 4),
          // F1 derived
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'F1: ${(2 * recall * precision / (recall + precision)).toStringAsFixed(1)}%',
                style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(color: NVColors.textMuted, fontSize: 10),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: NVColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value / 100.0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildMisclassificationCard() {
    const maxCount = 10.0;
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: NVColors.error, size: 16),
              SizedBox(width: 8),
              Text(
                'Top Misclassification Pairs',
                style: TextStyle(
                    color: NVColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Most frequent classification errors in test set',
            style: TextStyle(color: NVColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 20),
          ...List.generate(_errorPairs.length, (i) {
            final pair = _errorPairs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pair.label,
                          style: const TextStyle(
                              color: NVColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: NVColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: NVColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${pair.count}',
                          style: const TextStyle(
                              color: NVColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: NVColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pair.count / maxCount,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                NVColors.error.withValues(alpha: 0.5),
                                NVColors.error.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          // Scale reference
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0',
                  style:
                      TextStyle(color: NVColors.textMuted, fontSize: 9)),
              ...List.generate(5, (i) {
                final v = (i + 1) * 2;
                return Text(
                  '$v',
                  style: const TextStyle(
                      color: NVColors.textMuted, fontSize: 9),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize_rounded,
                  color: NVColors.researcherColor, size: 16),
              SizedBox(width: 8),
              Text(
                'Classification Report Summary',
                style: TextStyle(
                    color: NVColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_selectedModel · Overall metrics',
            style: const TextStyle(color: NVColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: NVColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NVColors.border),
            ),
            child: Column(
              children: List.generate(_reportRows.length, (i) {
                final row = _reportRows[i];
                final isLast = i == _reportRows.length - 1;
                return Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: NVColors.border)),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: const TextStyle(
                              color: NVColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      Text(
                        row.value,
                        style: const TextStyle(
                          color: NVColors.researcherColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // Visual accuracy ring
          Center(child: _buildAccuracyRing()),
        ],
      ),
    );
  }

  Widget _buildAccuracyRing() {
    return Column(
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  sections: [
                    PieChartSectionData(
                      value: 93.2,
                      color: NVColors.researcherColor,
                      radius: 16,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 6.8,
                      color: NVColors.error.withValues(alpha: 0.5),
                      radius: 12,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '93.2%',
                    style: TextStyle(
                        color: NVColors.researcherColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  Text(
                    'Accuracy',
                    style:
                        TextStyle(color: NVColors.textMuted, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(
                color: NVColors.researcherColor, label: 'Correct 93.2%'),
            const SizedBox(width: 12),
            _LegendDot(
                color: NVColors.error.withValues(alpha: 0.5),
                label: 'Error 6.8%'),
          ],
        ),
      ],
    );
  }
}

// ── Helper data classes ─────────────────────────────────────────────────────

class _ErrorPair {
  final String label;
  final int count;
  const _ErrorPair(this.label, this.count);
}

class _ReportRow {
  final String label;
  final String value;
  const _ReportRow(this.label, this.value);
}

// ── Small reusable widgets ───────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? NVColors.researcherColor.withValues(alpha: 0.15)
              : NVColors.bgDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? NVColors.researcherColor.withValues(alpha: 0.6)
                : NVColors.border,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? NVColors.researcherColor : NVColors.textMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
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
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: NVColors.textMuted, fontSize: 9)),
      ],
    );
  }
}
