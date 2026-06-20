// lib/src/ui/screens/dashboard/researcher/dataset_management_screen.dart
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

// ──────────────────────────── Data models ─────────────────────────────────

class _Dataset {
  final String name;
  final String modality;
  final int samples;
  final double trainRatio;
  final double valRatio;
  final double testRatio;
  final Color color;

  const _Dataset(this.name, this.modality, this.samples, this.trainRatio,
      this.valRatio, this.testRatio, this.color);

  int get trainCount => (samples * trainRatio).round();
  int get valCount => (samples * valRatio).round();
  int get testCount => (samples * testRatio).round();
}

class _PieSlice {
  final String label;
  final int count;
  final Color color;
  const _PieSlice(this.label, this.count, this.color);
  double get pct => count / 14200 * 100;
}

// ──────────────────────────── Screen ──────────────────────────────────────

class DatasetManagementScreen extends StatefulWidget {
  const DatasetManagementScreen({super.key});

  @override
  State<DatasetManagementScreen> createState() =>
      _DatasetManagementScreenState();
}

class _DatasetManagementScreenState extends State<DatasetManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  int _selectedDatasetIndex = 0;
  int _touchedPieIndex = -1;

  static const _datasets = [
    _Dataset('BrainMRI-v3', 'Brain MRI', 14200, 0.70, 0.15, 0.15,
        NVColors.researcherColor),
    _Dataset('SpineMRI-v2', 'Spine MRI', 9800, 0.70, 0.15, 0.15,
        NVColors.doctorColor),
    _Dataset('ChestXR-v1', 'Chest X-Ray', 12400, 0.75, 0.12, 0.13,
        NVColors.radiologistColor),
    _Dataset('CTScan-v1', 'CT Scan', 6200, 0.70, 0.15, 0.15,
        NVColors.warning),
    _Dataset('StrokeMRI-v1', 'Brain MRI', 5400, 0.72, 0.13, 0.15,
        NVColors.error),
    _Dataset('GliomaSeg-v2', 'Brain MRI', 3120, 0.68, 0.16, 0.16,
        NVColors.secondary),
  ];

  // Pie data for BrainMRI-v3 (always shown for selected dataset)
  static const _pieSlices = [
    _PieSlice('Normal', 4200, NVColors.success),
    _PieSlice('Ischemic Stroke', 3800, NVColors.researcherColor),
    _PieSlice('Glioblastoma', 2900, NVColors.info),
    _PieSlice('Hemorrhage', 1800, NVColors.error),
    _PieSlice('Other', 1500, NVColors.textMuted),
  ];

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

  _Dataset get _selected => _datasets[_selectedDatasetIndex];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return NVScaffold(
      currentRoute: '/dashboard/researcher/datasets',
      role: AppConstants.roleResearcher,
      title: 'Dataset Management',
      subtitle: 'Dataset analytics, class distribution & train/validation/test split management',
      userName: user?.name ?? 'Researcher',
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fade,
      body: Column(
        children: [
          NVTopBar(
            title: 'Dataset Management',
            subtitle: 'Dataset analytics, class distribution & train/validation/test split management',
            user: user?.name ?? 'Researcher',
            roleColor: NVColors.researcherColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildDatasetsSection(),
                  const SizedBox(height: 24),
                  _buildDetailRow(),
                  const SizedBox(height: 24),
                  _buildQualityReport(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final count = w > 800 ? 4 : (w > 400 ? 2 : 1);
      final itemWidth = w / count;
      final ratio = w > 400 ? 1.6 : (itemWidth / 160.0);
      return GridView.count(
        crossAxisCount: count,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ratio,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          NVStatCard(
            label: 'Total Datasets',
            value: '14',
            icon: Icons.storage_rounded,
            color: NVColors.researcherColor,
          ),
          NVStatCard(
            label: 'Total Samples',
            value: '48,320',
            icon: Icons.grid_view_rounded,
            color: NVColors.doctorColor,
            subtitle: 'All modalities',
          ),
          NVStatCard(
            label: 'Class Balance',
            value: '87.4%',
            icon: Icons.balance_rounded,
            color: NVColors.success,
            subtitle: 'Moderate balance',
          ),
          NVStatCard(
            label: 'Augmented',
            value: '31,240',
            icon: Icons.auto_fix_high_rounded,
            color: NVColors.warning,
            subtitle: 'Augmented samples',
          ),
        ],
      );
    });
  }

  // ── Datasets Section ──────────────────────────────────────────────────────

  Widget _buildDatasetsSection() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.dataset_rounded, color: NVColors.researcherColor, size: 18),
              const SizedBox(width: 8),
              const Text('Datasets', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(Icons.upload_rounded, size: 15, color: Colors.black),
                label: const Text('Import New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NVColors.researcherColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dataset cards grid - responsive
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final count = w > 700 ? 3 : w > 400 ? 2 : 1;
            final itemWidth = w / count;
            final ratio = w > 400 ? (w > 700 ? 1.55 : 1.4) : (itemWidth / 180.0);
            return GridView.count(
              crossAxisCount: count,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: ratio,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(_datasets.length, (i) => _DatasetCard(
                dataset: _datasets[i],
                isSelected: _selectedDatasetIndex == i,
                onTap: () => setState(() => _selectedDatasetIndex = i),
                onAnalyze: () => setState(() => _selectedDatasetIndex = i),
              )),
            );
          }),
        ],
      ),
    );
  }

  // ── Detail Row ────────────────────────────────────────────────────────────

  Widget _buildDetailRow() {
    final ds = _selected;
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      if (isWide) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _buildClassDistribution()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildSplitPanel(ds)),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildDatasetInfo(ds)),
            ],
          ),
        );
      }
      return Column(children: [
        _buildClassDistribution(),
        const SizedBox(height: 16),
        _buildSplitPanel(ds),
        const SizedBox(height: 16),
        _buildDatasetInfo(ds),
      ]);
    });
  }

  Widget _buildClassDistribution() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.pie_chart_rounded,
                color: NVColors.researcherColor, size: 16),
            const SizedBox(width: 8),
            Text(
              'Class Distribution · ${_selected.name}',
              style: const TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: List.generate(_pieSlices.length, (i) {
                  final s = _pieSlices[i];
                  final isTouched = i == _touchedPieIndex;
                  return PieChartSectionData(
                    color: s.color,
                    value: s.count.toDouble(),
                    radius: isTouched ? 58 : 50,
                    title: isTouched
                        ? '${s.pct.toStringAsFixed(1)}%'
                        : '',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _pieSlices.map((s) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${s.label} (${_formatNum(s.count)})',
                    style: const TextStyle(
                        color: NVColors.textSecondary, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPanel(_Dataset ds) {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.call_split_rounded,
                color: NVColors.doctorColor, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Train / Val / Test Split',
              style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ]),
          const SizedBox(height: 16),
          // 3 big metric boxes
          Row(
            children: [
              _SplitMetric(
                  label: 'TRAIN',
                  count: ds.trainCount,
                  pct: (ds.trainRatio * 100).round(),
                  color: NVColors.researcherColor),
              const SizedBox(width: 10),
              _SplitMetric(
                  label: 'VAL',
                  count: ds.valCount,
                  pct: (ds.valRatio * 100).round(),
                  color: NVColors.doctorColor),
              const SizedBox(width: 10),
              _SplitMetric(
                  label: 'TEST',
                  count: ds.testCount,
                  pct: (ds.testRatio * 100).round(),
                  color: NVColors.warning),
            ],
          ),
          const SizedBox(height: 14),
          // Horizontal progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (ds.trainRatio * 100).round(),
                    child: Container(color: NVColors.researcherColor),
                  ),
                  Expanded(
                    flex: (ds.valRatio * 100).round(),
                    child: Container(color: NVColors.doctorColor),
                  ),
                  Expanded(
                    flex: (ds.testRatio * 100).round(),
                    child: Container(color: NVColors.warning),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Labels under bar
          Row(
            children: [
              Expanded(
                  flex: (ds.trainRatio * 100).round(),
                  child: const Text('Train',
                      style: TextStyle(
                          color: NVColors.researcherColor, fontSize: 9))),
              Expanded(
                  flex: (ds.valRatio * 100).round(),
                  child: const Text('Val',
                      style: TextStyle(
                          color: NVColors.doctorColor, fontSize: 9))),
              Expanded(
                  flex: (ds.testRatio * 100).round(),
                  child: const Text('Test',
                      style:
                          TextStyle(color: NVColors.warning, fontSize: 9))),
            ],
          ),
          const SizedBox(height: 16),
          // Bar chart — samples per class
          SizedBox(
            height: 180,
            child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 4500,
                  barTouchData: BarTouchData(enabled: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        const FlLine(color: NVColors.border, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, m) => Text(
                          '${(v / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(
                              color: NVColors.textMuted, fontSize: 8),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          const labels = [
                            'Normal',
                            'Ischemic',
                            'Glio.',
                            'Hemor.',
                            'Other'
                          ];
                          final idx = v.toInt();
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox();
                          }
                          return Text(labels[idx],
                              style: const TextStyle(
                                  color: NVColors.textMuted, fontSize: 8));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(_pieSlices.length, (i) {
                    final s = _pieSlices[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (s.count * ds.trainRatio).roundToDouble(),
                          color: NVColors.researcherColor,
                          width: 5,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: (s.count * ds.valRatio).roundToDouble(),
                          color: NVColors.doctorColor,
                          width: 5,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: (s.count * ds.testRatio).roundToDouble(),
                          color: NVColors.warning,
                          width: 5,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegDot(color: NVColors.researcherColor, label: 'Train'),
              const SizedBox(width: 12),
              _LegDot(color: NVColors.doctorColor, label: 'Val'),
              const SizedBox(width: 12),
              _LegDot(color: NVColors.warning, label: 'Test'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatasetInfo(_Dataset ds) {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: NVColors.secondary, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Dataset Info',
              style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ]),
          const SizedBox(height: 16),
          _InfoRow(label: 'Name', value: ds.name),
          _InfoRow(label: 'Version', value: 'v3.0'),
          _InfoRow(label: 'Created', value: 'Jan 2026'),
          _InfoRow(label: 'Last Updated', value: 'May 2026'),
          _InfoRow(label: 'Format', value: 'DICOM / NIfTI'),
          _InfoRow(label: 'Modality', value: ds.modality),
          _InfoRow(
              label: 'Augmentations', value: 'Flip, Rotate, Noise'),
          _InfoRow(label: 'Annotation', value: 'Semi-automated'),
          const SizedBox(height: 16),
          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSnack('Preparing download…'),
              icon: const Icon(Icons.download_rounded, size: 15),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NVColors.researcherColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteDialog(ds.name),
              icon: const Icon(Icons.delete_outline_rounded, size: 15),
              label: const Text('Delete Dataset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: NVColors.error,
                side: const BorderSide(color: NVColors.error),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quality Report ────────────────────────────────────────────────────────

  Widget _buildQualityReport() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: NVColors.info, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quality Analysis',
                        style: TextStyle(
                            color: NVColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text('Automated quality checks',
                        style: TextStyle(
                            color: NVColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: NVColors.researcherColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          NVColors.researcherColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: NVColors.researcherColor, size: 13),
                    SizedBox(width: 4),
                    Text('Re-run Checks',
                        style: TextStyle(
                            color: NVColors.researcherColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: NVColors.border, height: 1),
          const SizedBox(height: 12),
          _QualityRow(
            icon: Icons.rule_rounded,
            label: 'Missing Values',
            detail: '0.3% across all fields',
            status: 'Good',
            statusColor: NVColors.success,
          ),
          _QualityRow(
            icon: Icons.content_copy_rounded,
            label: 'Duplicate Images',
            detail: '12 found in dataset',
            status: 'Warning',
            statusColor: NVColors.warning,
            actionLabel: 'Resolve',
            onAction: () => _showSnack('Resolving duplicates…'),
          ),
          _QualityRow(
            icon: Icons.balance_rounded,
            label: 'Class Imbalance',
            detail: 'Moderate — ratio 1:2.8',
            status: 'Warning',
            statusColor: NVColors.warning,
          ),
          _QualityRow(
            icon: Icons.draw_rounded,
            label: 'Annotation Quality',
            detail: '94.7% inter-annotator agreement',
            status: 'Good',
            statusColor: NVColors.success,
          ),
        ],
      ),
    );
  }

  // ── Dialogs & helpers ─────────────────────────────────────────────────────

  void _showImportDialog() {
    final nameCtrl = TextEditingController();
    String selectedModality = 'Brain MRI';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: NVColors.bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: NVColors.border)),
          title: const Row(children: [
            Icon(Icons.upload_rounded,
                color: NVColors.researcherColor, size: 20),
            SizedBox(width: 8),
            Text('Import New Dataset',
                style: TextStyle(color: NVColors.textPrimary, fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: NVColors.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Dataset Name',
                    hintText: 'e.g. BrainMRI-v4'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedModality,
                dropdownColor: NVColors.bgCard,
                style: const TextStyle(
                    color: NVColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Modality'),
                items: AppConstants.modalities
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setS(() => selectedModality = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: NVColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showSnack('Dataset import queued');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: NVColors.researcherColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NVColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NVColors.error)),
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: NVColors.error, size: 20),
          SizedBox(width: 8),
          Text('Delete Dataset',
              style: TextStyle(color: NVColors.error, fontSize: 16)),
        ]),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
          style: const TextStyle(color: NVColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: NVColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Dataset "$name" deleted');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: NVColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: NVColors.researcherColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ──────────────────────────── Sub-widgets ─────────────────────────────────

class _DatasetCard extends StatelessWidget {
  final _Dataset dataset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onAnalyze;

  const _DatasetCard({
    required this.dataset,
    required this.isSelected,
    required this.onTap,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final ds = dataset;
    return NVGlassCard(
      hoverable: true,
      padding: const EdgeInsets.all(14),
      borderColor:
          isSelected ? ds.color : NVColors.border,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + modality badge
          Row(
            children: [
              Expanded(
                child: Text(
                  ds.name,
                  style: TextStyle(
                    color: isSelected ? ds.color : NVColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ds.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ds.color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  ds.modality,
                  style: TextStyle(
                      color: ds.color,
                      fontSize: 8,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sample count
          Row(
            children: [
              Icon(Icons.photo_library_rounded,
                  color: NVColors.textMuted, size: 11),
              const SizedBox(width: 4),
              Text(
                '${_fmtNum(ds.samples)} samples',
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Split bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Split',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 9)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (ds.trainRatio * 100).round(),
                        child: Container(color: NVColors.researcherColor),
                      ),
                      Expanded(
                        flex: (ds.valRatio * 100).round(),
                        child: Container(color: NVColors.doctorColor),
                      ),
                      Expanded(
                        flex: (ds.testRatio * 100).round(),
                        child: Container(color: NVColors.warning),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                      '${(ds.trainRatio * 100).round()}% Train',
                      style: const TextStyle(
                          color: NVColors.researcherColor, fontSize: 8)),
                  const Text(' · ',
                      style: TextStyle(
                          color: NVColors.textMuted, fontSize: 8)),
                  Text('${(ds.valRatio * 100).round()}% Val',
                      style: const TextStyle(
                          color: NVColors.doctorColor, fontSize: 8)),
                  const Text(' · ',
                      style: TextStyle(
                          color: NVColors.textMuted, fontSize: 8)),
                  Text('${(ds.testRatio * 100).round()}% Test',
                      style: const TextStyle(
                          color: NVColors.warning, fontSize: 8)),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onAnalyze,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ds.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: ds.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Analyze',
                    style: TextStyle(
                        color: ds.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: NVColors.bgDeep,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: NVColors.border),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: NVColors.textMuted, size: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtNum(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }
}

class _SplitMetric extends StatelessWidget {
  final String label;
  final int count;
  final int pct;
  final Color color;

  const _SplitMetric(
      {required this.label,
      required this.count,
      required this.pct,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(
              count >= 1000
                  ? '${(count / 1000).toStringAsFixed(1)}k'
                  : '$count',
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text('$pct%',
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label,
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: NVColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final String status;
  final Color statusColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _QualityRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.status,
    required this.statusColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: NVColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                Text(detail,
                    style: const TextStyle(
                        color: NVColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NVColors.researcherColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: NVColors.researcherColor
                          .withValues(alpha: 0.35)),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                      color: NVColors.researcherColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: NVColors.textMuted, fontSize: 10)),
      ],
    );
  }
}
