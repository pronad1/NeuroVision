// lib/src/ui/screens/dashboard/radiologist/dicom_viewer_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_stat_card.dart';

// ─────────────────────────────────────────────────────────────
// Window / Level preset model
// ─────────────────────────────────────────────────────────────
class _WindowPreset {
  final String name;
  final int width;
  final int level;
  const _WindowPreset(this.name, this.width, this.level);
}

// ─────────────────────────────────────────────────────────────
// DicomViewerScreen
// ─────────────────────────────────────────────────────────────
class DicomViewerScreen extends StatefulWidget {
  const DicomViewerScreen({super.key});

  @override
  State<DicomViewerScreen> createState() => _DicomViewerScreenState();
}

class _DicomViewerScreenState extends State<DicomViewerScreen>
    with SingleTickerProviderStateMixin {
  // ── Animations ────────────────────────────────────────────
  late AnimationController _ctrl;
  late Animation<double> _fade;

  // ── Viewer state ─────────────────────────────────────────
  int _currentSlice = 42;
  static const int _totalSlices = 86;
  static const int _thumbnailCount = 12;
  static const int _thumbnailStartSlice = 38;

  String _activePreset = 'Brain';
  int _windowWidth = 400;
  int _windowLevel = 40;

  static const List<_WindowPreset> _presets = [
    _WindowPreset('Brain', 400, 40),
    _WindowPreset('Bone', 2500, 400),
    _WindowPreset('Lung', 1500, -600),
    _WindowPreset('Soft Tissue', 350, 50),
    _WindowPreset('Angio', 600, 300),
  ];

  // ── Measurements ─────────────────────────────────────────
  final List<Map<String, String>> _measurements = [
    {'name': 'Linear 1', 'value': '14.2 mm'},
    {'name': 'Area 1', 'value': '3.8 cm²'},
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

  void _applyPreset(_WindowPreset p) {
    setState(() {
      _activePreset = p.name;
      _windowWidth = p.width;
      _windowLevel = p.level;
    });
  }

  void _changeSlice(int delta) {
    setState(() {
      _currentSlice =
          (_currentSlice + delta).clamp(1, _totalSlices);
    });
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;

    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Row(
        children: [
          NVSidebar(
            currentRoute: '/dashboard/radiologist/dicom',
            role: AppConstants.roleRadiologist,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  NVTopBar(
                    title: 'DICOM Viewer',
                    subtitle:
                        'Full-resolution medical image viewing with window/level controls',
                    user: user?.name ?? 'Radiologist',
                    roleColor: NVColors.radiologistColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          // ── Stats row ──────────────────────────────────
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          // ── Main content ───────────────────────────────
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: slice strip
                                SizedBox(
                                    width: 100,
                                    child: _buildSliceStrip()),
                                const SizedBox(width: 12),
                                // Center: main viewer
                                Expanded(child: _buildMainViewer()),
                                const SizedBox(width: 12),
                                // Right: panels
                                SizedBox(
                                    width: 220,
                                    child: _buildRightPanels()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Stats row
  // ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: NVStatCard(
            label: 'Images Loaded',
            value: '86',
            subtitle: 'Slices · CASE-2026-047',
            icon: Icons.image_rounded,
            color: NVColors.radiologistColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NVStatCard(
            label: 'Current Slice',
            value: '$_currentSlice/$_totalSlices',
            icon: Icons.layers_rounded,
            color: NVColors.doctorColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NVStatCard(
            label: 'Window Width',
            value: '$_windowWidth HU',
            icon: Icons.tune_rounded,
            color: NVColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NVStatCard(
            label: 'Window Level',
            value: '$_windowLevel HU',
            icon: Icons.brightness_6_rounded,
            color: NVColors.success,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Left panel – slice strip
  // ─────────────────────────────────────────────────────────
  Widget _buildSliceStrip() {
    return NVGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          const Text(
            'Slices',
            style: TextStyle(
              color: NVColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _thumbnailCount,
              itemBuilder: (_, i) {
                final sliceNum = _thumbnailStartSlice + i;
                final isSelected = sliceNum == _currentSlice;
                return GestureDetector(
                  onTap: () => setState(() => _currentSlice = sliceNum),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 70,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? [
                                NVColors.radiologistColor
                                    .withValues(alpha: 0.25),
                                const Color(0xFF1a1a2e),
                              ]
                            : [
                                const Color(0xFF0d0d14),
                                Colors.black,
                              ],
                      ),
                      border: Border.all(
                        color: isSelected
                            ? NVColors.radiologistColor
                            : NVColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        children: [
                          // Mini brain painter
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ThumbnailBrainPainter(
                                isSelected: isSelected,
                                sliceOffset: i / _thumbnailCount,
                              ),
                            ),
                          ),
                          // Slice number
                          Positioned(
                            bottom: 4,
                            right: 5,
                            child: Text(
                              '$sliceNum',
                              style: TextStyle(
                                color: isSelected
                                    ? NVColors.radiologistColor
                                    : Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: NVColors.radiologistColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Center panel – main DICOM viewer
  // ─────────────────────────────────────────────────────────
  Widget _buildMainViewer() {
    return NVGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ── Toolbar ────────────────────────────────────────
          _buildToolbar(),
          const Divider(height: 1, color: NVColors.border),
          // ── Image area ────────────────────────────────────
          Expanded(child: _buildImageArea()),
          const Divider(height: 1, color: NVColors.border),
          // ── Slice slider ──────────────────────────────────
          _buildSliceSlider(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Case label
          const Icon(Icons.folder_open_rounded,
              color: NVColors.radiologistColor, size: 14),
          const SizedBox(width: 6),
          const Text(
            'CASE-2026-047 · Brain MRI · T2',
            style: TextStyle(
              color: NVColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          // Window presets
          ..._presets.map((p) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _PresetChip(
                  label: p.name,
                  isActive: _activePreset == p.name,
                  onTap: () => _applyPreset(p),
                ),
              )),
          const Spacer(),
          // Action buttons
          ...[
            (Icons.zoom_in_rounded, 'Zoom In', () {}),
            (Icons.zoom_out_rounded, 'Zoom Out', () {}),
            (Icons.fit_screen_rounded, 'Fit', () {}),
            (Icons.rotate_right_rounded, 'Rotate', () {}),
            (Icons.pan_tool_rounded, 'Pan', () {}),
            (Icons.restart_alt_rounded, 'Reset', () {}),
            (Icons.photo_camera_rounded, 'Screenshot', () {}),
          ].map((t) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _ToolBtn(
                    icon: t.$1, tooltip: t.$2, onTap: t.$3),
              )),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NVColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.05),
                  radius: 0.75,
                  colors: [
                    const Color(0xFF1a1f35).withValues(alpha: 0.95),
                    const Color(0xFF0a0c16),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Brain visualization
            Positioned.fill(
              child: CustomPaint(
                painter: _BrainScanPainter(
                  slice: _currentSlice,
                  totalSlices: _totalSlices,
                  windowWidth: _windowWidth,
                  windowLevel: _windowLevel,
                ),
              ),
            ),
            // DICOM info overlay – top left
            Positioned(
              top: 12,
              left: 12,
              child: _InfoOverlay(lines: const [
                'CASE-2026-047',
                'T2-FLAIR',
                '3T MAGNETOM',
                '1.5 mm',
              ]),
            ),
            // Window/Level – top right
            Positioned(
              top: 12,
              right: 12,
              child: _InfoOverlay(lines: [
                'W: $_windowWidth HU',
                'L: $_windowLevel HU',
                _activePreset,
              ], align: TextAlign.right),
            ),
            // Slice position – bottom left
            Positioned(
              bottom: 12,
              left: 12,
              child: _InfoOverlay(lines: [
                'Slice: $_currentSlice / $_totalSlices',
              ]),
            ),
            // Scale bar – bottom right
            Positioned(
              bottom: 12,
              right: 12,
              child: _ScaleBar(),
            ),
            // Left nav arrow
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _changeSlice(-1),
                  enabled: _currentSlice > 1,
                ),
              ),
            ),
            // Right nav arrow
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _changeSlice(1),
                  enabled: _currentSlice < _totalSlices,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliceSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '1',
            style: const TextStyle(
                color: NVColors.textMuted, fontSize: 10),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: NVColors.radiologistColor,
                inactiveTrackColor: NVColors.border,
                thumbColor: NVColors.radiologistColor,
                overlayColor:
                    NVColors.radiologistColor.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6),
                trackHeight: 3,
              ),
              child: Slider(
                value: _currentSlice.toDouble(),
                min: 1,
                max: _totalSlices.toDouble(),
                divisions: _totalSlices - 1,
                onChanged: (v) =>
                    setState(() => _currentSlice = v.round()),
              ),
            ),
          ),
          Text(
            '$_totalSlices',
            style: const TextStyle(
                color: NVColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Right panel
  // ─────────────────────────────────────────────────────────
  Widget _buildRightPanels() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMetadataCard(),
          const SizedBox(height: 12),
          _buildWindowPresetsCard(),
          const SizedBox(height: 12),
          _buildMeasurementsCard(),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    const rows = [
      ('Case ID', 'CASE-2026-047 (anon.)'),
      ('Modality', 'Brain MRI T2-FLAIR'),
      ('Acquisition', '2026-05-15'),
      ('Scanner', '3T Siemens MAGNETOM'),
      ('Voxel Size', '1.0×1.0×1.5 mm'),
      ('Slices', '86'),
      ('FOV', '240×240 mm'),
    ];

    return NVGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: NVColors.radiologistColor, size: 14),
            const SizedBox(width: 6),
            const Text(
              'DICOM Metadata',
              style: TextStyle(
                color: NVColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ...rows.map((r) => _MetaRow(label: r.$1, value: r.$2)),
        ],
      ),
    );
  }

  Widget _buildWindowPresetsCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tune_rounded,
                color: NVColors.warning, size: 14),
            const SizedBox(width: 6),
            const Text(
              'Window Presets',
              style: TextStyle(
                color: NVColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ..._presets.map((p) {
            final isActive = _activePreset == p.name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _applyPreset(p),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive
                        ? NVColors.radiologistColor
                        : NVColors.textSecondary,
                    backgroundColor: isActive
                        ? NVColors.radiologistColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    side: BorderSide(
                      color: isActive
                          ? NVColors.radiologistColor
                          : NVColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name,
                          style: const TextStyle(fontSize: 11)),
                      Text(
                        'W${p.width}/L${p.level}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isActive
                              ? NVColors.radiologistColor
                                  .withValues(alpha: 0.7)
                              : NVColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMeasurementsCard() {
    return NVGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.straighten_rounded,
                color: NVColors.accent, size: 14),
            const SizedBox(width: 6),
            const Text(
              'Measurements',
              style: TextStyle(
                color: NVColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${_measurements.length}',
              style: const TextStyle(
                  color: NVColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 10),
          ..._measurements.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: NVColors.bgDeep,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NVColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.linear_scale_rounded,
                        color: NVColors.accent, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m['name']!,
                        style: const TextStyle(
                            color: NVColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      m['value']!,
                      style: const TextStyle(
                          color: NVColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 13),
              label: const Text('Add Measurement',
                  style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: NVColors.accent,
                side: const BorderSide(color: NVColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CustomPainter – main brain scan visualization
// ─────────────────────────────────────────────────────────────
class _BrainScanPainter extends CustomPainter {
  final int slice;
  final int totalSlices;
  final int windowWidth;
  final int windowLevel;

  const _BrainScanPainter({
    required this.slice,
    required this.totalSlices,
    required this.windowWidth,
    required this.windowLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;
    final rw = size.width * 0.32;
    final rh = size.height * 0.45;

    // Intensity varies slightly with slice
    final t = slice / totalSlices;
    final brightness = 0.08 + t * 0.04;

    // ── Outer skull oval ────────────────────────────────────
    final skullPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCenter(center: Offset(cx, cy), width: rw * 2, height: rh * 2))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rw * 2, height: rh * 2),
        skullPaint);

    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rw * 2, height: rh * 2),
        outlinePaint);

    // ── Inner parenchyma fill ──────────────────────────────
    final parenchymaPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: brightness + 0.08),
          Colors.white.withValues(alpha: brightness),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
          center: Offset(cx, cy), width: rw * 1.7, height: rh * 1.7))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rw * 1.8, height: rh * 1.8),
        parenchymaPaint);

    // ── Interhemispheric fissure (midline) ─────────────────
    final midlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, cy - rh * 0.85),
      Offset(cx, cy + rh * 0.85),
      midlinePaint,
    );

    // ── Gyri / sulci – curved lines ────────────────────────
    final gyriPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Left hemisphere arcs
    _drawGyrus(canvas, cx - rw * 0.45, cy - rh * 0.35, rw * 0.35, gyriPaint);
    _drawGyrus(canvas, cx - rw * 0.40, cy + rh * 0.05, rw * 0.30, gyriPaint);
    _drawGyrus(canvas, cx - rw * 0.50, cy + rh * 0.40, rw * 0.25, gyriPaint);

    // Right hemisphere arcs
    _drawGyrus(canvas, cx + rw * 0.45, cy - rh * 0.35, rw * 0.35, gyriPaint,
        flip: true);
    _drawGyrus(canvas, cx + rw * 0.40, cy + rh * 0.05, rw * 0.30, gyriPaint,
        flip: true);
    _drawGyrus(canvas, cx + rw * 0.50, cy + rh * 0.40, rw * 0.25, gyriPaint,
        flip: true);

    // ── Lateral ventricles (bright on T2) ─────────────────
    final ventPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    // Left
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - rw * 0.28, cy - rh * 0.05),
            width: rw * 0.28,
            height: rh * 0.35),
        ventPaint);
    // Right
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + rw * 0.28, cy - rh * 0.05),
            width: rw * 0.28,
            height: rh * 0.35),
        ventPaint);

    // ── 3rd ventricle ──────────────────────────────────────
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: rw * 0.1,
            height: rh * 0.2),
        ventPaint);

    // ── Crosshair grid overlay ─────────────────────────────
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    // Horizontal
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), crossPaint);
    // Vertical
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), crossPaint);

    // ── Crosshair center tick ──────────────────────────────
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), tickPaint);
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), tickPaint);
  }

  void _drawGyrus(Canvas canvas, double cx, double cy, double r, Paint paint,
      {bool flip = false}) {
    final path = Path();
    final sweepDir = flip ? -1.0 : 1.0;
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, cy), width: r * 2, height: r * 1.1),
      math.pi * 0.2,
      math.pi * 0.7 * sweepDir,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BrainScanPainter old) =>
      old.slice != slice ||
      old.windowWidth != windowWidth ||
      old.windowLevel != windowLevel;
}

