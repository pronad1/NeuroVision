// lib/src/ui/screens/dashboard/researcher/model_monitoring_screen.dart
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

class ModelMonitoringScreen extends StatefulWidget {
  const ModelMonitoringScreen({super.key});
  @override
  State<ModelMonitoringScreen> createState() => _ModelMonitoringScreenState();
}

class _ModelMonitoringScreenState extends State<ModelMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  final _models = [
    _Model('DERNet v2.1', 'Brain MRI', 96.8, 0.043, 0.971, 0.965, 0.968, NVColors.researcherColor, true),
    _Model('SegResNet', 'Brain MRI', 94.2, 0.062, 0.948, 0.937, 0.942, NVColors.doctorColor, false),
    _Model('EfficientNetV2', 'Spine MRI', 91.5, 0.078, 0.922, 0.908, 0.915, NVColors.radiologistColor, false),
    _Model('Attention U-Net', 'Brain MRI', 93.7, 0.055, 0.941, 0.930, 0.935, NVColors.accent, false),
    _Model('DenseNet201', 'Spine MRI', 89.4, 0.091, 0.899, 0.884, 0.891, NVColors.secondary, false),
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return NVScaffold(
      currentRoute: '/dashboard/researcher/models',
      role: AppConstants.roleResearcher,
      title: 'Model Monitoring',
      subtitle: 'Real-time performance tracking and architecture comparison',
      userName: user?.name ?? 'Researcher',
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fade,
      body: Column(children: [
        NVTopBar(title: 'Model Monitoring', subtitle: 'Real-time performance tracking and architecture comparison', user: user?.name ?? 'Researcher', roleColor: NVColors.researcherColor),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildStats(),
            const SizedBox(height: 24),
            _buildLeaderboard(),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _buildRadarChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildRocCurve()),
                ]);
              }
              return Column(children: [
                _buildRadarChart(),
                const SizedBox(height: 16),
                _buildRocCurve(),
              ]);
            }),
          ]),
        )),
      ]),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(builder: (context, c) {
      return GridView.count(
        crossAxisCount: c.maxWidth > 800 ? 4 : 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: 1.6, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: const [
          NVStatCard(label: 'Models Deployed', value: '5', icon: Icons.model_training_rounded, color: NVColors.researcherColor, subtitle: 'Active pipelines'),
          NVStatCard(label: 'Best F1 Score', value: '0.968', icon: Icons.star_rounded, color: NVColors.warning, trend: '+0.012', trendPositive: true, subtitle: 'DERNet v2.1'),
          NVStatCard(label: 'Avg Inference', value: '1.8s', icon: Icons.speed_rounded, color: NVColors.success, subtitle: 'Per scan · GPU'),
          NVStatCard(label: 'Model Drift', value: 'Stable', icon: Icons.monitor_heart_rounded, color: NVColors.info, subtitle: 'No degradation'),
        ],
      );
    });
  }

  Widget _buildLeaderboard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.leaderboard_rounded, color: NVColors.researcherColor, size: 18), SizedBox(width: 8), Text('Model Leaderboard', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const SizedBox(width: 28),
                Expanded(flex: 3, child: const Text('Model', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                if (isWide) Expanded(flex: 2, child: const Text('Modality', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: const Text('Accuracy', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                if (isWide) Expanded(flex: 2, child: const Text('Loss', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: const Text('F1 Score', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: const Text('Performance', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 4),
            ..._models.asMap().entries.map((entry) {
              final i = entry.key; final m = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: i == 0 ? m.color.withValues(alpha: 0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: i == 0 ? Border.all(color: m.color.withValues(alpha: 0.2)) : null,
                ),
                child: Row(children: [
                  SizedBox(width: 28, child: i == 0
                      ? const Icon(Icons.emoji_events_rounded, color: NVColors.warning, size: 18)
                      : Text('${i + 1}', style: const TextStyle(color: NVColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: m.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(m.name, style: TextStyle(color: i == 0 ? NVColors.textPrimary : NVColors.textSecondary, fontWeight: i == 0 ? FontWeight.w700 : FontWeight.normal, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ])),
                  if (isWide) Expanded(flex: 2, child: Text(m.modality, style: const TextStyle(color: NVColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2, child: Text('${m.accuracy}%', style: TextStyle(color: m.color, fontWeight: FontWeight.bold, fontSize: 12))),
                  if (isWide) Expanded(flex: 2, child: Text(m.loss.toString(), style: TextStyle(color: NVColors.error.withValues(alpha: 0.8), fontSize: 12))),
                  Expanded(flex: 2, child: Text(m.f1.toStringAsFixed(3), style: TextStyle(color: m.color, fontWeight: FontWeight.w600, fontSize: 12))),
                  Expanded(flex: 3, child: Row(children: [
                    Expanded(child: LinearProgressIndicator(value: m.accuracy / 100, backgroundColor: NVColors.border, valueColor: AlwaysStoppedAnimation<Color>(m.color), minHeight: 5, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 6),
                    Text('${m.accuracy}%', style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
                  ])),
                ]),
              );
            }),
          ]);
        }),
      ]),
    );
  }

  Widget _buildRadarChart() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.radar_rounded, color: NVColors.researcherColor, size: 18), SizedBox(width: 8), Text('Performance Radar', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))]),
        const SizedBox(height: 8),
        const Text('Top 3 models · Accuracy / Precision / Recall / F1 / Speed', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
        const SizedBox(height: 16),
        SizedBox(height: 240, child: RadarChart(
          RadarChartData(
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            radarBorderData: const BorderSide(color: NVColors.border, width: 0.5),
            gridBorderData: const BorderSide(color: NVColors.border, width: 0.3),
            tickCount: 4,
            ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
            getTitle: (index, angle) {
              const titles = ['Accuracy', 'Precision', 'Recall', 'F1', 'Speed', 'Stability'];
              return RadarChartTitle(text: index < titles.length ? titles[index] : '', angle: angle, positionPercentageOffset: 0.15);
            },
            titleTextStyle: const TextStyle(color: NVColors.textMuted, fontSize: 10),
            dataSets: [
              RadarDataSet(dataEntries: const [RadarEntry(value: 9.68), RadarEntry(value: 9.71), RadarEntry(value: 9.65), RadarEntry(value: 9.68), RadarEntry(value: 8.5), RadarEntry(value: 9.2)],
                  fillColor: NVColors.researcherColor.withValues(alpha: 0.15), borderColor: NVColors.researcherColor, borderWidth: 2, entryRadius: 3),
              RadarDataSet(dataEntries: const [RadarEntry(value: 9.42), RadarEntry(value: 9.48), RadarEntry(value: 9.37), RadarEntry(value: 9.42), RadarEntry(value: 8.8), RadarEntry(value: 8.9)],
                  fillColor: NVColors.doctorColor.withValues(alpha: 0.1), borderColor: NVColors.doctorColor, borderWidth: 2, entryRadius: 3),
              RadarDataSet(dataEntries: const [RadarEntry(value: 9.15), RadarEntry(value: 9.22), RadarEntry(value: 9.08), RadarEntry(value: 9.15), RadarEntry(value: 9.2), RadarEntry(value: 8.5)],
                  fillColor: NVColors.radiologistColor.withValues(alpha: 0.08), borderColor: NVColors.radiologistColor, borderWidth: 1.5, entryRadius: 2),
            ],
          ),
        )),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Leg(color: NVColors.researcherColor, label: 'DERNet v2.1'),
          const SizedBox(width: 16),
          _Leg(color: NVColors.doctorColor, label: 'SegResNet'),
          const SizedBox(width: 16),
          _Leg(color: NVColors.radiologistColor, label: 'EfficientNetV2'),
        ]),
      ]),
    );
  }

  Widget _buildRocCurve() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.show_chart_rounded, color: NVColors.researcherColor, size: 18), SizedBox(width: 8), Text('ROC Curves', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))]),
        const SizedBox(height: 4),
        const Text('True Positive Rate vs False Positive Rate', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: LineChart(LineChartData(
          gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: NVColors.border, strokeWidth: 0.5)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(color: NVColors.textMuted, fontSize: 9)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(color: NVColors.textMuted, fontSize: 9)))),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: 1, minY: 0, maxY: 1,
          lineBarsData: [
            // Random classifier baseline
            LineChartBarData(spots: const [FlSpot(0, 0), FlSpot(1, 1)], color: NVColors.border, barWidth: 1, dashArray: [4, 4], dotData: const FlDotData(show: false)),
            // DERNet
            LineChartBarData(spots: const [FlSpot(0, 0), FlSpot(0.05, 0.72), FlSpot(0.1, 0.88), FlSpot(0.2, 0.94), FlSpot(0.4, 0.97), FlSpot(1, 1)], isCurved: true, color: NVColors.researcherColor, barWidth: 2.5, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [NVColors.researcherColor.withValues(alpha: 0.1), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            // SegResNet
            LineChartBarData(spots: const [FlSpot(0, 0), FlSpot(0.08, 0.65), FlSpot(0.15, 0.82), FlSpot(0.25, 0.90), FlSpot(0.5, 0.95), FlSpot(1, 1)], isCurved: true, color: NVColors.doctorColor, barWidth: 2, dotData: const FlDotData(show: false)),
          ],
        ))),
        const SizedBox(height: 12),
        _AucRow(model: 'DERNet v2.1', auc: 0.987, color: NVColors.researcherColor),
        _AucRow(model: 'SegResNet', auc: 0.971, color: NVColors.doctorColor),
      ]),
    );
  }
}

class _Model {
  final String name, modality;
  final double accuracy, loss, precision, recall, f1;
  final Color color;
  final bool isDeployed;
  _Model(this.name, this.modality, this.accuracy, this.loss, this.precision, this.recall, this.f1, this.color, this.isDeployed);
}

class _Leg extends StatelessWidget {
  final Color color; final String label;
  const _Leg({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 2, color: color), const SizedBox(width: 5), Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10))]);
}

class _AucRow extends StatelessWidget {
  final String model; final double auc; final Color color;
  const _AucRow({required this.model, required this.auc, required this.color});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Container(width: 8, height: 2, color: color), const SizedBox(width: 6), Text(model, style: const TextStyle(color: NVColors.textSecondary, fontSize: 11)), const Spacer(), Text('AUC: ${auc.toStringAsFixed(3)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11))]));
}
