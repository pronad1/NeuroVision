// lib/src/ui/screens/dashboard/researcher/gpu_monitor_screen.dart
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

class _GpuData {
  final String id;
  final String name;
  final double utilization; // 0.0 – 1.0
  final double vramUsed;    // GB
  final double vramTotal;   // GB
  final int tempC;
  final int powerW;
  final double tflops;
  final String jobId;
  final String jobModel;

  const _GpuData({
    required this.id,
    required this.name,
    required this.utilization,
    required this.vramUsed,
    required this.vramTotal,
    required this.tempC,
    required this.powerW,
    required this.tflops,
    required this.jobId,
    required this.jobModel,
  });
}

class _JobData {
  final String jobId;
  final String model;
  final String dataset;
  final String gpu;
  final String status;
  final double progress;
  final String eta;

  const _JobData({
    required this.jobId,
    required this.model,
    required this.dataset,
    required this.gpu,
    required this.status,
    required this.progress,
    required this.eta,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class GpuMonitorScreen extends StatefulWidget {
  const GpuMonitorScreen({super.key});

  @override
  State<GpuMonitorScreen> createState() => _GpuMonitorScreenState();
}

class _GpuMonitorScreenState extends State<GpuMonitorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  // Mock GPU data
  static const _gpus = [
    _GpuData(
      id: 'GPU 0',
      name: 'NVIDIA A100 80GB',
      utilization: 0.78,
      vramUsed: 28.4,
      vramTotal: 40.0,
      tempC: 68,
      powerW: 340,
      tflops: 9.7,
      jobId: 'JOB-2026-014',
      jobModel: 'DERNet v2.1',
    ),
    _GpuData(
      id: 'GPU 1',
      name: 'NVIDIA A100 80GB',
      utilization: 0.67,
      vramUsed: 24.0,
      vramTotal: 40.0,
      tempC: 62,
      powerW: 298,
      tflops: 8.4,
      jobId: 'JOB-2026-013',
      jobModel: 'EfficientNetV2',
    ),
  ];

  // VRAM history data points (GB)
  static const _gpu0Vram = <double>[
    24, 25, 26, 27, 28, 28, 29, 29, 28, 27,
    28, 29, 30, 29, 28, 28, 29, 28, 27, 28
  ];
  static const _gpu1Vram = <double>[
    20, 21, 22, 23, 24, 24, 25, 25, 24, 23,
    24, 25, 25, 24, 23, 24, 24, 23, 24, 24
  ];

  // Job queue
  final List<_JobData> _jobs = const [
    _JobData(jobId: 'JOB-2026-014', model: 'DERNet v2.1',    dataset: 'BrainMRI-v3',  gpu: 'GPU 0', status: 'Running',   progress: 0.60, eta: '18 min'),
    _JobData(jobId: 'JOB-2026-013', model: 'EfficientNetV2', dataset: 'SpineMRI-v2',  gpu: 'GPU 1', status: 'Running',   progress: 0.40, eta: '34 min'),
    _JobData(jobId: 'JOB-2026-012', model: 'SegResNet',       dataset: 'BrainMRI-v3',  gpu: 'Any',   status: 'Queued',    progress: 0.0,  eta: '--'),
    _JobData(jobId: 'JOB-2026-011', model: 'DenseNet201',     dataset: 'ChestXR-v1',   gpu: 'GPU 0', status: 'Completed', progress: 1.0,  eta: 'Done'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'Running':   return NVColors.researcherColor;
      case 'Queued':    return NVColors.warning;
      case 'Completed': return NVColors.success;
      default:          return NVColors.textMuted;
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return NVScaffold(
      currentRoute: '/dashboard/researcher/gpu',
      role: AppConstants.roleResearcher,
      title: 'GPU Monitor',
      subtitle: 'Real-time GPU utilization, VRAM usage & training job queue',
      userName: user?.name ?? 'Researcher',
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fade,
      body: Column(
        children: [
          NVTopBar(
            title: 'GPU Monitor',
            subtitle: 'Real-time GPU utilization, VRAM usage & training job queue',
            user: user?.name ?? 'Researcher',
            roleColor: NVColors.researcherColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Stats row
                  _buildStats(),
                  const SizedBox(height: 24),

                  // 2) GPU cards
                  LayoutBuilder(builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _gpus.map((g) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: g == _gpus.last ? 0 : 16),
                            child: _buildGpuCard(g),
                          ),
                        )).toList(),
                      );
                    }
                    return Column(
                      children: _gpus.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildGpuCard(g),
                      )).toList(),
                    );
                  }),
                  const SizedBox(height: 24),

                  // 3) VRAM history chart
                  _buildVramChart(),
                  const SizedBox(height: 24),

                  // 4) Job queue
                  _buildJobQueue(),
                  const SizedBox(height: 24),