// ─────────────────────────────────────────────────────────────
// CustomPainter – thumbnail mini brain
// ─────────────────────────────────────────────────────────────
class _ThumbnailBrainPainter extends CustomPainter {
  final bool isSelected;
  final double sliceOffset;
  const _ThumbnailBrainPainter(
      {required this.isSelected, required this.sliceOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.36;
    final ry = size.height * 0.38;

    final outlinePaint = Paint()
      ..color = (isSelected ? NVColors.radiologistColor : Colors.white)
          .withValues(alpha: isSelected ? 0.45 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        outlinePaint);

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06 + sliceOffset * 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy), width: rx * 1.8, height: ry * 1.8),
        fillPaint);

    // Midline
    canvas.drawLine(
      Offset(cx, cy - ry * 0.7),
      Offset(cx, cy + ry * 0.7),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..strokeWidth = 0.5,
    );

    // Ventricles (bright)
    final vp = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - rx * 0.3, cy),
            width: rx * 0.3,
            height: ry * 0.35),
        vp);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + rx * 0.3, cy),
            width: rx * 0.3,
            height: ry * 0.35),
        vp);
  }

  @override
  bool shouldRepaint(covariant _ThumbnailBrainPainter old) =>
      old.isSelected != isSelected;
}

// ─────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _PresetChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? NVColors.radiologistColor.withValues(alpha: 0.2)
              : NVColors.bgDeep,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isActive ? NVColors.radiologistColor : NVColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isActive ? NVColors.radiologistColor : NVColors.textMuted,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ToolBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: NVColors.bgDeep,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: NVColors.border),
          ),
          child: Icon(icon, color: NVColors.textSecondary, size: 14),
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _NavArrow(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.2,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

class _InfoOverlay extends StatelessWidget {
  final List<String> lines;
  final TextAlign align;
  const _InfoOverlay(
      {required this.lines, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lines
            .map((l) => Text(
                  l,
                  textAlign: align,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ScaleBar extends StatelessWidget {
  const _ScaleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 2,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '20 mm',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                  color: NVColors.textMuted,
                  fontSize: 10,
                  height: 1.4),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: NVColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
