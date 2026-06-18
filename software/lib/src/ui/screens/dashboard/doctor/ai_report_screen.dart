// lib/src/ui/screens/dashboard/doctor/ai_report_screen.dart
//
// Feature: AI-Powered Radiology Report Generation
// Academic concept: Multi-Modal AI — Computer Vision findings → LLM clinical report
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../../utils/download_helper.dart';

// ─── Mock data models ────────────────────────────────────────────────────────

class _ReportSection {
  final String title;
  final String content;
  _ReportSection(this.title, this.content);
}

class _MockReport {
  final String reportId;
  final String urgency;
  final Color urgencyColor;
  final List<_ReportSection> sections;
  _MockReport(this.reportId, this.urgency, this.urgencyColor, this.sections);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AIReportScreen extends StatefulWidget {
  const AIReportScreen({super.key});

  @override
  State<AIReportScreen> createState() => _AIReportScreenState();
}

class _AIReportScreenState extends State<AIReportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Form state
  String _selectedCase = 'CASE-2026-047';
  String _selectedModality = 'Brain MRI';
  String _selectedModel = 'DERNet Ensemble';
  String _selectedSeverity = 'Medium';

  // UI state
  bool _isGenerating = false;
  bool _reportGenerated = false;
  _MockReport? _report;
  int _visibleSections = 0;

  static const _cases = [
    'CASE-2026-047', 'CASE-2026-046', 'CASE-2026-045',
    'CASE-2026-044', 'CASE-2026-043',
  ];

