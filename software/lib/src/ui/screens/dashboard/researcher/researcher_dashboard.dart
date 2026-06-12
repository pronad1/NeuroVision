// lib/src/ui/screens/dashboard/researcher/researcher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_stat_card.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_top_bar.dart';

class ResearcherDashboard extends StatefulWidget {
  const ResearcherDashboard({super.key});

  @override
  State<ResearcherDashboard> createState() => _ResearcherDashboardState();
}

class _ResearcherDashboardState extends State<ResearcherDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _experiments = [
    _Experiment('EXP-2026-014', 'DERNet v2.1', 'Brain MRI', 96.8, 'Completed', NVColors.success),
    _Experiment('EXP-2026-013', 'SegResNet', 'Brain MRI', 94.2, 'Completed', NVColors.success),
    _Experiment('EXP-2026-012', 'EfficientNetV2', 'Spine MRI', 91.5, 'Running', NVColors.primary),
    _Experiment('EXP-2026-011', 'Attention U-Net', 'Brain MRI', 93.7, 'Paused', NVColors.warning),
    _Experiment('EXP-2026-010', 'DenseNet201', 'Spine MRI', 89.4, 'Completed', NVColors.success),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<NVAuthProvider>(context);
    final user = auth.nvUser;

    return NVScaffold(
      currentRoute: '/dashboard/researcher',
      role: AppConstants.roleResearcher,
      title: 'Researcher Dashboard',
      subtitle: 'Model Monitoring, Experiments & AI Performance',
      userName: user?.name ?? 'Researcher',
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'Researcher Dashboard',
            subtitle: 'Model Monitoring, Experiments & AI Performance',
            user: user?.name ?? 'Researcher',
            roleColor: NVColors.researcherColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildModelsSection(),
                  const SizedBox(height: 24),
                  _buildBottomGrid(),
                  const SizedBox(height: 24),
                  _buildExperimentsTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 900 ? 1.7 : 1.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            NVStatCard(
              label: 'Active Experiments',
              value: '7',
              icon: Icons.science_rounded,
              color: NVColors.researcherColor,
              subtitle: '2 running now',
            ),
            NVStatCard(
              label: 'Best Model Accuracy',
              value: '96.8%',
              icon: Icons.emoji_events_rounded,
              color: NVColors.warning,
              trend: '+1.4%',
              trendPositive: true,
              subtitle: 'DERNet v2.1',
            ),
            NVStatCard(
              label: 'Datasets Analyzed',
              value: '14',
              icon: Icons.storage_rounded,
              color: NVColors.doctorColor,
              subtitle: '48,320 samples total',
            ),
            NVStatCard(
              label: 'GPU Utilization',
              value: '73%',
              icon: Icons.memory_rounded,
              color: NVColors.secondary,
              subtitle: 'NVIDIA A100 · 2 GPUs',
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelsSection() {
    final models = [
      ('DERNet v2.1', 'Brain MRI', 96.8, 0.043, NVColors.researcherColor, 'Best'),
      ('SegResNet', 'Brain MRI', 94.2, 0.062, NVColors.doctorColor, null),
      ('EfficientNetV2', 'Spine MRI', 91.5, 0.078, NVColors.radiologistColor, 'Running'),
      ('Attention U-Net', 'Brain MRI', 93.7, 0.055, NVColors.accent, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.leaderboard_rounded, color: NVColors.researcherColor, size: 18),
            SizedBox(width: 8),
            Text('Model Performance Leaderboard', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final count = constraints.maxWidth > 800 ? 4 : 2;
          return GridView.count(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: models.map((m) => _ModelCard(
              name: m.$1,
              modality: m.$2,
              accuracy: m.$3,
              loss: m.$4,
              color: m.$5,
              badge: m.$6,
            )).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildBottomGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 750;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildTrainingCurveCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildConfusionMatrixCard()),
          ],
        );
      }
      return Column(children: [_buildTrainingCurveCard(), const SizedBox(height: 16), _buildConfusionMatrixCard()]);
    });
  }

  Widget _buildTrainingCurveCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: NVColors.researcherColor, size: 18),
              SizedBox(width: 8),
              Text('DERNet v2.1 Training Curve', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(color: NVColors.border, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(0)}%', style: const TextStyle(color: NVColors.textMuted, fontSize: 9)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Text('Ep ${v.toInt()}', style: const TextStyle(color: NVColors.textMuted, fontSize: 9)),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Training accuracy
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 72), FlSpot(5, 82), FlSpot(10, 88), FlSpot(15, 92), FlSpot(20, 94), FlSpot(25, 95.5), FlSpot(30, 96.8),
                    ],
                    isCurved: true,
                    color: NVColors.researcherColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [NVColors.researcherColor.withValues(alpha: 0.12), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Validation accuracy
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 68), FlSpot(5, 79), FlSpot(10, 85), FlSpot(15, 89), FlSpot(20, 91.5), FlSpot(25, 93), FlSpot(30, 94.2),
                    ],
                    isCurved: true,
                    color: NVColors.doctorColor,
                    barWidth: 2,
                    dashArray: [4, 3],
                    dotData: const FlDotData(show: false),
                  ),
                  // Loss
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 52), FlSpot(5, 38), FlSpot(10, 22), FlSpot(15, 14), FlSpot(20, 9), FlSpot(25, 6), FlSpot(30, 4.3),
                    ],
                    isCurved: true,
                    color: NVColors.error,
                    barWidth: 1.5,
                    dashArray: [2, 3],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              _LegendDot(color: NVColors.researcherColor, label: 'Train Acc'),
              _LegendDot(color: NVColors.doctorColor, label: 'Val Acc'),
              _LegendDot(color: NVColors.error, label: 'Loss'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfusionMatrixCard() {
    // Simplified 3x3 confusion matrix: Normal / Lesion / Tumor
    final matrix = [
      [142, 8, 3],
      [12, 198, 6],
      [2, 4, 156],
    ];
    final labels = ['Normal', 'Lesion', 'Tumor'];

    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_on_rounded, color: NVColors.researcherColor, size: 18),
              SizedBox(width: 8),
              Text('Confusion Matrix', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('DERNet v2.1 · Brain MRI Test Set', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          // Column labels
          Row(
            children: [
              const SizedBox(width: 60),
              ...labels.map((l) => Expanded(
                child: Center(
                  child: Text(l, style: const TextStyle(color: NVColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              )),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(3, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(labels[row], style: const TextStyle(color: NVColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  ...List.generate(3, (col) {
                    final val = matrix[row][col];
                    final isCorrect = row == col;
                    final maxVal = 198.0;
                    final intensity = val / maxVal;
                    return Expanded(
                      child: Container(
                        height: 52,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? NVColors.researcherColor.withValues(alpha: 0.1 + intensity * 0.5)
                              : NVColors.error.withValues(alpha: intensity * 0.4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCorrect
                                ? NVColors.researcherColor.withValues(alpha: 0.3)
                                : NVColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              val.toString(),
                              style: TextStyle(
                                color: isCorrect ? NVColors.researcherColor : NVColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              _MatrixLegend(color: NVColors.researcherColor, label: 'Correct'),
              const SizedBox(width: 16),
              _MatrixLegend(color: NVColors.error, label: 'Misclassified'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentsTable() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, color: NVColors.researcherColor, size: 18),
              const SizedBox(width: 8),
              const Text('Experiment Runs', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Run'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NVColors.researcherColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Column(children: _experiments.map((e) => _MobileExperimentCard(item: e)).toList())
          else ...[  
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Experiment ID', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Model', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Modality', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Accuracy', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ..._experiments.map((e) => _ExperimentRow(item: e)),
          ],
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String name;
  final String modality;
  final double accuracy;
  final double loss;
  final Color color;
  final String? badge;

  const _ModelCard({
    required this.name,
    required this.modality,
    required this.accuracy,
    required this.loss,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return NVGlassCard(
      hoverable: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(name, style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(badge!, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(modality, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const Spacer(),
          Text(
            '${accuracy.toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const Text('Accuracy', style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: accuracy / 100,
            backgroundColor: NVColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Text('Loss: ${loss.toStringAsFixed(3)}', style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _Experiment {
  final String id;
  final String model;
  final String modality;
  final double accuracy;
  final String status;
  final Color statusColor;
  _Experiment(this.id, this.model, this.modality, this.accuracy, this.status, this.statusColor);
}

class _MobileExperimentCard extends StatelessWidget {
  final _Experiment item;
  const _MobileExperimentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NVColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.id, style: const TextStyle(color: NVColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: item.statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(item.status, style: TextStyle(color: item.statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${item.model} · ${item.modality}', style: const TextStyle(color: NVColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${item.accuracy}%', style: const TextStyle(color: NVColors.researcherColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: item.accuracy / 100,
                  backgroundColor: NVColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(item.statusColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExperimentRow extends StatelessWidget {
  final _Experiment item;
  const _ExperimentRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: NVColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(item.id, style: const TextStyle(color: NVColors.primary, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text(item.model, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12))),
          Expanded(flex: 2, child: Text(item.modality, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12))),
          Expanded(
            flex: 2,
            child: Text(
              '${item.accuracy}%',
              style: const TextStyle(color: NVColors.researcherColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: item.statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(item.status, style: TextStyle(color: item.statusColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
        ],
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
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _MatrixLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _MatrixLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
