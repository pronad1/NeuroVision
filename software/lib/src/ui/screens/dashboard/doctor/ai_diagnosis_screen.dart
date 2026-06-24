// lib/src/ui/screens/dashboard/doctor/ai_diagnosis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_top_bar.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_stat_card.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/medical_service.dart';
import '../../../../models/medical_case.dart';

class AIDiagnosisScreen extends StatefulWidget {
  const AIDiagnosisScreen({super.key});
  @override
  State<AIDiagnosisScreen> createState() => _AIDiagnosisScreenState();
}

class _AIDiagnosisScreenState extends State<AIDiagnosisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  String _selectedCase = 'CASE-2026-047';
  bool _showHeatmap = true;
  bool _showSegmentation = false;
  bool _isUploading = false;

  List<_DiagnosisCase> _cases = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final cases = await MedicalService().getCases();
    if (mounted) {
      setState(() {
        _cases = cases.map((c) {
          Color sevColor = NVColors.success;
          if (c.aiSeverity == 'Medium') sevColor = NVColors.warning;
          if (c.aiSeverity == 'High' || c.aiSeverity == 'Critical') sevColor = NVColors.error;

          final mockNames = ['Alice Johnson', 'Michael Lee', 'Sarah Connor', 'David Kim'];
          final randomName = mockNames[c.caseId.hashCode.abs() % mockNames.length];

          return _DiagnosisCase(
            caseId: c.caseId,
            patientName: randomName,
            modality: c.modality,
            prediction: c.aiPrediction ?? 'Unknown',
            confidence: c.aiConfidence ?? 0.0,
            severity: c.aiSeverity ?? 'Medium',
            modelUsed: c.aiModelUsed ?? 'DERNet',
            severityColor: sevColor,
            heatmapBase64: c.heatmapUrl,
            segmentationMaskBase64: c.segmentationMaskUrl,
          );
        }).toList();

        if (_cases.isNotEmpty && !_cases.any((e) => e.caseId == _selectedCase)) {
          _selectedCase = _cases.first.caseId;
        }
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  _DiagnosisCase? get _current => _cases.where((c) => c.caseId == _selectedCase).firstOrNull ?? _cases.firstOrNull;

  Future<void> _uploadAndAnalyze() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    setState(() => _isUploading = true);
    try {
      final aiResult = await AIService.analyzeBrainMRI(bytes, model: 'DERNet');
      final newCaseId = 'CASE-2026-0${_cases.length + 48}';

      await MedicalService().createCase(
        modality: aiResult.modality,
        uploadedBy: 'doctor',
        imageUrl: '', // mock
        aiPrediction: aiResult.prediction,
        aiConfidence: aiResult.confidence,
        aiSeverity: aiResult.severity,
        aiModelUsed: aiResult.modelUsed,
        heatmapUrl: aiResult.heatmapBase64,
        segmentationMaskUrl: aiResult.segmentationMaskBase64,
      );

      await _loadCases();
      
      if (mounted) {
        setState(() {
          _selectedCase = newCaseId;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Analysis Complete for $newCaseId'), backgroundColor: NVColors.success));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e'), backgroundColor: NVColors.error));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return NVScaffold(
      currentRoute: '/dashboard/doctor/ai-diagnosis',
      role: AppConstants.roleDoctor,
      title: 'AI Diagnosis Review',
      subtitle: 'Review and validate AI predictions per case',
      userName: user?.name ?? 'Doctor',
      roleColor: NVColors.doctorColor,
      fadeAnimation: _fade,
      body: Column(children: [
        NVTopBar(title: 'AI Diagnosis Review', subtitle: 'Review and validate AI predictions per case', user: user?.name ?? 'Doctor', roleColor: NVColors.doctorColor),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Stat row and action button
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                const Text('Dashboard Statistics', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                if (_isUploading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: NVColors.doctorColor, strokeWidth: 2))
                else
                  ElevatedButton.icon(
                    onPressed: _uploadAndAnalyze,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Upload Scan for AI Review'),
                    style: ElevatedButton.styleFrom(backgroundColor: NVColors.doctorColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              if (_cases.isEmpty) return const Center(child: CircularProgressIndicator());
              final isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 260, child: _buildCaseList()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDetailPanel()),
                ]);
              }
              return Column(children: [
                _buildCaseList(),
                const SizedBox(height: 16),
                _buildDetailPanel(),
              ]);
            }),
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
          NVStatCard(label: 'Pending Review', value: '12', icon: Icons.pending_rounded, color: NVColors.warning, subtitle: 'Awaiting validation'),
          NVStatCard(label: 'Avg. Confidence', value: '92.4%', icon: Icons.psychology_rounded, color: NVColors.doctorColor, trend: '+2.1%', trendPositive: true, subtitle: 'This week'),
          NVStatCard(label: 'Critical Cases', value: '3', icon: Icons.priority_high_rounded, color: NVColors.error, subtitle: 'Immediate review'),
          NVStatCard(label: 'Approved Today', value: '8', icon: Icons.verified_rounded, color: NVColors.success, trend: '+3', trendPositive: true, subtitle: 'Cases validated'),
        ],
      );
    });
  }

  Widget _buildCaseList() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cases Queue', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        ..._cases.map((c) {
          final isSelected = c.caseId == _selectedCase;
          return GestureDetector(
            onTap: () => setState(() => _selectedCase = c.caseId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? NVColors.doctorColor.withValues(alpha: 0.1) : NVColors.bgDeep,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? NVColors.doctorColor : NVColors.border),
              ),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: c.severityColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${c.patientName} (${c.caseId})', style: TextStyle(color: isSelected ? NVColors.primary : NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(c.modality, style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
                ])),
                Text('${c.confidence}%', style: TextStyle(color: c.severityColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildDetailPanel() {
    final c = _current;
    if (c == null) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      NVGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: NVColors.doctorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.psychology_rounded, color: NVColors.doctorColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c.patientName} · ${c.caseId}', style: const TextStyle(color: NVColors.primary, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                Text('${c.modality} · ${c.modelUsed}', style: const TextStyle(color: NVColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: c.severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.severityColor.withValues(alpha: 0.4))),
              child: Text(c.severity, style: TextStyle(color: c.severityColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 20),
          const Divider(color: NVColors.border),
          const SizedBox(height: 16),

          // AI Prediction
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
            SizedBox(width: 140, child: _InfoBlock(label: 'AI Prediction', value: c.prediction, valueColor: NVColors.textPrimary, icon: Icons.smart_toy_rounded)),
            SizedBox(width: 140, child: _InfoBlock(label: 'Confidence Score', value: '${c.confidence}%', valueColor: c.severityColor, icon: Icons.speed_rounded)),
            SizedBox(width: 140, child: _InfoBlock(label: 'Model Used', value: c.modelUsed, valueColor: NVColors.secondary, icon: Icons.memory_rounded)),
            SizedBox(width: 140, child: _InfoBlock(label: 'Severity', value: c.severity, valueColor: c.severityColor, icon: Icons.warning_amber_rounded)),
          ]),
          const SizedBox(height: 20),

          // Confidence bar
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Confidence Level', style: TextStyle(color: NVColors.textSecondary, fontSize: 12)),
              Text('${c.confidence}%', style: TextStyle(color: c.severityColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: c.confidence / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: NVColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(c.severityColor),
            ),
          ]),
          const SizedBox(height: 20),

          // Toggle controls
          Row(children: [
            _ToggleChip(label: 'Heatmap Overlay', icon: Icons.thermostat_rounded, active: _showHeatmap, color: NVColors.warning, onTap: () => setState(() => _showHeatmap = !_showHeatmap)),
            const SizedBox(width: 8),
            _ToggleChip(label: 'Segmentation', icon: Icons.layers_rounded, active: _showSegmentation, color: NVColors.secondary, onTap: () => setState(() => _showSegmentation = !_showSegmentation)),
          ]),
          const SizedBox(height: 20),

          // Simulated image viewer
          _buildImageViewer(c),
        ]),
      ),
      const SizedBox(height: 16),

      // Validation panel
      NVGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.fact_check_rounded, color: NVColors.doctorColor, size: 18),
            SizedBox(width: 8),
            Text('Clinical Validation', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
            ElevatedButton.icon(
              onPressed: () => _showApproveDialog(c),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NVColors.success, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('Request Re-analysis'),
              style: OutlinedButton.styleFrom(
                foregroundColor: NVColors.warning, side: const BorderSide(color: NVColors.warning),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.flag_rounded, size: 18),
              label: const Text('Flag'),
              style: OutlinedButton.styleFrom(
                foregroundColor: NVColors.error, side: const BorderSide(color: NVColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildImageViewer(_DiagnosisCase c) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NVColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          // Display uploaded image or fallback mock
          if (c.originalImage != null)
            Image.memory(c.originalImage!, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
          else ...[
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.2),
                  radius: 0.7,
                  colors: [const Color(0xFF1a1a2e).withValues(alpha: 0.9), Colors.black],
                ),
              ),
            ),
            CustomPaint(painter: _BrainOutlinePainter(), size: Size.infinite),
          ],
          
          // Heatmap overlay from API
          if (_showHeatmap)
            if (c.heatmapBase64 != null)
              Opacity(
                opacity: 0.6,
                child: Image.memory(base64Decode(c.heatmapBase64!), fit: BoxFit.contain, width: double.infinity, height: double.infinity)
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.1),
                    radius: 0.35,
                    colors: [NVColors.error.withValues(alpha: 0.6), NVColors.warning.withValues(alpha: 0.3), Colors.transparent],
                  ),
                ),
              ),
              
          // Segmentation overlay from API
          if (_showSegmentation)
            if (c.segmentationMaskBase64 != null)
              Opacity(
                opacity: 0.8,
                child: Image.memory(base64Decode(c.segmentationMaskBase64!), fit: BoxFit.contain, width: double.infinity, height: double.infinity)
              )
            else
              CustomPaint(painter: _SegmentationPainter(), size: Size.infinite),
          // Labels
          Positioned(top: 12, left: 12, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
            child: Text(c.modality, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          )),
          if (_showHeatmap) Positioned(top: 12, right: 12, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: NVColors.warning.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(6)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.thermostat_rounded, color: Colors.black, size: 12),
              SizedBox(width: 4),
              Text('Grad-CAM Active', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          )),
          // AI prediction tag
          Positioned(bottom: 12, left: 12, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: c.severityColor.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
            child: Text('AI: ${c.prediction} · ${c.confidence}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          )),
          Positioned(bottom: 12, right: 12, child: Row(children: [
            _IconTool(icon: Icons.zoom_in_rounded),
            const SizedBox(width: 6),
            _IconTool(icon: Icons.brightness_6_rounded),
            const SizedBox(width: 6),
            _IconTool(icon: Icons.fullscreen_rounded),
          ])),
        ]),
      ),
    );
  }

  void _showApproveDialog(_DiagnosisCase c) {
    final notesCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: NVColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: NVColors.border)),
      title: const Row(children: [
        Icon(Icons.verified_rounded, color: NVColors.success, size: 22),
        SizedBox(width: 8),
        Text('Approve AI Diagnosis', style: TextStyle(color: NVColors.textPrimary, fontSize: 16)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Patient: ${c.patientName}', style: const TextStyle(color: NVColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        Text('Case: ${c.caseId} · ${c.prediction}', style: const TextStyle(color: NVColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('Clinical Notes (optional)', style: TextStyle(color: NVColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: notesCtrl, maxLines: 3,
          style: const TextStyle(color: NVColors.textPrimary, fontSize: 13),
          decoration: const InputDecoration(hintText: 'Add clinical observations...'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: NVColors.textMuted))),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnosis approved successfully'), backgroundColor: NVColors.success, behavior: SnackBarBehavior.floating)); },
          style: ElevatedButton.styleFrom(backgroundColor: NVColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Confirm Approval'),
        ),
      ],
    ));
  }
}