  static const _caseDetails = {
    'CASE-2026-047': ('Ischemic Stroke Lesion Detected', 0.942, 3.7, 'Left frontal lobe'),
    'CASE-2026-046': ('L4-L5 Disc Herniation', 0.887, 1.2, 'L4-L5 intervertebral space'),
    'CASE-2026-045': ('Glioblastoma Multiforme', 0.961, 8.4, 'Right temporal lobe'),
    'CASE-2026-044': ('Intracranial Hemorrhage', 0.913, 5.1, 'Left basal ganglia'),
    'CASE-2026-043': ('Bilateral Pneumonia', 0.875, 12.3, 'Bilateral lower lobes'),
  };

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

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _reportGenerated = false;
      _visibleSections = 0;
    });

    // Simulate LLM API call latency
    await Future.delayed(const Duration(milliseconds: 2800));

    final details = _caseDetails[_selectedCase]!;
    final report = _buildMockReport(details);

    setState(() {
      _isGenerating = false;
      _reportGenerated = true;
      _report = report;
    });

    // Animate sections appearing one by one
    for (int i = 1; i <= report.sections.length; i++) {
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) setState(() => _visibleSections = i);
    }
  }

  _MockReport _buildMockReport(
      (String, double, double, String) details) {
    final (prediction, confidence, coverage, region) = details;
    final conf = (confidence * 100).toStringAsFixed(1);
    final cov = coverage.toStringAsFixed(2);
    final urgencyMap = {
      'High': ('URGENT — Immediate clinical review required', NVColors.error),
      'Medium': ('PRIORITY — Review within 24 hours', NVColors.warning),
      'Low': ('ROUTINE — Schedule follow-up', NVColors.info),
      'None': ('NORMAL — No immediate action required', NVColors.success),
    };
    final (urgency, urgencyColor) = urgencyMap[_selectedSeverity]!;
    final now = DateTime.now();
    final reportId = 'RPT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(1000 + now.millisecond % 9000)}';

    return _MockReport(reportId, urgency, urgencyColor, [
      _ReportSection('Patient & Examination Information',
          'Case ID: $_selectedCase\n'
          'Imaging Modality: $_selectedModality\n'
          'Report Generated: ${_formatDate(now)}\n'
          'AI Pipeline: $_selectedModel\n'
          'Processing Standard: ISLES-2022 / Clinical Grade AI'),
      _ReportSection('Clinical Findings',
          'AI analysis of the $_selectedModality scan demonstrates evidence of '
          '$prediction in $region. The deep learning ensemble ($_selectedModel) '
          'reports a diagnostic confidence of $conf% with a lesion coverage of '
          '$cov% of the total scan volume. Signal intensity abnormalities consistent '
          'with the predicted pathology are identified. Grad-CAM explainability '
          'visualization localizes the primary region of interest to the stated anatomical area.'),
      _ReportSection('AI Model Impressions',
          '1. $prediction — AI confidence $conf% ($_selectedModel)\n'
          '2. Lesion severity assessed as: $_selectedSeverity\n'
          '3. Lesion coverage: $cov% of imaged volume\n'
          '4. Explainability (Grad-CAM) confirms localized activation in the region of predicted pathology\n'
          '5. Ensemble consensus across DERNet, SegResNet, and AttentionUNet pipelines'),
      _ReportSection('Explainability Analysis',
          'Gradient-weighted Class Activation Maps (Grad-CAM) were applied to '
          'localize AI decision regions. The activation map confirms that the '
          'model\'s prediction is driven by signal changes in the anatomically '
          'relevant region, rather than image artifacts or background noise. '
          'Segmentation masks delineate the lesion boundary with mean Dice: 0.81. '
          'Model epistemic uncertainty in lesion boundary region: LOW–MODERATE.'),
      _ReportSection('Radiological Assessment & Recommendations',
          _getRecommendation()),
      _ReportSection('Quality & Confidence Metrics',
          'AI Diagnostic Confidence: $conf%\n'
          'Ensemble Agreement: High (3/3 models consensus)\n'
          'Image Quality Score: 94/100 (Acceptable for AI analysis)\n'
          'Uncertainty Level: ${confidence > 0.85 ? 'LOW' : 'MODERATE'}\n'
          'Report Status: DRAFT — Requires validation by licensed clinician'),
    ]);
  }

  String _getRecommendation() {
    switch (_selectedSeverity) {
      case 'None':
        return 'No immediate intervention indicated. Routine clinical follow-up as per '
            'institutional protocol. Repeat imaging in 12 months unless symptoms develop.';
      case 'Low':
        return 'Clinical correlation with patient history recommended. Follow-up '
            '$_selectedModality in 3–6 months. Conservative management and specialist '
            'consultation as clinically indicated.';
      case 'Medium':
        return 'Prompt specialist review advised. Consider neurology/radiology MDT '
            'discussion. Repeat imaging within 4–8 weeks. Clinical examination for '
            'corroborating neurological signs is recommended.';
      default:
        return 'URGENT: Immediate specialist review required. Transfer to appropriate '
            'clinical care pathway. Emergency multidisciplinary assessment. '
            'Do not delay intervention pending clinical evaluation. Alert on-call team.';
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} UTC';
  }

  @override
  Widget build(BuildContext context) {
    return NVScaffold(
      currentRoute: '/dashboard/doctor/ai-report',
      role: AppConstants.roleDoctor,
      title: 'AI Report Generator',
      subtitle: 'Multi-Modal AI Clinical Draft Report',
      userName: 'Doctor',
      roleColor: NVColors.doctorColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'AI Report Generator',
            subtitle: 'Multi-Modal AI — Vision Findings → Clinical Draft Report',
            user: 'Doctor',
            roleColor: NVColors.doctorColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConceptBanner(),
                  const SizedBox(height: 20),
                  _buildMainLayout(),
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
        gradient: LinearGradient(
          colors: [
            NVColors.doctorColor.withValues(alpha: 0.10),
            NVColors.secondary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NVColors.doctorColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [NVColors.doctorColor, Color(0xFF0090B8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Multi-Modal AI Report Generation',
                    style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 3),
                Text(
                  'AI computer vision findings are passed to a language model to generate '
                  'a structured clinical draft report — combining Vision AI + LLM.',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NVColors.doctorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NVColors.doctorColor.withValues(alpha: 0.3)),
            ),
            child: const Text('RESEARCH FEATURE',
                style: TextStyle(color: NVColors.doctorColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 750;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 320, child: _buildConfigPanel()),
            const SizedBox(width: 16),
            Expanded(child: _buildReportPanel()),
          ],
        );
      }
      return Column(children: [_buildConfigPanel(), const SizedBox(height: 16), _buildReportPanel()]);
    });
  }

  Widget _buildConfigPanel() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.settings_rounded, color: NVColors.doctorColor, size: 16),
            SizedBox(width: 8),
            Text('Report Configuration', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 20),
          _buildDropdownField('Case ID', _selectedCase, _cases, (v) => setState(() => _selectedCase = v!)),
          const SizedBox(height: 14),
          _buildDropdownField('Modality', _selectedModality,
              ['Brain MRI', 'Spine MRI', 'Chest X-Ray', 'CT Scan'],
              (v) => setState(() => _selectedModality = v!)),
          const SizedBox(height: 14),
          _buildDropdownField('AI Model Pipeline', _selectedModel,
              ['DERNet Ensemble', 'SegResNet', 'AttentionUNet', 'EfficientNetV2'],
              (v) => setState(() => _selectedModel = v!)),
          const SizedBox(height: 14),
          _buildDropdownField('Severity', _selectedSeverity,
              ['None', 'Low', 'Medium', 'High'],
              (v) => setState(() => _selectedSeverity = v!)),
          const SizedBox(height: 24),
          // Case details preview
          if (_caseDetails.containsKey(_selectedCase)) ...[
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
                  const Text('AI Findings Preview', style: TextStyle(color: NVColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(_caseDetails[_selectedCase]!.$1,
                      style: const TextStyle(color: NVColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Confidence: ${(_caseDetails[_selectedCase]!.$2 * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: NVColors.doctorColor, fontSize: 11)),
                  Text('Coverage: ${_caseDetails[_selectedCase]!.$3.toStringAsFixed(1)}%',
                      style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
                  Text('Region: ${_caseDetails[_selectedCase]!.$4}',
                      style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_isGenerating ? 'Generating...' : 'Generate AI Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NVColors.doctorColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: NVColors.bgDeep,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NVColors.border),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: NVColors.textPrimary, fontSize: 13)))).toList(),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: NVColors.bgCard,
            style: const TextStyle(color: NVColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildReportPanel() {
    if (_isGenerating) return _buildGeneratingState();
    if (!_reportGenerated || _report == null) return _buildEmptyState();
    return _buildReport(_report!);
  }

  Widget _buildEmptyState() {
    return NVGlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: NVColors.doctorColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: NVColors.doctorColor.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.description_rounded, color: NVColors.doctorColor, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('No Report Generated Yet',
              style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Configure the parameters on the left and click\n"Generate AI Report" to create a clinical draft.',
              style: TextStyle(color: NVColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return NVGlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72, height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(NVColors.doctorColor.withValues(alpha: 0.3)),
                ),
              ),
              const Icon(Icons.auto_awesome_rounded, color: NVColors.doctorColor, size: 30),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Generating Clinical Report...',
              style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          const Text('AI is processing your findings through\nthe multi-modal language pipeline',
              style: TextStyle(color: NVColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ..._buildGenerationSteps(),
        ],
      ),
    );
  }

  List<Widget> _buildGenerationSteps() {
    final steps = [
      'Parsing AI model findings...',
      'Structuring clinical terminology...',
      'Generating radiology impressions...',
      'Applying clinical guidelines...',
      'Finalizing report sections...',
    ];
    return steps.asMap().entries.map((e) => _StepItem(label: e.value, index: e.key)).toList();
  }

  Widget _buildReport(_MockReport report) {
    return Column(
      children: [
        // Header bar
        NVGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NVColors.doctorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded, color: NVColors.doctorColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report ${report.reportId}',
                        style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(_selectedCase,
                        style: const TextStyle(color: NVColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: report.urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: report.urgencyColor.withValues(alpha: 0.35)),
                ),
                child: Text(report.urgency,
                    style: TextStyle(color: report.urgencyColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Action buttons
        Row(
          children: [
            Expanded(child: _actionBtn(Icons.copy_rounded, 'Copy', () {
              final text = report.sections.map((s) => '${s.title}\n${s.content}').join('\n\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Report copied to clipboard'),
                backgroundColor: NVColors.bgCard,
                behavior: SnackBarBehavior.floating,
              ));
            })),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.picture_as_pdf_rounded, 'Export PDF', () {
              final text = report.sections.map((s) => '${s.title}\n${s.content}').join('\n\n');
              downloadFile('${report.reportId}_Export.txt', text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('AI clinical report exported as PDF successfully.'),
                backgroundColor: NVColors.success,
                behavior: SnackBarBehavior.floating,
              ));
            }, color: NVColors.secondary)),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.verified_rounded, 'Approve', () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Report approved and sent to records'),
                backgroundColor: NVColors.success.withValues(alpha: 0.8),
                behavior: SnackBarBehavior.floating,
              ));
            }, color: NVColors.success)),
          ],
        ),
        const SizedBox(height: 12),
        // Sections
        ...report.sections.asMap().entries.map((e) {
          final visible = e.key < _visibleSections;
          return AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 0.05),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSection(e.value, e.key),
              ),
            ),
          );
        }),
        // Disclaimer
        if (_visibleSections >= report.sections.length)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NVColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NVColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: NVColors.warning, size: 16),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'DRAFT REPORT — Must be validated by a licensed clinician before any clinical action. AI assistance does not replace professional medical judgment.',
                      style: TextStyle(color: NVColors.warning, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(_ReportSection section, int index) {
    final icons = [
      Icons.person_rounded,
      Icons.biotech_rounded,
      Icons.psychology_rounded,
      Icons.visibility_rounded,
      Icons.recommend_rounded,
      Icons.analytics_rounded,
    ];
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(index < icons.length ? icons[index] : Icons.article_rounded,
                color: NVColors.doctorColor, size: 15),
            const SizedBox(width: 8),
            Text(section.title,
                style: const TextStyle(color: NVColors.doctorColor, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 10),
          Text(section.content,
              style: const TextStyle(color: NVColors.textSecondary, fontSize: 12.5, height: 1.6)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {Color color = NVColors.doctorColor}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StepItem extends StatefulWidget {
  final String label;
  final int index;
  const _StepItem({required this.label, required this.index});

  @override
  State<_StepItem> createState() => _StepItemState();
}

class _StepItemState extends State<_StepItem> with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 300 + widget.index * 400), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: _visible ? NVColors.success : NVColors.border, size: 14),
            const SizedBox(width: 8),
            Text(widget.label,
                style: const TextStyle(color: NVColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
