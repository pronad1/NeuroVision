// lib/src/ui/screens/dashboard/radiologist/annotation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_glass_card.dart';

class AnnotationScreen extends StatefulWidget {
  const AnnotationScreen({super.key});
  @override
  State<AnnotationScreen> createState() => _AnnotationScreenState();
}

class _AnnotationScreenState extends State<AnnotationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  String _activeTool = 'bbox';
  Color _activeColor = NVColors.error;
  double _brushSize = 6.0;
  String _activeLabel = 'Lesion';
  final List<_Annotation> _annotations = [
    _Annotation('BBox', 'Lesion Region', NVColors.error, Rect.fromLTWH(120, 100, 80, 60)),
    _Annotation('Polygon', 'Tumor Core', NVColors.warning, Rect.fromLTWH(200, 150, 50, 40)),
    _Annotation('Contour', 'Edema Border', NVColors.info, Rect.fromLTWH(100, 80, 120, 90)),
  ];

  final _tools = [
    ('bbox', Icons.crop_rounded, 'Bounding Box'),
    ('polygon', Icons.polyline_rounded, 'Polygon'),
    ('brush', Icons.brush_rounded, 'Brush'),
    ('eraser', Icons.auto_fix_normal_rounded, 'Eraser'),
    ('measure', Icons.straighten_rounded, 'Measure'),
    ('point', Icons.location_on_rounded, 'Point'),
  ];
  final _labels = ['Lesion', 'Tumor Core', 'Edema', 'Hemorrhage', 'Normal', 'Uncertain'];

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
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width < 1200;

    return NVScaffold(
      currentRoute: '/dashboard/radiologist/annotations',
      role: AppConstants.roleRadiologist,
      title: 'Image Annotation',
      subtitle: 'Professional lesion annotation and marking tools',
      userName: user?.name ?? 'Radiologist',
      roleColor: NVColors.radiologistColor,
      fadeAnimation: _fade,
      body: Column(children: [
        NVTopBar(title: 'Image Annotation', subtitle: 'Professional lesion annotation and marking tools', user: user?.name ?? 'Radiologist', roleColor: NVColors.radiologistColor),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isMobile
                  ? Column(children: [
                      _buildToolbox(),
                      const SizedBox(height: 12),
                      LimitedBox(
                        maxHeight: 300,
                        child: _buildCanvas(),
                      ),
                      const SizedBox(height: 12),
                      LimitedBox(
                        maxHeight: 400,
                        child: SingleChildScrollView(child: _buildProperties()),
                      ),
                    ])
                  : isTablet
                      ? Column(
                          children: [
                            SizedBox(
                              height: 400,
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                SizedBox(width: 72, child: _buildToolbox()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildCanvas()),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(child: _buildProperties()),
                          ],
                        )
                      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(width: 72, child: _buildToolbox()),
                          const SizedBox(width: 12),
                          Expanded(child: SizedBox(height: 600, child: _buildCanvas())),
                          const SizedBox(width: 12),
                          SizedBox(width: 280, child: SingleChildScrollView(child: _buildProperties())),
                        ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildToolbox() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return NVGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._tools.map((t) {
                    final isActive = _activeTool == t.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Tooltip(
                        message: t.$3,
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTool = t.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isActive ? NVColors.radiologistColor.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isActive ? NVColors.radiologistColor : Colors.transparent),
                            ),
                            child: Icon(t.$2, color: isActive ? NVColors.radiologistColor : NVColors.textMuted, size: 20),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  const VerticalDivider(color: NVColors.border, width: 1),
                  const SizedBox(width: 6),
                  ...[NVColors.error, NVColors.warning, NVColors.success, NVColors.info, NVColors.secondary].map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeColor = c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: _activeColor == c ? Colors.white : Colors.transparent, width: 2),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            )
          : Column(children: [
              ..._tools.map((t) {
                final isActive = _activeTool == t.$1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Tooltip(
                    message: t.$3,
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTool = t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isActive ? NVColors.radiologistColor.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isActive ? NVColors.radiologistColor : Colors.transparent),
                        ),
                        child: Icon(t.$2, color: isActive ? NVColors.radiologistColor : NVColors.textMuted, size: 20),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Divider(color: NVColors.border),
              const SizedBox(height: 8),
              ...[NVColors.error, NVColors.warning, NVColors.success, NVColors.info, NVColors.secondary].map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeColor = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: _activeColor == c ? Colors.white : Colors.transparent, width: 2),
                      ),
                    ),
                  ),
                );
              }),
            ]),
    );
  }

  Widget _buildCanvas() {
    return NVGlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // Canvas header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              const Icon(Icons.draw_rounded, color: NVColors.radiologistColor, size: 16),
              const SizedBox(width: 8),
              const Text('CASE-2026-047 · Brain MRI', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 16),
              Text('Tool: ${_tools.firstWhere((t) => t.$1 == _activeTool).$3}', style: const TextStyle(color: NVColors.radiologistColor, fontSize: 12)),
              const SizedBox(width: 16),
              _CanvasBtn(icon: Icons.undo_rounded, onTap: () {}),
              const SizedBox(width: 4),
              _CanvasBtn(icon: Icons.redo_rounded, onTap: () {}),
              const SizedBox(width: 4),
              _CanvasBtn(icon: Icons.zoom_in_rounded, onTap: () {}),
              const SizedBox(width: 4),
              _CanvasBtn(icon: Icons.zoom_out_rounded, onTap: () {}),
              const SizedBox(width: 4),
              _CanvasBtn(icon: Icons.fullscreen_rounded, onTap: () {}),
            ]),
          ),
        ),
        // Annotation canvas — fixed height to avoid Expanded-in-scroll issues
        Container(
          height: 420,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NVColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(children: [
              // Background scan
              Container(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -0.1), radius: 0.8, colors: [const Color(0xFF1a1a2e).withValues(alpha: 0.95), Colors.black]))),
              Positioned.fill(child: CustomPaint(painter: _AnnotationCanvasPainter(annotations: _annotations, activeColor: _activeColor, activeTool: _activeTool))),
              // Cross cursor indicator
              Positioned(top: 12, right: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _activeColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(_activeLabel, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ]),
              )),
              // Slice nav
              Positioned(bottom: 12, left: 0, right: 0, child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.skip_previous_rounded, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  const Text('Slice 42 / 86', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  const Icon(Icons.skip_next_rounded, color: Colors.white54, size: 16),
                ]),
              ))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildProperties() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Label selector
        NVGlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Annotation Label', style: TextStyle(color: NVColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ..._labels.map((l) {
              final isActive = _activeLabel == l;
              return GestureDetector(
                onTap: () => setState(() => _activeLabel = l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? NVColors.radiologistColor.withValues(alpha: 0.12) : NVColors.bgDeep,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? NVColors.radiologistColor : NVColors.border),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(l, style: TextStyle(color: isActive ? NVColors.radiologistColor : NVColors.textSecondary, fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal))),
                    if (isActive) Icon(Icons.check_rounded, color: NVColors.radiologistColor, size: 14),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
            const Text('Brush Size', style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(activeTrackColor: NVColors.radiologistColor, inactiveTrackColor: NVColors.border, thumbColor: NVColors.radiologistColor, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5), trackHeight: 2),
              child: Slider(value: _brushSize, min: 2, max: 20, onChanged: (v) => setState(() => _brushSize = v)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Annotations list
        NVGlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Annotations', style: TextStyle(color: NVColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_annotations.length}', style: const TextStyle(color: NVColors.radiologistColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 10),
            ..._annotations.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(8), border: Border.all(color: NVColors.border)),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: a.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.label, style: const TextStyle(color: NVColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
                  Text(a.type, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
                ])),
                Icon(Icons.visibility_rounded, color: NVColors.textMuted, size: 14),
              ]),
            )),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save_rounded, size: 14),
              label: const Text('Save Annotations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NVColors.radiologistColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _Annotation {
  final String type, label;
  final Color color;
  final Rect rect;
  _Annotation(this.type, this.label, this.color, this.rect);
}

