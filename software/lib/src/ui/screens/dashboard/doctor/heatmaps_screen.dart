// lib/src/ui/screens/dashboard/doctor/heatmaps_screen.dart
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
// Data model
// ---------------------------------------------------------------------------
class _HeatmapCase {
  final String caseId;
  final String modality;
  final String prediction;
  final double confidence;
  final Color severityColor;

  const _HeatmapCase(
    this.caseId,
    this.modality,
    this.prediction,
    this.confidence,
    this.severityColor,
  );
}

// ---------------------------------------------------------------------------
// Mock dataset
// ---------------------------------------------------------------------------
const List<_HeatmapCase> _mockCases = [
  _HeatmapCase('CASE-2026-047', 'Brain MRI', 'Glioblastoma', 94.2, NVColors.error),
  _HeatmapCase('CASE-2026-046', 'Spine MRI', 'Herniated Disc', 88.7, NVColors.warning),
  _HeatmapCase('CASE-2026-045', 'Brain MRI', 'Meningioma', 96.1, NVColors.error),
  _HeatmapCase('CASE-2026-044', 'CT Scan', 'Hemorrhage', 91.3, NVColors.warning),
  _HeatmapCase('CASE-2026-043', 'Chest X-Ray', 'Normal', 87.5, NVColors.success),
];

const List<String> _layers = ['Conv1', 'Conv3', 'Conv5', 'FC'];

const List<String> _regionLabels = [
  'Frontal', 'Parietal', 'Temporal', 'Occipital', 'Cerebellar', 'Brain Stem'
];
const List<double> _regionValues = [82, 95, 71, 45, 38, 22];

