// lib/src/ui/screens/dashboard/doctor/segmentation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_stat_card.dart';
import '../../../../utils/download_helper.dart';

class SegmentationScreen extends StatefulWidget {
  const SegmentationScreen({super.key});
  @override
  State<SegmentationScreen> createState() => _SegmentationScreenState();
}

class _SegmentationScreenState extends State<SegmentationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  double _opacity = 0.7;
  bool _showOriginal = true;
  bool _showMask = true;
  bool _showContour = true;
  String _selectedRegion = 'All Regions';

  final _regions = ['All Regions', 'Left Hemisphere', 'Right Hemisphere', 'Brainstem', 'Cerebellum'];
  final _segData = [
    _SegRegion('Lesion Region A', '24.3 cc', '8.2%', NVColors.error, 0.82),
    _SegRegion('Perilesional Edema', '58.7 cc', '19.8%', NVColors.warning, 0.68),
    _SegRegion('Normal Tissue', '211.4 cc', '71.5%', NVColors.success, 0.95),
    _SegRegion('Uncertainty Zone', '2.1 cc', '0.7%', NVColors.info, 0.43),
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
      currentRoute: '/dashboard/doctor/segmentation',
      role: AppConstants.roleDoctor,
      title: 'Segmentation Analysis',
      subtitle: 'AI-powered lesion segmentation and volume measurement',
      userName: user?.name ?? 'Doctor',
      roleColor: NVColors.doctorColor,
      fadeAnimation: _fade,
      body: Column(children: [
        NVTopBar(title: 'Segmentation Analysis', subtitle: 'AI-powered lesion segmentation and volume measurement', user: user?.name ?? 'Doctor', roleColor: NVColors.doctorColor),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildStats(),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _buildViewer()),
                  const SizedBox(width: 16),
                  SizedBox(width: 280, child: _buildControls()),
                ]);
              }
              return Column(children: [
                _buildViewer(),
                const SizedBox(height: 16),
                _buildControls(),
              ]);
            }),
            const SizedBox(height: 16),
            _buildRegionTable(),
          ]),
        )),
      ]),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final count = w > 900 ? 4 : w > 400 ? 2 : 1;
      final itemWidth = w / count;
      final ratio = w > 400 ? 1.6 : (itemWidth / 160.0);
      return GridView.count(
        crossAxisCount: count, crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: ratio, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: const [
          NVStatCard(label: 'Lesion Volume', value: '24.3 cc', icon: Icons.bubble_chart_rounded, color: NVColors.error, subtitle: 'Active lesion region'),
          NVStatCard(label: 'Total Edema', value: '58.7 cc', icon: Icons.water_drop_rounded, color: NVColors.warning, subtitle: 'Perilesional zone'),
          NVStatCard(label: 'Dice Score', value: '0.892', icon: Icons.analytics_rounded, color: NVColors.success, trend: '+0.04', trendPositive: true, subtitle: 'Segmentation accuracy'),
          NVStatCard(label: 'IoU Score', value: '0.847', icon: Icons.layers_rounded, color: NVColors.secondary, subtitle: 'Intersection over union'),
        ],
      );
    });
  }

  Widget _buildViewer() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.layers_rounded, color: NVColors.doctorColor, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('Segmentation Viewer', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
          // Region filter
          DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _selectedRegion,
            dropdownColor: NVColors.bgCard,
            style: const TextStyle(color: NVColors.textSecondary, fontSize: 12),
            items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedRegion = v); },
          )),
        ]),
        const SizedBox(height: 16),
        // Layer toggles
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
          _LayerToggle(label: 'Original', active: _showOriginal, color: NVColors.textSecondary, onTap: () => setState(() => _showOriginal = !_showOriginal)),
          _LayerToggle(label: 'Mask', active: _showMask, color: NVColors.error, onTap: () => setState(() => _showMask = !_showMask)),
          _LayerToggle(label: 'Contour', active: _showContour, color: NVColors.secondary, onTap: () => setState(() => _showContour = !_showContour)),
          Text('Opacity: ${(_opacity * 100).toInt()}%', style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        // Opacity slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: NVColors.doctorColor,
            inactiveTrackColor: NVColors.border,
            thumbColor: NVColors.doctorColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 3,
          ),
          child: Slider(value: _opacity, onChanged: (v) => setState(() => _opacity = v)),
        ),
        const SizedBox(height: 12),
        // Scan viewer
        Container(
          height: 320,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: NVColors.border)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              // Base scan
              Container(decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0, -0.1), radius: 0.8, colors: [const Color(0xFF1a1a2e).withValues(alpha: 0.95), Colors.black]),
              )),
              CustomPaint(painter: _BrainScanPainter(showMask: _showMask, showContour: _showContour, opacity: _opacity), size: Size.infinite),
              // Info overlays
              Positioned(top: 10, left: 10, child: _ScanLabel(text: 'CASE-2026-047')),
              Positioned(top: 10, right: 10, child: _ScanLabel(text: 'SegResNet · Dice 0.892')),
              Positioned(bottom: 10, left: 10, child: _ScanLabel(text: 'Slice 42/86')),
              Positioned(bottom: 10, right: 10, child: Row(children: [
                _MiniBtn(icon: Icons.chevron_left_rounded),
                const SizedBox(width: 4),
                _MiniBtn(icon: Icons.chevron_right_rounded),
                const SizedBox(width: 8),
                _MiniBtn(icon: Icons.fullscreen_rounded),
              ])),
              // Legend overlay
              Positioned(left: 10, top: 40, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_showMask) _LegendDot(color: NVColors.error, label: 'Lesion'),
                const SizedBox(height: 4),
                _LegendDot(color: NVColors.warning.withValues(alpha: 0.7), label: 'Edema'),
              ])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildControls() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Measurement Tools', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 12),
        _MeasureTile(icon: Icons.straighten_rounded, label: 'Max Diameter', value: '4.8 cm', color: NVColors.doctorColor),
        _MeasureTile(icon: Icons.bubble_chart_rounded, label: 'Lesion Volume', value: '24.3 cc', color: NVColors.error),
        _MeasureTile(icon: Icons.water_drop_rounded, label: 'Edema Zone', value: '58.7 cc', color: NVColors.warning),
        _MeasureTile(icon: Icons.location_on_rounded, label: 'Location', value: 'Left MCA', color: NVColors.secondary),
        const SizedBox(height: 16),
        const Divider(color: NVColors.border),
        const SizedBox(height: 12),
        const Text('Model Info', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        _ModelInfo(label: 'Architecture', value: 'SegResNet'),
        _ModelInfo(label: 'Trained On', value: 'BraTS 2023'),
        _ModelInfo(label: 'Dice Score', value: '0.892'),
        _ModelInfo(label: 'HD95', value: '4.12 mm'),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () {
            downloadFile('Lesion_Mask_Export.nii.gz', 'Dummy NIfTI Mask Content');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Mask exported successfully as NIfTI file.'),
              backgroundColor: NVColors.success,
            ));
          },
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Export Mask'),
          style: ElevatedButton.styleFrom(
            backgroundColor: NVColors.doctorColor, foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () {
            downloadFile('Segmentation_Report.pdf', 'Dummy Segmentation Report PDF Content');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Segmentation report generated successfully.'),
              backgroundColor: NVColors.success,
            ));
          },
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: const Text('Generate Report'),
          style: OutlinedButton.styleFrom(
            foregroundColor: NVColors.secondary, side: const BorderSide(color: NVColors.secondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )),
      ]),
    );
  }

  Widget _buildRegionTable() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.table_chart_rounded, color: NVColors.doctorColor, size: 16),
          SizedBox(width: 8),
          Text('Segmented Regions', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('Region', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text('Volume', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text('% of Total', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
            Expanded(flex: 3, child: Text('Confidence', style: TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 4),
        ..._segData.map((r) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: NVColors.border.withValues(alpha: 0.4)))),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(r.name, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ])),
            Expanded(flex: 2, child: Text(r.volume, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(r.percentage, style: TextStyle(color: r.color, fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 3, child: Row(children: [
              Expanded(child: LinearProgressIndicator(value: r.confidence, backgroundColor: NVColors.border, valueColor: AlwaysStoppedAnimation<Color>(r.color), minHeight: 5, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Text('${(r.confidence * 100).toInt()}%', style: const TextStyle(color: NVColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
          ]),
        )),
      ]),
    );
  }
}

class _SegRegion { final String name, volume, percentage; final Color color; final double confidence;
  _SegRegion(this.name, this.volume, this.percentage, this.color, this.confidence);
}
class _LayerToggle extends StatelessWidget {
  final String label; final bool active; final Color color; final VoidCallback onTap;
  const _LayerToggle({required this.label, required this.active, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: active ? color.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: active ? color : NVColors.border)), child: Text(label, style: TextStyle(color: active ? color : NVColors.textMuted, fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.normal))));
}
class _MeasureTile extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _MeasureTile({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 8), Expanded(child: Text(label, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12))), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))]));
}
class _ModelInfo extends StatelessWidget {
  final String label, value;
  const _ModelInfo({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 11))), Text(value, style: const TextStyle(color: NVColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))]));
}
class _ScanLabel extends StatelessWidget {
  final String text;
  const _ScanLabel({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(5)), child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10)));
}
class _MiniBtn extends StatelessWidget {
  final IconData icon;
  const _MiniBtn({required this.icon});
  @override
  Widget build(BuildContext context) => Container(width: 26, height: 26, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white12)), child: Icon(icon, color: Colors.white70, size: 14));
}
class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9))]);
}