class _DiagnosisCase {
  final String caseId, patientName, modality, prediction, severity, modelUsed;
  final double confidence;
  final Color severityColor;
  final Uint8List? originalImage;
  final String? heatmapBase64;
  final String? segmentationMaskBase64;

  _DiagnosisCase({
    required this.caseId,
    required this.patientName,
    required this.modality,
    required this.prediction,
    required this.confidence,
    required this.severity,
    required this.modelUsed,
    required this.severityColor,
    this.originalImage,
    this.heatmapBase64,
    this.segmentationMaskBase64,
  });
}

class _InfoBlock extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final IconData icon;
  const _InfoBlock({required this.label, required this.value, required this.valueColor, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: NVColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: NVColors.textMuted, size: 12), const SizedBox(width: 4), Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10))]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label; final IconData icon; final bool active; final Color color; final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.icon, required this.active, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : NVColors.bgDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : NVColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? color : NVColors.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: active ? color : NVColors.textMuted, fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

class _IconTool extends StatelessWidget {
  final IconData icon;
  const _IconTool({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
      child: Icon(icon, color: Colors.white70, size: 15),
    );
  }
}

class _BrainOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final cx = size.width * 0.5; final cy = size.height * 0.45;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.55, height: size.height * 0.7), paint);
    canvas.drawLine(Offset(cx, cy - size.height * 0.35), Offset(cx, cy + size.height * 0.35), paint..strokeWidth = 0.8);
    final hemPaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final path = Path()..moveTo(cx - size.width * 0.1, cy - size.height * 0.2)..cubicTo(cx - size.width * 0.2, cy - size.height * 0.1, cx - size.width * 0.15, cy + size.height * 0.05, cx - size.width * 0.08, cy + size.height * 0.15);
    canvas.drawPath(path, hemPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SegmentationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = NVColors.secondary.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 2;
    final fillPaint = Paint()..color = NVColors.secondary.withValues(alpha: 0.08)..style = PaintingStyle.fill;
    final cx = size.width * 0.45; final cy = size.height * 0.38;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 60, height: 40);
    canvas.drawOval(rect, fillPaint);
    canvas.drawOval(rect, paint);
    // lesion pointer
    canvas.drawLine(Offset(cx + 30, cy), Offset(cx + 60, cy - 20), paint..color = NVColors.secondary.withValues(alpha: 0.6)..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