// 5×5 mock attention matrix (0.0–1.0)
const List<List<double>> _attentionMatrix = [
  [0.1, 0.2, 0.5, 0.3, 0.1],
  [0.2, 0.7, 0.9, 0.6, 0.2],
  [0.4, 0.8, 1.0, 0.8, 0.4],
  [0.2, 0.6, 0.8, 0.5, 0.2],
  [0.1, 0.2, 0.4, 0.2, 0.1],
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class HeatmapsScreen extends StatefulWidget {
  const HeatmapsScreen({super.key});

  @override
  State<HeatmapsScreen> createState() => _HeatmapsScreenState();
}

class _HeatmapsScreenState extends State<HeatmapsScreen>
    with SingleTickerProviderStateMixin {
  // ── animation ────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  // ── state ─────────────────────────────────────────────────────────────────
  int _selectedCaseIndex = 0;
  String _selectedLayer = 'Conv5';
  bool _showHeatmap = true;
  bool _showContours = true;

  _HeatmapCase get _activeCase => _mockCases[_selectedCaseIndex];

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

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;

    return NVScaffold(
      currentRoute: '/dashboard/doctor/heatmaps',
      role: AppConstants.roleDoctor,
      title: 'Grad-CAM Heatmaps',
      subtitle: 'Explainable AI activation maps & lesion attention visualization',
      userName: user?.name ?? 'Doctor',
      roleColor: NVColors.doctorColor,
      fadeAnimation: _fade,
      body: Column(
        children: [
          NVTopBar(
            title: 'Grad-CAM Heatmaps',
            subtitle: 'Explainable AI activation maps & lesion attention visualization',
            user: user?.name ?? 'Doctor',
            roleColor: NVColors.doctorColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildMainLayout(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── stats row ─────────────────────────────────────────────────────────────
  Widget _buildStats() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final count = w > 800 ? 4 : w > 400 ? 2 : 1;
      final itemWidth = w / count;
      final ratio = w > 400 ? 1.65 : (itemWidth / 160.0);
      return GridView.count(
        crossAxisCount: count, crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: ratio, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: const [
            NVStatCard(
              label: 'Cases Heatmapped',
              value: '184',
              icon: Icons.thermostat_rounded,
              color: NVColors.doctorColor,
              trend: '+12%',
              trendPositive: true,
            ),
            NVStatCard(
              label: 'Avg Activation Score',
              value: '0.847',
              icon: Icons.speed_rounded,
              color: NVColors.warning,
            ),
            NVStatCard(
              label: 'High-Risk Regions',
              value: '23',
              icon: Icons.warning_amber_rounded,
              color: NVColors.error,
              subtitle: 'This week',
            ),
            NVStatCard(
              label: 'Pending Review',
              value: '7',
              icon: Icons.pending_rounded,
              color: NVColors.info,
            ),
          ],
        );
      },
    );
  }

  // ── three-column layout ───────────────────────────────────────────────────
  Widget _buildMainLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      final isMedium = constraints.maxWidth > 560;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 260, child: _buildCasesQueue()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildGradCamViewer(),
                  const SizedBox(height: 16),
                  _buildActivationChart(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 240,
              child: Column(
                children: [
                  _buildActivationDetails(),
                  const SizedBox(height: 16),
                  _buildAttentionMap(),
                ],
              ),
            ),
          ],
        );
      }
      if (isMedium) {
        return Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _buildGradCamViewer()),
            const SizedBox(width: 16),
            SizedBox(width: 220, child: _buildActivationDetails()),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _buildCasesQueue()),
            const SizedBox(width: 16),
            Expanded(child: _buildActivationChart()),
          ]),
          const SizedBox(height: 16),
          _buildAttentionMap(),
        ]);
      }
      return Column(children: [
        _buildGradCamViewer(),
        const SizedBox(height: 16),
        _buildActivationDetails(),
        const SizedBox(height: 16),
        _buildActivationChart(),
        const SizedBox(height: 16),
        _buildCasesQueue(),
        const SizedBox(height: 16),
        _buildAttentionMap(),
      ]);
    });
  }

  // ── left: cases queue ─────────────────────────────────────────────────────
  Widget _buildCasesQueue() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.queue_rounded,
                  color: NVColors.doctorColor, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Cases Queue',
                style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: NVColors.doctorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_mockCases.length}',
                  style: const TextStyle(
                    color: NVColors.doctorColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_mockCases.length, (i) => _buildCaseItem(i)),
        ],
      ),
    );
  }

  Widget _buildCaseItem(int index) {
    final c = _mockCases[index];
    final isSelected = _selectedCaseIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedCaseIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? NVColors.doctorColor.withValues(alpha: 0.08)
              : NVColors.bgDeep.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? NVColors.doctorColor : NVColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Severity dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: c.severityColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.severityColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.caseId,
                    style: TextStyle(
                      color: isSelected
                          ? NVColors.doctorColor
                          : NVColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.modality,
                    style: const TextStyle(
                      color: NVColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Confidence badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: c.severityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${c.confidence.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: c.severityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── center: grad-cam viewer ───────────────────────────────────────────────
  Widget _buildGradCamViewer() {
    final c = _activeCase;
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: NVColors.doctorColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Grad-CAM Visualization',
                style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // Layer selector chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // Right-align chips
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _layers.map((layer) {
                  final active = _selectedLayer == layer;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLayer = layer),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? NVColors.doctorColor.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: active
                              ? NVColors.doctorColor
                              : NVColors.border,
                        ),
                      ),
                      child: Text(
                        layer,
                        style: TextStyle(
                          color: active
                              ? NVColors.doctorColor
                              : NVColors.textMuted,
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image viewer
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NVColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background radial gradient (dark blue brain scan sim)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.1),
                        radius: 0.9,
                        colors: [Color(0xFF0D1B3E), Color(0xFF020510)],
                      ),
                    ),
                  ),

                  // Brain outline via CustomPainter
                  CustomPaint(
                    painter: _BrainOutlinePainter(),
                    size: Size.infinite,
                  ),

                  // Heatmap overlay
                  if (_showHeatmap)
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.2, -0.1),
                          radius: 0.4,
                          colors: [
                            NVColors.error.withValues(alpha: 0.70),
                            NVColors.warning.withValues(alpha: 0.40),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),

                  // Contour overlay
                  if (_showContours)
                    CustomPaint(
                      painter: _HeatmapContourPainter(),
                      size: Size.infinite,
                    ),

                  // Modality badge (top-left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _ScanBadge(text: c.modality),
                  ),

                  // Grad-CAM layer badge (top-right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _ScanBadge(
                      text: 'Grad-CAM · $_selectedLayer',
                      color: NVColors.doctorColor.withValues(alpha: 0.85),
                    ),
                  ),

                  // AI prediction badge (bottom-left)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: _ScanBadge(
                      text:
                          'AI: ${c.prediction} · ${c.confidence.toStringAsFixed(1)}%',
                      color: c.severityColor.withValues(alpha: 0.85),
                    ),
                  ),

                  // Control buttons (bottom-right)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      children: [
                        _ViewerIconBtn(icon: Icons.zoom_in_rounded),
                        const SizedBox(width: 4),
                        _ViewerIconBtn(icon: Icons.brightness_6_rounded),
                        const SizedBox(width: 4),
                        _ViewerIconBtn(icon: Icons.fullscreen_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Color legend
          _buildColorLegend(),
        ],
      ),
    );
  }

  Widget _buildColorLegend() {
    const stops = [
      ('Low', Color(0xFF3B82F6)),
      ('', Color(0xFF06B6D4)),
      ('', Color(0xFF22C55E)),
      ('', Color(0xFFF59E0B)),
      ('High', Color(0xFFEF4444)),
    ];

    return Row(
      children: [
        const Text('Activation:',
            style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF06B6D4),
                  Color(0xFF22C55E),
                  Color(0xFFF59E0B),
                  Color(0xFFEF4444),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: stops.map((s) {
            if (s.$1.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: s.$2, shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Text(s.$1,
                      style: const TextStyle(
                          color: NVColors.textMuted, fontSize: 10)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── center: regional activation bar chart ─────────────────────────────────
  Widget _buildActivationChart() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: NVColors.doctorColor, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Regional Activation Analysis',
                style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
                maxY: 110,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        NVColors.bgCard.withValues(alpha: 0.95),
                    tooltipBorder:
                        const BorderSide(color: NVColors.border),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${_regionLabels[groupIndex]}\n${rod.toY.toInt()}%',
                      const TextStyle(
                          color: NVColors.textPrimary, fontSize: 11),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < 0 || i >= _regionLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _regionLabels[i],
                            style: const TextStyle(
                                color: NVColors.textMuted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 25,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                            color: NVColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: NVColors.border,
                    strokeWidth: 0.5,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_regionValues.length, (i) {
                  final val = _regionValues[i];
                  final barColor = val > 80
                      ? NVColors.error
                      : val > 60
                          ? NVColors.warning
                          : NVColors.success;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: barColor,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 110,
                          color: barColor.withValues(alpha: 0.07),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── right: activation details ──────────────────────────────────────────────
  Widget _buildActivationDetails() {
    final c = _activeCase;
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: NVColors.doctorColor, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Activation Details',
                style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info blocks
          _InfoBlock(label: 'Prediction', value: c.prediction,
              valueColor: c.severityColor),
          _InfoBlock(
              label: 'Confidence',
              value: '${c.confidence.toStringAsFixed(1)}%',
              valueColor: c.severityColor),
          _InfoBlock(label: 'Model', value: 'DERNet v2.1'),
          _InfoBlock(label: 'Layer', value: _selectedLayer,
              valueColor: NVColors.doctorColor),

          const SizedBox(height: 14),

          // Confidence progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confidence',
                  style:
                      TextStyle(color: NVColors.textMuted, fontSize: 11)),
              Text(
                '${c.confidence.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: c.severityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: c.confidence / 100.0,
            backgroundColor: NVColors.border,
            valueColor:
                AlwaysStoppedAnimation<Color>(c.severityColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),

          const SizedBox(height: 18),
          const Divider(color: NVColors.border, height: 1),
          const SizedBox(height: 14),

          // Overlay toggles
          const Text(
            'Overlay Controls',
            style: TextStyle(
              color: NVColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ToggleChip(
                label: 'Heatmap',
                active: _showHeatmap,
                color: NVColors.error,
                onTap: () =>
                    setState(() => _showHeatmap = !_showHeatmap),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Contours',
                active: _showContours,
                color: NVColors.warning,
                onTap: () =>
                    setState(() => _showContours = !_showContours),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── right: attention map ──────────────────────────────────────────────────
  Widget _buildAttentionMap() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded,
                  color: NVColors.doctorColor, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Attention Map',
                style: TextStyle(
                  color: NVColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                final row = index ~/ 5;
                final col = index % 5;
                final val = _attentionMatrix[row][col];
                return Container(
                  decoration: BoxDecoration(
                    color: _attentionColor(val),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      val.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white.withValues(
                            alpha: val > 0.4 ? 0.9 : 0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Mini legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _attentionLegendDot(
                  'Low', _attentionColor(0.1)),
              _attentionLegendDot(
                  'Mid', _attentionColor(0.5)),
              _attentionLegendDot(
                  'High', _attentionColor(1.0)),
            ],
          ),
        ],
      ),
    );
  }

  Color _attentionColor(double val) {
    if (val >= 0.8) return NVColors.error.withValues(alpha: 0.7 + val * 0.3);
    if (val >= 0.5) {
      return Color.lerp(
        NVColors.warning.withValues(alpha: 0.6),
        NVColors.error.withValues(alpha: 0.75),
        (val - 0.5) / 0.3,
      )!;
    }
    if (val >= 0.2) {
      return Color.lerp(
        NVColors.success.withValues(alpha: 0.25),
        NVColors.warning.withValues(alpha: 0.55),
        (val - 0.2) / 0.3,
      )!;
    }
    return NVColors.info.withValues(alpha: 0.18);
  }

  Widget _attentionLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: NVColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainters
// ---------------------------------------------------------------------------

class _BrainOutlinePainter extends CustomPainter {
  const _BrainOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer brain oval
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 10),
        width: size.width * 0.62,
        height: size.height * 0.78,
      ),
      outlinePaint,
    );

    // Midline (interhemispheric fissure)
    final midlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.37),
      Offset(cx, cy + size.height * 0.29),
      midlinePaint,
    );

    // Gyri / sulci simulation (concentric inner ovals)
    for (int i = 1; i <= 5; i++) {
      final gyriPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.025 + i * 0.008)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + (i % 2 == 0 ? -8.0 : 8.0), cy - 10),
          width: size.width * (0.12 + i * 0.08),
          height: size.height * (0.12 + i * 0.09),
        ),
        gyriPaint,
      );
    }

    // Inner highlight ring
    final highlightPaint = Paint()
      ..color = NVColors.doctorColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 10),
        width: size.width * 0.5,
        height: size.height * 0.64,
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BrainOutlinePainter oldDelegate) => false;
}

class _HeatmapContourPainter extends CustomPainter {
  const _HeatmapContourPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Contour 1 – tight hot zone
    final contour1 = Paint()
      ..color = NVColors.error.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.10, cy - size.height * 0.08),
        width: size.width * 0.22,
        height: size.height * 0.20,
      ),
      contour1,
    );

    // Contour 2 – medium activation zone
    final contour2 = Paint()
      ..color = NVColors.warning.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.10, cy - size.height * 0.08),
        width: size.width * 0.36,
        height: size.height * 0.34,
      ),
      contour2,
    );
  }

  @override
  bool shouldRepaint(covariant _HeatmapContourPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Small reusable sub-widgets
// ---------------------------------------------------------------------------

class _ScanBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const _ScanBadge({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ViewerIconBtn extends StatelessWidget {
  final IconData icon;

  const _ViewerIconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, color: Colors.white70, size: 15),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoBlock({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: NVColors.textMuted, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? NVColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active ? color : NVColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: active ? color : NVColors.textMuted,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? color : NVColors.textMuted,
                fontSize: 11,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