class _BrainScanPainter extends CustomPainter {
  final bool showMask, showContour;
  final double opacity;
  const _BrainScanPainter({required this.showMask, required this.showContour, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    // Brain outline
    final outline = Paint()..color = Colors.white.withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 10), width: size.width * 0.6, height: size.height * 0.75), outline);
    // Center line
    canvas.drawLine(Offset(cx, cy - size.height * 0.35), Offset(cx, cy + size.height * 0.3), outline..strokeWidth = 0.6);
    // Gray matter simulation
    for (int i = 0; i < 8; i++) {
      final p = Paint()..color = Colors.white.withValues(alpha: 0.03 + i * 0.005)..style = PaintingStyle.stroke..strokeWidth = 0.8;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 20 + i * 5, cy - 10), width: size.width * (0.1 + i * 0.06), height: size.height * (0.1 + i * 0.07)), p);
    }
    // Lesion mask
    if (showMask) {
      final mask = Paint()..color = NVColors.error.withValues(alpha: 0.45 * opacity)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 40, cy - 30), width: 70, height: 48), mask);
      final edema = Paint()..color = NVColors.warning.withValues(alpha: 0.22 * opacity)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 40, cy - 30), width: 110, height: 76), edema);
    }
    // Contour
    if (showContour) {
      final contour = Paint()..color = NVColors.secondary.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.8;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 40, cy - 30), width: 70, height: 48), contour);
    }
  }

  @override
  bool shouldRepaint(covariant _BrainScanPainter old) =>
      old.showMask != showMask || old.showContour != showContour || old.opacity != opacity;
}
