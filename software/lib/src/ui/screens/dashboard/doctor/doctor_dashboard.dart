// lib/src/ui/screens/dashboard/doctor/doctor_dashboard.dart
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

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Mock data for demo
  final _recentCases = [
    _CaseItem('CASE-2026-047', 'Brain MRI', 'Ischemic Stroke', 94.2, 'Validated', NVColors.success),
    _CaseItem('CASE-2026-046', 'Spine MRI', 'L4-L5 Herniation', 88.7, 'In Review', NVColors.warning),
    _CaseItem('CASE-2026-045', 'Brain MRI', 'Glioblastoma', 96.1, 'Validated', NVColors.success),
    _CaseItem('CASE-2026-044', 'CT Scan', 'Intracranial Hemorrhage', 91.3, 'Pending', NVColors.info),
    _CaseItem('CASE-2026-043', 'Chest X-Ray', 'Pneumonia', 87.5, 'Validated', NVColors.success),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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
      currentRoute: '/dashboard/doctor',
      role: AppConstants.roleDoctor,
      title: 'Doctor Dashboard',
      subtitle: 'AI Diagnosis Review & Case Management',
      userName: user?.name ?? 'Doctor',
      roleColor: NVColors.doctorColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'Doctor Dashboard',
            subtitle: 'AI Diagnosis Review & Case Management',
            user: user?.name ?? 'Doctor',
            roleColor: NVColors.doctorColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(user?.name ?? 'Doctor'),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildMainGrid(),
                  const SizedBox(height: 20),
                  _buildRecentCases(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)], // Deep Teal Gradients
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.medical_information_rounded, size: 100, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, Dr. $name', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              const Text('You have 12 pending AI diagnoses awaiting your clinical validation today.', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
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
        final aspectRatio = w > 700 ? 1.7 : w > 380 ? 1.5 : (w / 160.0);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            NVStatCard(
              label: 'Cases Reviewed',
              value: '248',
              icon: Icons.cases_rounded,
              color: NVColors.doctorColor,
              trend: '+18%',
              trendPositive: true,
              subtitle: 'This month',
            ),
            NVStatCard(
              label: 'AI Diagnoses Validated',
              value: '196',
              icon: Icons.verified_rounded,
              color: NVColors.success,
              trend: '+9%',
              trendPositive: true,
              subtitle: '79% validation rate',
            ),
            NVStatCard(
              label: 'Pending Review',
              value: '12',
              icon: Icons.pending_rounded,
              color: NVColors.warning,
              subtitle: 'Awaiting your action',
            ),
            NVStatCard(
              label: 'Avg. Confidence',
              value: '92.4%',
              icon: Icons.psychology_rounded,
              color: NVColors.secondary,
              trend: '+2.1%',
              trendPositive: true,
              subtitle: 'AI model accuracy',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildDiagnosisChart()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildModalityBreakdown()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildDiagnosisChart(),
              const SizedBox(height: 16),
              _buildModalityBreakdown(),
            ],
          );
        }
      },
    );
  }

  Widget _buildDiagnosisChart() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: NVColors.doctorColor, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Monthly Case Review Trend',
                  style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NVColors.bgCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: NVColors.border),
                ),
                child: const Text('6 months', style: TextStyle(color: NVColors.textMuted, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: NVColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(color: NVColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        const months = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'];
                        final i = v.toInt();
                        if (i >= 0 && i < months.length) {
                          return Text(months[i], style: const TextStyle(color: NVColors.textMuted, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 38), FlSpot(1, 45), FlSpot(2, 52), FlSpot(3, 41), FlSpot(4, 58), FlSpot(5, 62),
                    ],
                    isCurved: true,
                    color: NVColors.doctorColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: NVColors.doctorColor,
                        strokeWidth: 2,
                        strokeColor: NVColors.bgDeep,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [NVColors.doctorColor.withValues(alpha: 0.15), NVColors.doctorColor.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 30), FlSpot(1, 35), FlSpot(2, 42), FlSpot(3, 35), FlSpot(4, 48), FlSpot(5, 52),
                    ],
                    isCurved: true,
                    color: NVColors.success,
                    barWidth: 2,
                    dashArray: [5, 3],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: NVColors.doctorColor, label: 'Cases Reviewed'),
              const SizedBox(width: 20),
              _LegendItem(color: NVColors.success, label: 'Validated'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalityBreakdown() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.donut_large_rounded, color: NVColors.doctorColor, size: 18),
              SizedBox(width: 8),
              Text('Imaging Modality', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                sections: [
                  PieChartSectionData(value: 42, color: NVColors.doctorColor, title: '42%', radius: 40, titleStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 31, color: NVColors.secondary, title: '31%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 18, color: NVColors.accent, title: '18%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  PieChartSectionData(value: 9, color: NVColors.warning, title: '9%', radius: 40, titleStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ModalityLegend(color: NVColors.doctorColor, label: 'Brain MRI', value: '42%'),
          _ModalityLegend(color: NVColors.secondary, label: 'Spine MRI', value: '31%'),
          _ModalityLegend(color: NVColors.accent, label: 'Chest X-Ray', value: '18%'),
          _ModalityLegend(color: NVColors.warning, label: 'CT Scan', value: '9%'),
        ],
      ),
    );
  }

  Widget _buildRecentCases() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: NVColors.doctorColor, size: 18),
              const SizedBox(width: 8),
              const Text('Recent AI Diagnoses', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: NVColors.doctorColor, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile)
            // Mobile: card-list layout
            Column(
              children: _recentCases.map((c) => _MobileCaseCard(item: c)).toList(),
            )
          else ...[
            // Desktop: table layout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: NVColors.bgDeep,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Case ID', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Modality', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 3, child: Text('AI Prediction', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Confidence', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ..._recentCases.map((c) => _CaseRow(item: c)),
          ],
        ],
      ),
    );
  }
}

class _CaseItem {
  final String caseId;
  final String modality;
  final String prediction;
  final double confidence;
  final String status;
  final Color statusColor;

  _CaseItem(this.caseId, this.modality, this.prediction, this.confidence, this.status, this.statusColor);
}

// Mobile card version
class _MobileCaseCard extends StatelessWidget {
  final _CaseItem item;
  const _MobileCaseCard({required this.item});

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
              Flexible(child: Text(item.caseId, style: const TextStyle(color: NVColors.primary, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
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
          Text(item.modality, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(item.prediction, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${item.confidence}%', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: item.confidence / 100,
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

class _CaseRow extends StatelessWidget {
  final _CaseItem item;
  const _CaseRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border(bottom: BorderSide(color: NVColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(item.caseId, style: const TextStyle(color: NVColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(item.modality, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(item.prediction, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text('${item.confidence}%', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Expanded(
                  child: LinearProgressIndicator(
                    value: item.confidence / 100,
                    backgroundColor: NVColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(item.statusColor),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
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
              child: Text(
                item.status,
                style: TextStyle(color: item.statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _ModalityLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _ModalityLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12))),
          Text(value, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