                  // 5) System metrics
                  _buildSystemMetrics(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1) Stats ──────────────────────────────────────────────────────────────

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
            label: 'GPUs Online',
            value: '2/2',
            icon: Icons.memory_rounded,
            color: NVColors.researcherColor,
            subtitle: 'NVIDIA A100',
          ),
          NVStatCard(
            label: 'Avg Utilization',
            value: '73%',
            icon: Icons.speed_rounded,
            color: NVColors.warning,
            trend: '+5%',
            trendPositive: false,
            subtitle: 'Last 10 min',
          ),
          NVStatCard(
            label: 'VRAM Used',
            value: '52.4 GB',
            icon: Icons.storage_rounded,
            color: NVColors.info,
            subtitle: '80 GB total',
          ),
          NVStatCard(
            label: 'Active Jobs',
            value: '2',
            icon: Icons.play_circle_rounded,
            color: NVColors.success,
            subtitle: '1 queued',
          ),
        ],
      );
    });
  }

  // ── 2) GPU card ───────────────────────────────────────────────────────────

  Widget _buildGpuCard(_GpuData g) {
    final isHot = g.utilization > 0.80;
    final ringColor = isHot ? NVColors.warning : NVColors.researcherColor;
    final pct = (g.utilization * 100).round();

    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.memory_rounded, color: NVColors.researcherColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.id,
                      style: const TextStyle(
                          color: NVColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Text(
                      g.name,
                      style: const TextStyle(
                          color: NVColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: NVColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('Active',
                  style: TextStyle(
                      color: NVColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),

          // Circular utilisation gauge
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: g.utilization,
                    strokeWidth: 10,
                    backgroundColor: NVColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: TextStyle(
                          color: ringColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('util',
                        style: TextStyle(
                            color: NVColors.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Metric 2×2 grid
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final itemWidth = w / 2;
            final ratio = w > 300 ? 2.4 : (itemWidth / 60.0);
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: ratio,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            children: [
              _GpuMetric(
                  icon: Icons.thermostat_rounded,
                  label: 'Temp',
                  value: '${g.tempC}°C',
                  color: g.tempC > 75 ? NVColors.warning : NVColors.textSecondary),
              _GpuMetric(
                  icon: Icons.bolt_rounded,
                  label: 'Power',
                  value: '${g.powerW}W',
                  color: NVColors.info),
              _GpuMetric(
                  icon: Icons.storage_rounded,
                  label: 'VRAM',
                  value: '${g.vramUsed}/${g.vramTotal} GB',
                  color: NVColors.researcherColor),
              _GpuMetric(
                  icon: Icons.flash_on_rounded,
                  label: 'Speed',
                  value: '${g.tflops} TF',
                  color: NVColors.secondary),
            ],
          );
          }),
          const SizedBox(height: 16),

          // VRAM bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('VRAM',
                      style: TextStyle(
                          color: NVColors.textMuted,
                          fontSize: 10)),
                  const Spacer(),
                  Text(
                    '${g.vramUsed} / ${g.vramTotal} GB',
                    style: const TextStyle(
                        color: NVColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: g.vramUsed / g.vramTotal,
                backgroundColor: NVColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(NVColors.researcherColor),
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active job badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: NVColors.researcherColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: NVColors.researcherColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline_rounded,
                    color: NVColors.researcherColor, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.jobId,
                        style: const TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        g.jobModel,
                        style: const TextStyle(
                            color: NVColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: NVColors.researcherColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Running',
                      style: TextStyle(
                          color: NVColors.researcherColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3) VRAM history line chart ─────────────────────────────────────────────

  Widget _buildVramChart() {
    List<FlSpot> toSpots(List<double> vals) =>
        vals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.show_chart_rounded,
                  color: NVColors.researcherColor, size: 18),
              SizedBox(width: 8),
              Text('Memory Usage History',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('GPU VRAM over the last 20 samples',
              style:
                  TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 19,
                minY: 0,
                maxY: 40,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: NVColors.border, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()} GB',
                        style: const TextStyle(
                            color: NVColors.textMuted, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (v, _) {
                        final labels = ['0s', '5s', '10s', '15s', '19s'];
                        final idx = [0, 5, 10, 15, 19].indexOf(v.toInt());
                        if (idx == -1) return const SizedBox.shrink();
                        return Text(labels[idx],
                            style: const TextStyle(
                                color: NVColors.textMuted, fontSize: 9));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // GPU 0 – researcherColor
                  LineChartBarData(
                    spots: toSpots(_gpu0Vram),
                    isCurved: true,
                    color: NVColors.researcherColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          NVColors.researcherColor.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // GPU 1 – doctorColor
                  LineChartBarData(
                    spots: toSpots(_gpu1Vram),
                    isCurved: true,
                    color: NVColors.doctorColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          NVColors.doctorColor.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendItem(color: NVColors.researcherColor, label: 'GPU 0'),
              SizedBox(width: 20),
              _LegendItem(color: NVColors.doctorColor, label: 'GPU 1'),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4) Job Queue ──────────────────────────────────────────────────────────

  Widget _buildJobQueue() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.queue_rounded,
                  color: NVColors.researcherColor, size: 18),
              const SizedBox(width: 8),
              const Text('Job Queue',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showNewJobSnackbar(),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('New Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NVColors.researcherColor,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: NVColors.bgDeep,
                borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Job ID',
                        style: TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Expanded(
                    flex: 3,
                    child: Text('Model',
                        style: TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Expanded(
                    flex: 3,
                    child: Text('Dataset',
                        style: TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Expanded(
                    flex: 2,
                    child: Text('GPU',
                        style: TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Expanded(
                    flex: 2,
                    child: Text('Status',
                        style: TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Expanded(
                    flex: 4,
                    child: Text('Progress',
                        style: TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Expanded(
                    flex: 2,
                    child: Text('ETA',
                        style: TextStyle(
                            color: NVColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 60),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Table rows
          ..._jobs.map((j) => _buildJobRow(j)),
        ],
      ),
    );
  }

  Widget _buildJobRow(_JobData j) {
    final statusColor = _statusColor(j.status);
    final canCancel =
        j.status == 'Running' || j.status == 'Queued';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NVColors.border),
      ),
      child: Row(
        children: [
          // Job ID
          Expanded(
            flex: 3,
            child: Text(j.jobId,
                style: const TextStyle(
                    color: NVColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          // Model
          Expanded(
            flex: 3,
            child: Text(j.model,
                style: const TextStyle(
                    color: NVColors.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
          // Dataset
          Expanded(
            flex: 3,
            child: Text(j.dataset,
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ),
          // GPU
          Expanded(
            flex: 2,
            child: Text(j.gpu,
                style: const TextStyle(
                    color: NVColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
          // Status badge
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(j.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ),
          ),
          // Progress
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: j.progress,
                    backgroundColor: NVColors.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(j.progress * 100).round()}%',
                  style: const TextStyle(
                      color: NVColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          // ETA
          Expanded(
            flex: 2,
            child: Text(j.eta,
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 11)),
          ),
          // Cancel button
          SizedBox(
            width: 60,
            child: canCancel
                ? TextButton(
                    onPressed: () => _cancelJob(j.jobId),
                    style: TextButton.styleFrom(
                      foregroundColor: NVColors.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 10)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── 5) System metrics ─────────────────────────────────────────────────────

  Widget _buildSystemMetrics() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SystemMetricCard(
              icon: Icons.developer_board_rounded,
              label: 'CPU Usage',
              value: '42%',
              subtitle: '32 cores active',
              progress: 0.42,
              progressColor: NVColors.researcherColor,
            )),
            const SizedBox(width: 16),
            Expanded(child: _SystemMetricCard(
              icon: Icons.memory_rounded,
              label: 'System RAM',
              value: '128 / 512 GB',
              subtitle: '25% used',
              progress: 0.25,
              progressColor: NVColors.info,
            )),
            const SizedBox(width: 16),
            Expanded(child: _SystemMetricCard(
              icon: Icons.storage_rounded,
              label: 'Storage',
              value: '4.2 / 20 TB',
              subtitle: '21% used',
              progress: 0.21,
              progressColor: NVColors.success,
            )),
          ],
        );
      }
      return Column(
        children: [
          _SystemMetricCard(
            icon: Icons.developer_board_rounded,
            label: 'CPU Usage',
            value: '42%',
            subtitle: '32 cores active',
            progress: 0.42,
            progressColor: NVColors.researcherColor,
          ),
          const SizedBox(height: 16),
          _SystemMetricCard(
            icon: Icons.memory_rounded,
            label: 'System RAM',
            value: '128 / 512 GB',
            subtitle: '25% used',
            progress: 0.25,
            progressColor: NVColors.info,
          ),
          const SizedBox(height: 16),
          _SystemMetricCard(
            icon: Icons.storage_rounded,
            label: 'Storage',
            value: '4.2 / 20 TB',
            subtitle: '21% used',
            progress: 0.21,
            progressColor: NVColors.success,
          ),
        ],
      );
    });
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _cancelJob(String jobId) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Job $jobId cancelled'),
      backgroundColor: NVColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showNewJobSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('New job submission form coming soon'),
      backgroundColor: NVColors.researcherColor,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ---------------------------------------------------------------------------
// Reusable sub-widgets
// ---------------------------------------------------------------------------

class _GpuMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GpuMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: NVColors.bgDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NVColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: NVColors.textMuted, fontSize: 9)),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
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
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: NVColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _SystemMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final double progress;
  final Color progressColor;

  const _SystemMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: progressColor, size: 16),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  color: progressColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: NVColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                  color: progressColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