class _AnnotationCanvasPainter extends CustomPainter {
  final List<_Annotation> annotations;
  final Color activeColor;
  final String activeTool;
  const _AnnotationCanvasPainter({required this.annotations, required this.activeColor, required this.activeTool});

  @override
  void paint(Canvas canvas, Size size) {
    // Brain outline
    final outline = Paint()..color = Colors.white.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2 - 20), width: size.width * 0.55, height: size.height * 0.7), outline);
    canvas.drawLine(Offset(size.width / 2, size.height * 0.12), Offset(size.width / 2, size.height * 0.78), outline..strokeWidth = 0.5);

    // Annotations
    for (final a in annotations) {
      final fill = Paint()..color = a.color.withValues(alpha: 0.15)..style = PaintingStyle.fill;
      final stroke = Paint()..color = a.color..style = PaintingStyle.stroke..strokeWidth = 1.8;
      final rect = Rect.fromLTWH(a.rect.left / 400 * size.width, a.rect.top / 300 * size.height, a.rect.width / 400 * size.width, a.rect.height / 300 * size.height);
      if (a.type == 'BBox') {
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
        // Corner handles
        _drawHandle(canvas, rect.topLeft, a.color);
        _drawHandle(canvas, rect.topRight, a.color);
        _drawHandle(canvas, rect.bottomLeft, a.color);
        _drawHandle(canvas, rect.bottomRight, a.color);
      } else {
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, stroke);
      }
      // Label
      final tp = TextPainter(
        text: TextSpan(text: a.label, style: TextStyle(color: a.color, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, rect.topLeft + const Offset(2, -14));
    }
  }

  void _drawHandle(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(pos, 4, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(pos, 4, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _AnnotationCanvasPainter old) => true;
}

class _CanvasBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CanvasBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(6), border: Border.all(color: NVColors.border)), child: Icon(icon, color: NVColors.textSecondary, size: 14)));
}
