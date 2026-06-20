// lib/src/ui/screens/dashboard/radiologist/radiologist_dashboard.dart
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

class RadiologistDashboard extends StatefulWidget {
  const RadiologistDashboard({super.key});

  @override
  State<RadiologistDashboard> createState() => _RadiologistDashboardState();
}

class _RadiologistDashboardState extends State<RadiologistDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _touchedIndex = -1;

  final _pendingAnnotations = [
    _AnnotationItem('CASE-2026-047', 'Brain MRI', 'Lesion Boundary', 'High', NVColors.error),
    _AnnotationItem('CASE-2026-046', 'Spine MRI', 'Vertebral Segmentation', 'Medium', NVColors.warning),
    _AnnotationItem('CASE-2026-044', 'CT Scan', 'Hemorrhage Localization', 'High', NVColors.error),
    _AnnotationItem('CASE-2026-042', 'Brain MRI', 'Tumor Volume', 'Low', NVColors.success),
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
      currentRoute: '/dashboard/radiologist',
      role: AppConstants.roleRadiologist,
      title: 'Radiologist Dashboard',
      subtitle: 'DICOM Viewer, Annotations & Lesion Analysis',
      userName: user?.name ?? 'Radiologist',
      roleColor: NVColors.radiologistColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'Radiologist Dashboard',
            subtitle: 'DICOM Viewer, Annotations & Lesion Analysis',
            user: user?.name ?? 'Radiologist',
            roleColor: NVColors.radiologistColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildMainGrid(),
                  const SizedBox(height: 20),
                  _buildAnnotationQueue(),
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
        final w = constraints.maxWidth;
        final crossAxisCount = w > 700 ? 4 : w > 380 ? 2 : 1;
        final aspectRatio = w > 700
            ? 1.7
            : w > 380
                ? 1.5
                : (w / 160.0);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            NVStatCard(
              label: 'Images Annotated',
              value: '1,342',
              icon: Icons.draw_rounded,
              color: NVColors.radiologistColor,
              trend: '+22%',
              trendPositive: true,
              subtitle: 'This month',
            ),
            NVStatCard(
              label: 'Lesions Localized',
              value: '876',
              icon: Icons.location_searching_rounded,
              color: NVColors.doctorColor,
              trend: '+15%',
              trendPositive: true,
              subtitle: 'Confirmed regions',
            ),
            NVStatCard(
              label: 'Pending Annotations',
              value: '24',
              icon: Icons.pending_actions_rounded,
              color: NVColors.warning,
              subtitle: '4 high priority',
            ),
            NVStatCard(
              label: 'AI Agreement Rate',
              value: '87.3%',
              icon: Icons.handshake_rounded,
              color: NVColors.success,
              trend: '+3.4%',
              trendPositive: true,
              subtitle: 'vs radiologist marks',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildLesionHeatmapCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildAnnotationTypeChart()),
          ],
        );
      }
      return Column(children: [_buildLesionHeatmapCard(), const SizedBox(height: 16), _buildAnnotationTypeChart()]);
    });
  }

  Widget _buildLesionHeatmapCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.thermostat_rounded, color: NVColors.radiologistColor, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weekly Lesion Detection Accuracy',
                  style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(days[v.toInt()], style: const TextStyle(color: NVColors.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}%', style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(color: NVColors.border, strokeWidth: 0.5),
                ),
                barGroups: [
                  _barGroup(0, 84), _barGroup(1, 91), _barGroup(2, 88), _barGroup(3, 95),
                  _barGroup(4, 87), _barGroup(5, 76), _barGroup(6, 82),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: NVColors.radiologistColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('AI-Radiologist Agreement %', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y >= 90 ? NVColors.success : (y >= 80 ? NVColors.radiologistColor : NVColors.warning),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildAnnotationTypeChart() {
    final sections = [
      (38.0, 'Lesion Boundary', NVColors.radiologistColor),
      (28.0, 'Tumor Volume', NVColors.doctorColor),
      (22.0, 'Vertebral Seg.', NVColors.accent),
      (12.0, 'Hemorrhage', NVColors.error),
    ];

    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.donut_large_rounded, color: NVColors.radiologistColor, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Annotation Types', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (event, res) {
                    setState(() {
                      _touchedIndex = res?.touchedSection?.touchedSectionIndex ?? -1;
                    });
                  },
                ),
                sections: sections.asMap().entries.map((e) {
                  final isTouched = e.key == _touchedIndex;
                  return PieChartSectionData(
                    value: e.value.$1,
                    color: e.value.$3,
                    radius: isTouched ? 50 : 42,
                    title: '${e.value.$1.toInt()}%',
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...sections.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(s.$2, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12))),
                Text('${s.$1.toInt()}%', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAnnotationQueue() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.queue_rounded, color: NVColors.radiologistColor, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Annotation Queue', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NVColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NVColors.error.withValues(alpha: 0.3)),
                ),
                child: const Text('4 Pending', style: TextStyle(color: NVColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._pendingAnnotations.map((a) => _AnnotationRow(item: a)),
        ],
      ),
    );
  }
}

class _AnnotationItem {
  final String caseId;
  final String modality;
  final String task;
  final String priority;
  final Color priorityColor;
  _AnnotationItem(this.caseId, this.modality, this.task, this.priority, this.priorityColor);
}

class _AnnotationRow extends StatelessWidget {
  final _AnnotationItem item;
  const _AnnotationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NVColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_information_rounded, color: NVColors.radiologistColor.withValues(alpha: 0.7), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.caseId, style: const TextStyle(color: NVColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(item.priority, style: TextStyle(color: item.priorityColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${item.modality} · ${item.task}', style: const TextStyle(color: NVColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NVColors.radiologistColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Annotate'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(Icons.medical_information_rounded, color: NVColors.radiologistColor.withValues(alpha: 0.7), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.caseId, style: const TextStyle(color: NVColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${item.modality} · ${item.task}', style: const TextStyle(color: NVColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: item.priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(item.priority, style: TextStyle(color: item.priorityColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.radiologistColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Annotate'),
                ),
              ],
            ),
    );
  }
}
