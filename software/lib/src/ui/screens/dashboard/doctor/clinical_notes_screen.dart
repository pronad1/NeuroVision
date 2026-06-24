// lib/src/ui/screens/dashboard/doctor/clinical_notes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../../utils/download_helper.dart';
import '../../../../services/medical_service.dart';
import '../../../../models/medical_case.dart';

class ClinicalNotesScreen extends StatefulWidget {
  const ClinicalNotesScreen({super.key});
  @override
  State<ClinicalNotesScreen> createState() => _ClinicalNotesScreenState();
}

class _ClinicalNotesScreenState extends State<ClinicalNotesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  final _noteController = TextEditingController();
  String _selectedCase = 'CASE-2026-047';
  String _selectedTemplate = 'Diagnosis Report';
  bool _isSaving = false;

  final _templates = ['Diagnosis Report', 'Radiology Findings', 'Follow-up Notes', 'Second Opinion', 'Treatment Plan'];

  List<MedicalCase> _cases = [];

  final _notes = [
    _ClinicalNote('CASE-2026-047', 'Dr. Ahmad', 'Patient presents with ischemic stroke in left MCA territory. AI confidence 94.2%. Recommend immediate intervention. NIHSS score 8. CT perfusion shows penumbra of approximately 85ml.', '2026-05-13 14:32', NVColors.error),
    _ClinicalNote('CASE-2026-045', 'Dr. Ahmad', 'High-grade glioma confirmed by AI segmentation. Tumor volume approximately 24.3cc. Multidisciplinary team consultation required. Biopsy recommended for histological grading.', '2026-05-12 09:15', NVColors.warning),
    _ClinicalNote('CASE-2026-043', 'Dr. Ahmad', 'Right lower lobe pneumonia confirmed. Consolidation pattern consistent with bacterial etiology. Recommend broad-spectrum antibiotics. Follow-up CXR in 48 hours.', '2026-05-11 16:44', NVColors.success),
  ];

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
        _cases = cases;
        if (_cases.isNotEmpty && !_cases.any((e) => e.caseId == _selectedCase)) {
          _selectedCase = _cases.first.caseId;
        }
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _noteController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    return NVScaffold(
      currentRoute: '/dashboard/doctor/notes',
      role: AppConstants.roleDoctor,
      title: 'Clinical Notes',
      subtitle: 'Structured case notes and diagnostic reports',
      userName: user?.name ?? 'Doctor',
      roleColor: NVColors.doctorColor,
      fadeAnimation: _fade,
      body: Column(children: [
        NVTopBar(title: 'Clinical Notes', subtitle: 'Structured case notes and diagnostic reports', user: user?.name ?? 'Doctor', roleColor: NVColors.doctorColor),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _buildEditor()),
                const SizedBox(width: 16),
                SizedBox(width: 320, child: _buildHistory()),
              ]);
            }
            return Column(children: [
              _buildEditor(),
              const SizedBox(height: 16),
              _buildHistory(),
            ]);
          }),
        )),
      ]),
    );
  }

  Widget _buildEditor() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 10,
          children: [
          const Icon(Icons.note_alt_rounded, color: NVColors.doctorColor, size: 18),
          const SizedBox(width: 8),
          const Text('New Clinical Note', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 16),
          // Case selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(8), border: Border.all(color: NVColors.border)),
            child: DropdownButtonHideUnderline(
              child: _cases.isEmpty 
                ? const Text('Loading cases...', style: TextStyle(color: NVColors.textMuted, fontSize: 13))
                : DropdownButton<String>(
                  value: _selectedCase,
                  dropdownColor: NVColors.bgCard,
                  style: const TextStyle(color: NVColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                  items: _cases.map((c) => DropdownMenuItem(value: c.caseId, child: Text('Anonymous (${c.caseId})'))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedCase = v); },
                ),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Template selector
        const Text('Template', style: TextStyle(color: NVColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _templates.map((t) {
            final isSelected = _selectedTemplate == t;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTemplate = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? NVColors.doctorColor.withValues(alpha: 0.15) : NVColors.bgDeep,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? NVColors.doctorColor : NVColors.border),
                  ),
                  child: Text(t, style: TextStyle(color: isSelected ? NVColors.doctorColor : NVColors.textMuted, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 16),

        // Fields row
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: 180, child: _FieldBlock(label: 'Patient / Case ID', value: 'Anonymous / $_selectedCase')),
            SizedBox(width: 150, child: _FieldBlock(label: 'Note Type', value: _selectedTemplate)),
            SizedBox(width: 130, child: _FieldBlock(label: 'Date', value: DateTime.now().toString().substring(0, 10))),
            const SizedBox(width: 110, child: _FieldBlock(label: 'Priority', value: 'Routine')),
          ],
        ),
        const SizedBox(height: 16),

        // Text editor
        const Text('Clinical Observations', style: TextStyle(color: NVColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: NVColors.bgDeep,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NVColors.border),
          ),
          child: Column(children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: NVColors.border))),
              child: Row(children: [
                _ToolbarBtn(icon: Icons.format_bold, onTap: () {}),
                _ToolbarBtn(icon: Icons.format_italic, onTap: () {}),
                _ToolbarBtn(icon: Icons.format_list_bulleted, onTap: () {}),
                const SizedBox(width: 8),
                Container(width: 1, height: 16, color: NVColors.border),
                const SizedBox(width: 8),
                _ToolbarBtn(icon: Icons.medical_services_rounded, onTap: () => _insertTemplate()),
                _ToolbarBtn(icon: Icons.mic_rounded, onTap: () {}),
              ]),
            ),
            TextField(
              controller: _noteController,
              maxLines: 12,
              style: const TextStyle(color: NVColors.textPrimary, fontSize: 14, height: 1.6),
              decoration: const InputDecoration(
                hintText: 'Enter detailed clinical observations, findings, and recommendations...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveNote,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.save_rounded, size: 16),
            label: const Text('Save Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NVColors.doctorColor, foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              downloadFile('Clinical_Note_Export.txt', _noteController.text.isNotEmpty ? _noteController.text : 'Empty Note');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Clinical notes exported as PDF successfully.'),
                backgroundColor: NVColors.success,
              ));
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('Export PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: NVColors.secondary, side: const BorderSide(color: NVColors.secondary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _noteController.clear()),
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: NVColors.textMuted, side: const BorderSide(color: NVColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildHistory() {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.history_rounded, color: NVColors.doctorColor, size: 16),
          SizedBox(width: 6),
          Text('Recent Notes', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        ..._notes.map((n) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: NVColors.bgDeep,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NVColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 4, color: n.accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(n.caseId, style: const TextStyle(color: NVColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                      const Spacer(),
                      Text(n.date.substring(5), style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
                    ]),
                    const SizedBox(height: 4),
                    Text(n.author, style: const TextStyle(color: NVColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    Text(n.content, style: const TextStyle(color: NVColors.textMuted, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      GestureDetector(onTap: () => setState(() => _noteController.text = n.content), child: const Text('Edit', style: TextStyle(color: NVColors.doctorColor, fontSize: 11, fontWeight: FontWeight.w600))),
                      const SizedBox(width: 12),
                      const Text('Export', style: TextStyle(color: NVColors.secondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        )),
      ]),
    );
  }

  void _insertTemplate() {
    if (_cases.isEmpty) return;
    final caseData = _cases.firstWhere((c) => c.caseId == _selectedCase, orElse: () => _cases.first);
    
    final templates = {
      'Diagnosis Report': 'PATIENT: Anonymous\nCASE ID: ${caseData.caseId}\n\nCHIEF COMPLAINT:\n\nHISTORY OF PRESENT ILLNESS:\n\nAI FINDINGS (Autonomous):\n- Modality: ${caseData.modality}\n- Prediction: ${caseData.aiPrediction ?? "Unknown"}\n- Confidence: ${caseData.aiConfidence?.toStringAsFixed(1) ?? "N/A"}%\n- Severity: ${caseData.aiSeverity ?? "N/A"}\n\nCLINICAL ASSESSMENT:\n\nRECOMMENDATIONS:\n',
      'Radiology Findings': 'PATIENT: Anonymous\nCASE ID: ${caseData.caseId}\n\nIMAGING MODALITY: ${caseData.modality}\n\nTECHNIQUE:\n\nFINDINGS:\n- Location: \n- Size: \n- Characteristics: \n\nIMPRESSION:\n\nAI CORRELATION:\n- AI flagged ${caseData.aiPrediction ?? "Unknown"} with ${caseData.aiConfidence?.toStringAsFixed(1) ?? "N/A"}% confidence.\n',
    };
    _noteController.text = templates[_selectedTemplate] ?? 'PATIENT: Anonymous\n\n';
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;
    
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      final user = Provider.of<NVAuthProvider>(context, listen: false).nvUser;
      setState(() {
        _isSaving = false;
        _notes.insert(0, _ClinicalNote(
          _selectedCase,
          user?.name ?? 'Doctor',
          _noteController.text.trim(),
          DateTime.now().toString().substring(0, 16),
          NVColors.success,
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Clinical note saved successfully'),
        backgroundColor: NVColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _noteController.clear();
    }
  }
}

class _ClinicalNote {
  final String caseId, author, content, date;
  final Color accentColor;
  _ClinicalNote(this.caseId, this.author, this.content, this.date, this.accentColor);
}

class _FieldBlock extends StatelessWidget {
  final String label, value;
  const _FieldBlock({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: NVColors.bgDeep, borderRadius: BorderRadius.circular(8), border: Border.all(color: NVColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _ToolbarBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, color: NVColors.textSecondary, size: 16)),
    );
  }
}

