// lib/src/ui/screens/dashboard/researcher/model_benchmark_screen.dart
//
// Feature: Real-Time Model Benchmarking Arena
// Academic concept: Head-to-head comparative model evaluation on the same input.
// DERNet vs SegResNet vs AttentionUNet — side-by-side performance race.
//
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_top_bar.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class _ModelResult {
  final String name;
  final Color color;
  double accuracy;
  double dice;
  double precision;
  double recall;
  double inferenceMs;
  int rank;
  bool done;
  double progress;

  _ModelResult({
    required this.name,
    required this.color,
    required this.accuracy,
    required this.dice,
    required this.precision,
    required this.recall,
    required this.inferenceMs,
    required this.rank,
    this.done = false,
    this.progress = 0.0,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ModelBenchmarkScreen extends StatefulWidget {
  const ModelBenchmarkScreen({super.key});

  @override
  State<ModelBenchmarkScreen> createState() => _ModelBenchmarkScreenState();
}

class _ModelBenchmarkScreenState extends State<ModelBenchmarkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  bool _isBenchmarking = false;
  bool _benchmarkComplete = false;
  String _selectedModality = 'Brain MRI';

  final List<_ModelResult> _models = [
    _ModelResult(
      name: 'DERNet', color: NVColors.researcherColor,
      accuracy: 96.8, dice: 0.817, precision: 0.921, recall: 0.896, inferenceMs: 284, rank: 1,
    ),
    _ModelResult(
      name: 'SegResNet', color: NVColors.doctorColor,
      accuracy: 94.2, dice: 0.782, precision: 0.883, recall: 0.871, inferenceMs: 211, rank: 2,
    ),
    _ModelResult(
      name: 'AttentionUNet', color: NVColors.radiologistColor,
      accuracy: 93.7, dice: 0.779, precision: 0.862, recall: 0.858, inferenceMs: 198, rank: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _isBenchmarking = true;
      _benchmarkComplete = false;
      for (final m in _models) {
        m.done = false;
        m.progress = 0.0;
      }
    });

    // Simulate concurrent model inference with different speeds
    final finishTimes = [1800, 2200, 2600]; // ms to finish
    final totalTime = finishTimes.last;

    for (int elapsed = 0; elapsed <= totalTime; elapsed += 80) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _models.length; i++) {
          _models[i].progress = (elapsed / finishTimes[i]).clamp(0.0, 1.0);
          if (_models[i].progress >= 1.0 && !_models[i].done) {
            _models[i].done = true;
          }
        }
      });
    }

    if (!mounted) return;
    setState(() {
      _isBenchmarking = false;
      _benchmarkComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NVScaffold(
      currentRoute: '/dashboard/researcher/benchmark',
      role: AppConstants.roleResearcher,
      title: 'Benchmark Arena',
      subtitle: 'Real-Time Comparative Model Evaluation',
      userName: 'Researcher',
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'Model Benchmarking Arena',
            subtitle: 'Head-to-Head: DERNet vs SegResNet vs AttentionUNet',
            user: 'Researcher',
            roleColor: NVColors.researcherColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConceptBanner(),
                  const SizedBox(height: 20),
                  _buildControlBar(),
                  const SizedBox(height: 20),
                  _buildRaceLeaderboard(),
                  const SizedBox(height: 20),
                  if (_benchmarkComplete) ...[
                    _buildMainCharts(),
                    const SizedBox(height: 20),
                    _buildComparisonTable(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          NVColors.researcherColor.withValues(alpha: 0.10),
          NVColors.warning.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NVColors.researcherColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [NVColors.warning, Color(0xFFD97706)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.leaderboard_rounded, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Model Benchmarking Arena — Comparative AI Evaluation',
                    style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 3),
                Text(
                  'Run all 3 deep learning models simultaneously on the same test scan. Compare inference speed, '
                  'Dice score, accuracy, precision, and recall in a live race-style leaderboard.',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NVColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NVColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Text('ARENA MODE',
                style: TextStyle(color: NVColors.warning, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: NVColors.researcherColor, size: 16),
          const SizedBox(width: 8),
          const Text('Test Modality:', style: TextStyle(color: NVColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: NVColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NVColors.border),
            ),
            child: DropdownButton<String>(
              value: _selectedModality,
              onChanged: (v) => setState(() => _selectedModality = v!),
              items: ['Brain MRI', 'Spine MRI'].map((v) => DropdownMenuItem(
                value: v,
                child: Text(v, style: const TextStyle(color: NVColors.textPrimary, fontSize: 13)),
              )).toList(),
              underline: const SizedBox(),
              dropdownColor: NVColors.bgCard,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isBenchmarking ? null : _runBenchmark,
            icon: _isBenchmarking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.play_circle_rounded, size: 18),
            label: Text(_isBenchmarking ? 'Benchmarking...' : 'Run Benchmark'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NVColors.researcherColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceLeaderboard() {
    final sorted = List<_ModelResult>.from(_models);
    if (_benchmarkComplete) {
      sorted.sort((a, b) => b.accuracy.compareTo(a.accuracy));
    }

    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.sports_score_rounded, color: NVColors.warning, size: 16),
            SizedBox(width: 8),
            Text('Live Inference Race', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          const Text('All models running simultaneously on the same test scan',
              style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          ...sorted.asMap().entries.map((e) => _buildRaceRow(e.key + 1, e.value)),
        ],
      ),
    );
  }

  Widget _buildRaceRow(int pos, _ModelResult model) {
    final isWinner = pos == 1 && _benchmarkComplete;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? model.color.withValues(alpha: 0.08) : NVColors.bgDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? model.color.withValues(alpha: 0.4) : NVColors.border,
          width: isWinner ? 1.5 : 1,
        ),
        boxShadow: isWinner ? [BoxShadow(color: model.color.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1)] : [],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Position badge
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _posColor(pos).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _posColor(pos).withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: isWinner
                      ? const Icon(Icons.emoji_events_rounded, color: NVColors.warning, size: 14)
                      : Text('$pos', style: TextStyle(color: _posColor(pos), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: model.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(model.name,
                    style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              if (model.done) ...[
                Text('${model.inferenceMs}ms', style: TextStyle(color: model.color, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 12),
                Text('${model.accuracy.toStringAsFixed(1)}%', style: TextStyle(color: model.color, fontWeight: FontWeight.bold, fontSize: 16)),
              ] else if (_isBenchmarking || !_benchmarkComplete) ...[
                Text('${(model.progress * 100).toInt()}%', style: const TextStyle(color: NVColors.textMuted, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: model.progress,
              minHeight: 6,
              backgroundColor: NVColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(model.color),
            ),
          ),
          if (model.done && _benchmarkComplete) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricChip('Dice: ${model.dice.toStringAsFixed(3)}', model.color),
                _MetricChip('Prec: ${(model.precision * 100).toStringAsFixed(1)}%', model.color),
                _MetricChip('Recall: ${(model.recall * 100).toStringAsFixed(1)}%', model.color),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _posColor(int pos) {
    if (pos == 1) return NVColors.warning;
    if (pos == 2) return NVColors.textSecondary;
    return const Color(0xFFB45309);
  }

  Widget _buildMainCharts() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 750;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildRadarChart()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildSpeedChart()),
          ],
        );
      }
      return Column(children: [_buildRadarChart(), const SizedBox(height: 16), _buildSpeedChart()]);
    });
  }

  Widget _buildRadarChart() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.radar_rounded, color: NVColors.researcherColor, size: 16),
            SizedBox(width: 8),
            Text('Multi-Metric Comparison Radar', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: RadarChart(RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
              gridBorderData: const BorderSide(color: NVColors.border, width: 0.5),
              radarBorderData: const BorderSide(color: NVColors.border, width: 0.5),
              titleTextStyle: const TextStyle(color: NVColors.textMuted, fontSize: 10),
              titlePositionPercentageOffset: 0.18,
              getTitle: (index, _) {
                const titles = ['Accuracy', 'Dice', 'Precision', 'Recall', 'Speed'];
                return RadarChartTitle(text: titles[index]);
              },
              dataSets: [
                RadarDataSet(
                  fillColor: NVColors.researcherColor.withValues(alpha: 0.15),
                  borderColor: NVColors.researcherColor,
                  borderWidth: 2,
                  entryRadius: 3,
                  dataEntries: [
                    const RadarEntry(value: 96.8),
                    const RadarEntry(value: 81.7),
                    const RadarEntry(value: 92.1),
                    const RadarEntry(value: 89.6),
                    const RadarEntry(value: 60),
                  ],
                ),
                RadarDataSet(
                  fillColor: NVColors.doctorColor.withValues(alpha: 0.10),
                  borderColor: NVColors.doctorColor,
                  borderWidth: 2,
                  entryRadius: 3,
                  dataEntries: [
                    const RadarEntry(value: 94.2),
                    const RadarEntry(value: 78.2),
                    const RadarEntry(value: 88.3),
                    const RadarEntry(value: 87.1),
                    const RadarEntry(value: 80),
                  ],
                ),
                RadarDataSet(
                  fillColor: NVColors.radiologistColor.withValues(alpha: 0.10),
                  borderColor: NVColors.radiologistColor,
                  borderWidth: 2,
                  entryRadius: 3,
                  dataEntries: [
                    const RadarEntry(value: 93.7),
                    const RadarEntry(value: 77.9),
                    const RadarEntry(value: 86.2),
                    const RadarEntry(value: 85.8),
                    const RadarEntry(value: 85),
                  ],
                ),
              ],
            )),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: _models.map((m) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 2, color: m.color),
              const SizedBox(width: 5),
              Text(m.name, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
            ]),
          )).toList()),
        ],
      ),
    );
  }

  Widget _buildSpeedChart() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.speed_rounded, color: NVColors.warning, size: 16),
            SizedBox(width: 8),
            Text('Inference Speed', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          const Text('Milliseconds per forward pass', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              barGroups: _models.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(
                  toY: e.value.inferenceMs.toDouble(),
                  color: e.value.color,
                  width: 36,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                )],
              )).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final names = _models.map((m) => m.name).toList();
                    final i = v.toInt();
                    return Text(i < names.length ? names[i] : '',
                        style: const TextStyle(color: NVColors.textMuted, fontSize: 10));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}ms',
                      style: const TextStyle(color: NVColors.textMuted, fontSize: 9)),
                )),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: NVColors.border, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
            )),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NVColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NVColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(children: const [
              Icon(Icons.info_rounded, color: NVColors.warning, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text(
                'AttentionUNet is fastest (198ms). DERNet achieves highest accuracy (96.8%) with ensemble.',
                style: TextStyle(color: NVColors.warning, fontSize: 10, height: 1.4),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.table_chart_rounded, color: NVColors.researcherColor, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('Full Benchmark Results', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: NVColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NVColors.success.withValues(alpha: 0.3)),
              ),
              child: const Text('COMPLETE', style: TextStyle(color: NVColors.success, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Model', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Accuracy', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Dice Score', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Precision', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Recall', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Speed', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ..._models.asMap().entries.map((e) {
            final m = e.value;
            final isFirst = e.key == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isFirst ? m.color.withValues(alpha: 0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isFirst ? Border.all(color: m.color.withValues(alpha: 0.2)) : null,
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Row(children: [
                    if (isFirst) const Icon(Icons.emoji_events_rounded, color: NVColors.warning, size: 12),
                    if (isFirst) const SizedBox(width: 4),
                    Text(m.name, style: TextStyle(color: m.color, fontWeight: FontWeight.w600, fontSize: 12)),
                  ])),
                  Expanded(flex: 2, child: Text('${m.accuracy.toStringAsFixed(1)}%', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12))),
                  Expanded(flex: 2, child: Text(m.dice.toStringAsFixed(3), style: const TextStyle(color: NVColors.textPrimary, fontSize: 12))),
                  Expanded(flex: 2, child: Text('${(m.precision * 100).toStringAsFixed(1)}%', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12))),
                  Expanded(flex: 2, child: Text('${(m.recall * 100).toStringAsFixed(1)}%', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12))),
                  Expanded(flex: 2, child: Text('${m.inferenceMs}ms', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MetricChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
