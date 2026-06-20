// lib/src/ui/screens/dashboard/researcher/experiment_tracking_screen.dart
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

class ExperimentTrackingScreen extends StatefulWidget {
  const ExperimentTrackingScreen({super.key});
  @override
  State<ExperimentTrackingScreen> createState() => _ExperimentTrackingScreenState();
}

class _ExperimentTrackingScreenState extends State<ExperimentTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  String _selectedExpId = 'EXP-2026-014';
  String _sortBy = 'accuracy';

  final _experiments = [
    _Exp('EXP-2026-014', 'DERNet v2.1', 'Brain MRI', 96.8, 0.043, 0.971, 0.965, 30, 30, 'completed', NVColors.success),
    _Exp('EXP-2026-013', 'SegResNet', 'Brain MRI', 94.2, 0.062, 0.948, 0.937, 30, 30, 'completed', NVColors.success),
    _Exp('EXP-2026-012', 'EfficientNetV2', 'Spine MRI', 91.5, 0.078, 0.922, 0.908, 30, 18, 'running', NVColors.primary),
    _Exp('EXP-2026-011', 'Attention U-Net', 'Brain MRI', 93.7, 0.055, 0.941, 0.930, 25, 25, 'paused', NVColors.warning),
    _Exp('EXP-2026-010', 'DenseNet201', 'Spine MRI', 89.4, 0.091, 0.899, 0.884, 20, 20, 'completed', NVColors.success),
    _Exp('EXP-2026-009', 'ResNet50', 'Chest X-Ray', 87.1, 0.108, 0.874, 0.862, 15, 15, 'completed', NVColors.success),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  _Exp get _selected => _experiments.firstWhere((e) => e.id == _selectedExpId, orElse: () => _experiments.first);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return NVScaffold(
      currentRoute: '/dashboard/researcher/experiments',
      role: AppConstants.roleResearcher,
      title: 'Experiment Tracking',
      subtitle: 'Monitor training runs, compare architectures, track metrics',
      userName: user?.name ?? 'Researcher',
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fade,
      body: Column(children: [
        NVTopBar(title: 'Experiment Tracking', subtitle: 'Monitor training runs, compare architectures, track metrics', user: user?.name ?? 'Researcher', roleColor: NVColors.researcherColor),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildStats(),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 300, child: _buildExpList()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildExpDetail()),
                ]);
              }
              return Column(children: [
                _buildExpList(),
                const SizedBox(height: 16),
                _buildExpDetail(),
              ]);
            }),
          ]),
        )),
      ]),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final count = w > 800 ? 4 : (w > 400 ? 2 : 1);
      final itemWidth = w / count;
      final ratio = w > 400 ? 1.6 : (itemWidth / 160.0);
      return GridView.count(
        crossAxisCount: count, crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: ratio, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: const [
          NVStatCard(label: 'Total Experiments', value: '6', icon: Icons.science_rounded, color: NVColors.researcherColor, subtitle: 'All runs'),
          NVStatCard(label: 'Best Accuracy', value: '96.8%', icon: Icons.emoji_events_rounded, color: NVColors.warning, subtitle: 'DERNet v2.1'),
          NVStatCard(label: 'Running Now', value: '1', icon: Icons.play_circle_rounded, color: NVColors.primary, subtitle: 'EfficientNetV2'),
          NVStatCard(label: 'GPU Hours Used', value: '142h', icon: Icons.memory_rounded, color: NVColors.secondary, subtitle: 'Across all runs'),
        ],
      );
    });
  }

  Widget _buildExpList() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Experiment Runs', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showNewExpDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: NVColors.researcherColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: NVColors.researcherColor.withValues(alpha: 0.4))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, color: NVColors.researcherColor, size: 14), SizedBox(width: 4), Text('New', style: TextStyle(color: NVColors.researcherColor, fontSize: 11, fontWeight: FontWeight.w600))]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        // Sort
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Sort by:', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(width: 8),
          ...['accuracy', 'loss', 'date'].map((s) {
            final isActive = _sortBy == s;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _sortBy = s),
                child: Text(s, style: TextStyle(color: isActive ? NVColors.researcherColor : NVColors.textMuted, fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
              ),
            );
          }),
        ]),
        const SizedBox(height: 12),
        ..._experiments.map((e) {
          final isSelected = e.id == _selectedExpId;
          return GestureDetector(
            onTap: () => setState(() => _selectedExpId = e.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? NVColors.researcherColor.withValues(alpha: 0.1) : NVColors.bgDeep,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? NVColors.researcherColor : NVColors.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: e.statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(e.id, style: TextStyle(color: isSelected ? NVColors.primary : NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: e.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(e.status, style: TextStyle(color: e.statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${e.model} · ${e.modality}', style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
                const SizedBox(height: 6),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('Acc: ', style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
                  Text('${e.accuracy}%', style: const TextStyle(color: NVColors.researcherColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 12),
                  Text('Loss: ', style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
                  Text(e.loss.toString(), style: const TextStyle(color: NVColors.doctorColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 12),
                  Text('${e.epochsCurrent}/${e.epochsTotal} ep', style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
                ]),
                if (e.status == 'running') ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: e.epochsCurrent / e.epochsTotal,
                    backgroundColor: NVColors.border, valueColor: const AlwaysStoppedAnimation<Color>(NVColors.primary),
                    minHeight: 3, borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildExpDetail() {
    final e = _selected;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Detail header
      NVGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 10, children: [
            const Icon(Icons.science_rounded, color: NVColors.researcherColor, size: 18),
            Text(e.id, style: const TextStyle(color: NVColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: e.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: e.statusColor.withValues(alpha: 0.4))), child: Text(e.status.toUpperCase(), style: TextStyle(color: e.statusColor, fontWeight: FontWeight.bold, fontSize: 11))),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.compare_arrows_rounded, size: 14), label: const Text('Compare'), style: OutlinedButton.styleFrom(foregroundColor: NVColors.researcherColor, side: const BorderSide(color: NVColors.researcherColor), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontSize: 12))),
          ]),
          const SizedBox(height: 16),
          // Metrics grid
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final count = w > 500 ? 4 : 2;
            final itemWidth = w / count;
            final ratio = w > 400 ? 1.4 : 1.1;
            return GridView.count(
              crossAxisCount: count,
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: ratio, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricCard(label: 'Accuracy', value: '${e.accuracy}%', color: NVColors.researcherColor),
                _MetricCard(label: 'Loss', value: e.loss.toString(), color: NVColors.error),
                _MetricCard(label: 'Precision', value: '${(e.precision * 100).toStringAsFixed(1)}%', color: NVColors.success),
                _MetricCard(label: 'Recall', value: '${(e.recall * 100).toStringAsFixed(1)}%', color: NVColors.doctorColor),
              ],
            );
          }),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16, runSpacing: 12,
            children: [
              _ExpDetail(label: 'Model', value: e.model),
              _ExpDetail(label: 'Modality', value: e.modality),
              _ExpDetail(label: 'Epochs', value: '${e.epochsCurrent}/${e.epochsTotal}'),
              _ExpDetail(label: 'F1 Score', value: (e.precision * e.recall * 2 / (e.precision + e.recall)).toStringAsFixed(3)),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Training curves
      NVGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.trending_up_rounded, color: NVColors.researcherColor, size: 16), SizedBox(width: 8), Text('Training Curves', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]),
          const SizedBox(height: 20),
          SizedBox(height: 180, child: LineChart(LineChartData(
            gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: NVColors.border, strokeWidth: 0.5)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(0)}%', style: const TextStyle(color: NVColors.textMuted, fontSize: 9)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text('Ep ${v.toInt()}', style: const TextStyle(color: NVColors.textMuted, fontSize: 9)))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(spots: const [FlSpot(1, 72), FlSpot(5, 82), FlSpot(10, 88), FlSpot(15, 92), FlSpot(20, 94), FlSpot(25, 95.5), FlSpot(30, 96.8)], isCurved: true, color: NVColors.researcherColor, barWidth: 2.5, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [NVColors.researcherColor.withValues(alpha: 0.12), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              LineChartBarData(spots: const [FlSpot(1, 68), FlSpot(5, 79), FlSpot(10, 85), FlSpot(15, 89), FlSpot(20, 91.5), FlSpot(25, 93), FlSpot(30, 94.2)], isCurved: true, color: NVColors.doctorColor, barWidth: 2, dashArray: [4, 3], dotData: const FlDotData(show: false)),
            ],
          ))),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LegLine(color: NVColors.researcherColor, label: 'Train Accuracy'),
            const SizedBox(width: 16),
            _LegLine(color: NVColors.doctorColor, label: 'Val Accuracy', dashed: true),
          ]),
        ]),
      ),
    ]);
  }

  void _showNewExpDialog() {
    final modelCtrl = TextEditingController();
    String selectedModality = 'Brain MRI';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      backgroundColor: NVColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: NVColors.border)),
      title: const Row(children: [Icon(Icons.add_circle_outline_rounded, color: NVColors.researcherColor, size: 20), SizedBox(width: 8), Text('New Experiment Run', style: TextStyle(color: NVColors.textPrimary, fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: modelCtrl, style: const TextStyle(color: NVColors.textPrimary), decoration: const InputDecoration(labelText: 'Model Name', hintText: 'DERNet v3.0')),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedModality,
          dropdownColor: NVColors.bgCard,
          style: const TextStyle(color: NVColors.textPrimary, fontSize: 13),
          decoration: const InputDecoration(labelText: 'Modality'),
          items: ['Brain MRI', 'Spine MRI', 'Chest X-Ray', 'CT Scan'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) { if (v != null) setS(() => selectedModality = v); },
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: NVColors.textMuted))),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiment queued for training'), backgroundColor: NVColors.researcherColor, behavior: SnackBarBehavior.floating)); },
          style: ElevatedButton.styleFrom(backgroundColor: NVColors.researcherColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Start Run'),
        ),
      ],
    )));
  }
}

class _Exp {
  final String id, model, modality, status;
  final double accuracy, loss, precision, recall;
  final int epochsTotal, epochsCurrent;
  final Color statusColor;
  _Exp(this.id, this.model, this.modality, this.accuracy, this.loss, this.precision, this.recall, this.epochsTotal, this.epochsCurrent, this.status, this.statusColor);
}

class _MetricCard extends StatelessWidget {
  final String label, value; final Color color;
  const _MetricCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)), const SizedBox(height: 4), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))]));
}

class _ExpDetail extends StatelessWidget {
  final String label, value;
  const _ExpDetail({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)), const SizedBox(height: 2), Text(value, style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]);
}

class _LegLine extends StatelessWidget {
  final Color color; final String label; final bool dashed;
  const _LegLine({required this.color, required this.label, this.dashed = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 16, height: 2, color: color), const SizedBox(width: 6), Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10))]);
}
