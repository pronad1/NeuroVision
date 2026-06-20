// lib/src/ui/screens/dashboard/radiologist/uncertainty_screen.dart
//
// Feature: Uncertainty Quantification & AI Doubt Maps
// Academic concept: Bayesian Deep Learning — Monte Carlo Dropout runs N stochastic
// forward passes; variance across passes = model uncertainty. Critical for safety.
//
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_stat_card.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class UncertaintyScreen extends StatefulWidget {
  const UncertaintyScreen({super.key});

  @override
  State<UncertaintyScreen> createState() => _UncertaintyScreenState();
}

class _UncertaintyScreenState extends State<UncertaintyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int _mcPasses = 20;
  bool _isComputing = false;
  bool _resultsReady = true;

  // Derived metrics based on MC passes
  double get _epistemicUncertainty => 0.042 - (_mcPasses - 10) * 0.0006;
  double get _aleatoricUncertainty => 0.031;
  double get _stabilityScore => 87.4 + (_mcPasses - 10) * 0.22;

  // Uncertainty distribution histogram data
  List<BarChartGroupData> get _histogramData {
    // Simulated uncertainty distribution across image regions
    final vals = [4.0, 12.0, 28.0, 45.0, 38.0, 22.0, 14.0, 8.0, 5.0, 3.0];
    return vals.asMap().entries.map((e) => BarChartGroupData(
      x: e.key,
      barRods: [BarChartRodData(
        toY: e.value,
        color: _uncertaintyBarColor(e.key / (vals.length - 1)),
        width: 14,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )],
    )).toList();
  }

  Color _uncertaintyBarColor(double t) {
    if (t < 0.33) return NVColors.success;
    if (t < 0.66) return NVColors.warning;
    return NVColors.error;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _recompute() async {
    setState(() { _isComputing = true; _resultsReady = false; });
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() { _isComputing = false; _resultsReady = true; });
  }

  @override
  Widget build(BuildContext context) {
    return NVScaffold(
      currentRoute: '/dashboard/radiologist/uncertainty',
      role: AppConstants.roleRadiologist,
      title: 'Uncertainty Maps',
      subtitle: 'Bayesian Deep Learning — MC Dropout Analysis',
      userName: 'Radiologist',
      roleColor: NVColors.radiologistColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'AI Uncertainty Quantification',
            subtitle: 'Monte Carlo Dropout — Epistemic & Aleatoric Uncertainty Analysis',
            user: 'Radiologist',
            roleColor: NVColors.radiologistColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConceptBanner(),
                  const SizedBox(height: 20),
                  _buildControlPanel(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildMainContent(),
                  const SizedBox(height: 20),
                  _buildClinicalGuidance(),
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
          NVColors.radiologistColor.withValues(alpha: 0.10),
          NVColors.error.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NVColors.radiologistColor.withValues(alpha: 0.25)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [NVColors.radiologistColor, Color(0xFF4F1D96)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.blur_on_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const SizedBox(
              width: 300, // Fixed width for text area to allow horizontal scroll
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Uncertainty Quantification — Bayesian Deep Learning',
                      style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 3),
                  Text(
                    'The AI model runs N stochastic forward passes (MC Dropout). Pixel-wise variance across '
                    'passes creates an "uncertainty map" — red = AI is unsure. Critical for patient safety.',
                    style: TextStyle(color: NVColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: NVColors.radiologistColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NVColors.radiologistColor.withValues(alpha: 0.3)),
              ),
              child: const Text('BAYESIAN AI',
                  style: TextStyle(color: NVColors.radiologistColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          // Stack vertically on mobile to avoid overflow
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: NVColors.radiologistColor, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Monte Carlo Dropout Passes:',
                        style: TextStyle(color: NVColors.textSecondary, fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: NVColors.radiologistColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NVColors.radiologistColor.withValues(alpha: 0.3)),
                    ),
                    child: Text('$_mcPasses',
                        style: const TextStyle(color: NVColors.radiologistColor, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: NVColors.radiologistColor,
                  thumbColor: NVColors.radiologistColor,
                  inactiveTrackColor: NVColors.border,
                  overlayColor: NVColors.radiologistColor.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _mcPasses.toDouble(),
                  min: 10, max: 50, divisions: 8,
                  onChanged: (v) => setState(() => _mcPasses = v.toInt()),
                  onChangeEnd: (_) => _recompute(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isComputing ? null : _recompute,
                  icon: _isComputing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_isComputing ? 'Computing...' : 'Recompute'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.radiologistColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: const Size(0, 0),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          );
        }
        // Wide layout: single row
        return Row(
          children: [
            const Icon(Icons.tune_rounded, color: NVColors.radiologistColor, size: 16),
            const SizedBox(width: 8),
            const Text('Monte Carlo Dropout Passes:', style: TextStyle(color: NVColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 16),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: NVColors.radiologistColor,
                  thumbColor: NVColors.radiologistColor,
                  inactiveTrackColor: NVColors.border,
                  overlayColor: NVColors.radiologistColor.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _mcPasses.toDouble(),
                  min: 10, max: 50, divisions: 8,
                  onChanged: (v) => setState(() => _mcPasses = v.toInt()),
                  onChangeEnd: (_) => _recompute(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: NVColors.radiologistColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NVColors.radiologistColor.withValues(alpha: 0.3)),
              ),
              child: Text('$_mcPasses passes',
                  style: const TextStyle(color: NVColors.radiologistColor, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isComputing ? null : _recompute,
              icon: _isComputing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(_isComputing ? 'Computing...' : 'Recompute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NVColors.radiologistColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 0),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final count = w > 800 ? 4 : 2;
      final itemWidth = w / count;
      final ratio = w > 800 ? 1.8 : w > 380 ? 1.5 : (itemWidth / 180.0);
      return GridView.count(
        crossAxisCount: count,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          NVStatCard(
            label: 'Epistemic Uncertainty',
            value: _epistemicUncertainty.toStringAsFixed(4),
            icon: Icons.psychology_rounded,
            color: NVColors.radiologistColor,
            subtitle: 'Model knowledge uncertainty',
          ),
          NVStatCard(
            label: 'Aleatoric Uncertainty',
            value: _aleatoricUncertainty.toStringAsFixed(4),
            icon: Icons.blur_on_rounded,
            color: NVColors.warning,
            subtitle: 'Data inherent noise',
          ),
          NVStatCard(
            label: 'Prediction Stability',
            value: '${_stabilityScore.toStringAsFixed(1)}%',
            icon: Icons.verified_rounded,
            color: NVColors.success,
            subtitle: 'Across MC passes',
          ),
          NVStatCard(
            label: 'High-Risk Regions',
            value: '3',
            icon: Icons.warning_amber_rounded,
            color: NVColors.error,
            subtitle: 'Require manual review',
          ),
        ],
      );
    });
  }

  Widget _buildMainContent() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 750;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildUncertaintyMaps()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildHistogram()),
          ],
        );
      }
      return Column(children: [_buildUncertaintyMaps(), const SizedBox(height: 16), _buildHistogram()]);
    });
  }

  Widget _buildUncertaintyMaps() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.compare_rounded, color: NVColors.radiologistColor, size: 16),
            SizedBox(width: 8),
            Text('Uncertainty Visualization', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          Text('Case CASE-2026-045 · Brain MRI · DERNet Ensemble · $_mcPasses MC passes',
              style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            final items = [
              _ScanPanel('Original Scan', _buildOriginalScan(), NVColors.textMuted),
              _ScanPanel('Grad-CAM', _buildGradCAM(), NVColors.doctorColor),
              _ScanPanel('Uncertainty Map', _buildUncertaintyMap(), NVColors.radiologistColor),
            ];
            if (isWide) {
              return Row(
                children: items.map((p) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildScanCard(p),
                ))).toList(),
              );
            }
            return Column(children: items.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildScanCard(p),
            )).toList());
          }),
          const SizedBox(height: 14),
          // Color legend for uncertainty map
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Low uncertainty', style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
                const SizedBox(width: 8),
                Container(
                  width: 120, height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NVColors.success, NVColors.warning, NVColors.error],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('High uncertainty', style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard(_ScanPanel panel) {
    return Column(
      children: [
        Text(panel.title, style: TextStyle(color: panel.labelColor, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 140,
            child: AnimatedOpacity(
              opacity: _resultsReady ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 400),
              child: panel.widget,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalScan() {
    return CustomPaint(painter: _ScanPainter(type: 'original'), child: const SizedBox.expand());
  }

  Widget _buildGradCAM() {
    return CustomPaint(painter: _ScanPainter(type: 'gradcam'), child: const SizedBox.expand());
  }

  Widget _buildUncertaintyMap() {
    return CustomPaint(painter: _ScanPainter(type: 'uncertainty'), child: const SizedBox.expand());
  }

  Widget _buildHistogram() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bar_chart_rounded, color: NVColors.radiologistColor, size: 16),
            SizedBox(width: 8),
            Text('Uncertainty Distribution', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          const Text('Pixel-wise uncertainty values across scan',
              style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: AnimatedOpacity(
              opacity: _resultsReady ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 400),
              child: BarChart(BarChartData(
                barGroups: _histogramData,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: NVColors.border, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                        style: const TextStyle(color: NVColors.textMuted, fontSize: 9)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final labels = ['0.0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9'];
                      final i = v.toInt();
                      return Text(i < labels.length ? labels[i] : '',
                          style: const TextStyle(color: NVColors.textMuted, fontSize: 8));
                    },
                  )),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              )),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _UncertLegend(color: NVColors.success, label: 'Confident'),
              const SizedBox(width: 14),
              _UncertLegend(color: NVColors.warning, label: 'Moderate'),
              const SizedBox(width: 14),
              _UncertLegend(color: NVColors.error, label: 'Uncertain'),
            ]),
          ),
          const SizedBox(height: 16),
          // MC passes info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NVColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NVColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MC Dropout Method', style: TextStyle(color: NVColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('$_mcPasses stochastic forward passes', style: const TextStyle(color: NVColors.textPrimary, fontSize: 12)),
                const Text('Dropout rate: 0.3 (all layers active at inference)', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
                const Text('Aggregation: pixel-wise mean + variance', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalGuidance() {
    final regions = [
      ('Left Frontal Lobe — Superior', 'HIGH', NVColors.error, 'Urgent manual review required. AI confidence drops below 70% in this region.'),
      ('Perilesional Zone — Boundary', 'MEDIUM', NVColors.warning, 'Lesion boundary uncertain. Consider follow-up imaging for precise delineation.'),
      ('Contralateral Hemisphere', 'LOW', NVColors.success, 'High model confidence. AI prediction reliable in this region.'),
    ];

    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.medical_information_rounded, color: NVColors.radiologistColor, size: 16),
            SizedBox(width: 8),
            Text('Clinical Guidance — Uncertain Regions', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          ...regions.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: r.$3.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: r.$3.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: r.$3.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(r.$2, style: TextStyle(color: r.$3, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(r.$4, style: const TextStyle(color: NVColors.textMuted, fontSize: 11, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Helper classes ───────────────────────────────────────────────────────────

class _ScanPanel {
  final String title;
  final Widget widget;
  final Color labelColor;
  _ScanPanel(this.title, this.widget, this.labelColor);
}

class _UncertLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _UncertLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
    ]);
  }
}

// ─── Custom painters for scan/map visualization ───────────────────────────────

class _ScanPainter extends CustomPainter {
  final String type;
  _ScanPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0A0E1A);
    canvas.drawRect(Offset.zero & size, bg);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.height * 0.42;

    if (type == 'original') {
      // Brain outline in grey
      final brainPaint = Paint()..color = const Color(0xFF374151)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.9, height: r * 2.1), brainPaint);
      final innerPaint = Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.5, height: r * 1.7), innerPaint);
      // Lesion spot
      final lesionPaint = Paint()..color = const Color(0xFF4B5563)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.2, cy - r * 0.3), width: r * 0.5, height: r * 0.4), lesionPaint);
    } else if (type == 'gradcam') {
      // Brain outline
      final brainPaint = Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.9, height: r * 2.1), brainPaint);
      // Heatmap gradient
      final shader = RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 0.55,
        colors: [NVColors.error.withValues(alpha: 0.85), NVColors.warning.withValues(alpha: 0.5), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 1.9, height: r * 2.1),
        Paint()..shader = shader,
      );
    } else {
      // Uncertainty map: brain background
      final brainPaint = Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.9, height: r * 2.1), brainPaint);
      // Low uncertainty (blue/green) over most of brain
      final lowShader = RadialGradient(
        center: Alignment.center,
        radius: 0.6,
        colors: [NVColors.success.withValues(alpha: 0.3), NVColors.info.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 1.9, height: r * 2.1),
        Paint()..shader = lowShader,
      );
      // Medium uncertainty (yellow) in mid zone
      final medPaint = Paint()..color = NVColors.warning.withValues(alpha: 0.4);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.15, cy - r * 0.2), width: r * 0.7, height: r * 0.6), medPaint);
      // High uncertainty (red) in uncertain region
      final highPaint = Paint()..color = NVColors.error.withValues(alpha: 0.7);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.2, cy - r * 0.3), width: r * 0.38, height: r * 0.32), highPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => old.type != type;
}
