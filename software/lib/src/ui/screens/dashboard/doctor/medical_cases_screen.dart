// lib/src/ui/screens/dashboard/doctor/medical_cases_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/medical_service.dart';
import '../../../../models/medical_case.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_glass_card.dart';

class MedicalCasesScreen extends StatefulWidget {
  const MedicalCasesScreen({super.key});
  @override
  State<MedicalCasesScreen> createState() => _MedicalCasesScreenState();
}

class _MedicalCasesScreenState extends State<MedicalCasesScreen> {
  final _medService = MedicalService();
  String _filterStatus = 'all';
  String _filterModality = 'all';

  final _statuses = ['all', 'pending', 'in_review', 'validated', 'completed'];
  final _modalities = ['all', 'Brain MRI', 'Spine MRI', 'Chest X-Ray', 'CT Scan'];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<NVAuthProvider>(context);
    final user = auth.nvUser;

    return NVScaffold(
      currentRoute: '/dashboard/doctor/cases',
      role: AppConstants.roleDoctor,
      title: 'Medical Cases',
      subtitle: 'Anonymized case management & AI review',
      userName: user?.name ?? 'Doctor',
      roleColor: NVColors.doctorColor,
      body: Column(
        children: [
          NVTopBar(
            title: 'Medical Cases',
            subtitle: 'Anonymized case management & AI review',
            user: user?.name ?? 'Doctor',
            roleColor: NVColors.doctorColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with filter + new case button
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Cases', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
                      const SizedBox(width: 8),
                      // Status filter
                      _FilterChips(
                        items: _statuses,
                        selected: _filterStatus,
                        onSelected: (v) => setState(() => _filterStatus = v),
                        colorMap: {
                          'all': NVColors.textMuted,
                          'pending': NVColors.info,
                          'in_review': NVColors.warning,
                          'validated': NVColors.success,
                          'completed': NVColors.primary,
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showNewCaseDialog(context, user?.uid ?? ''),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('New Case'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NVColors.doctorColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Modality filter row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _modalities.map((m) {
                      final isSelected = _filterModality == m;
                      return GestureDetector(
                          onTap: () => setState(() => _filterModality = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? NVColors.doctorColor.withValues(alpha: 0.15) : NVColors.bgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? NVColors.doctorColor : NVColors.border,
                              ),
                            ),
                            child: Text(
                              m == 'all' ? 'All Modalities' : m,
                              style: TextStyle(
                                color: isSelected ? NVColors.doctorColor : NVColors.textMuted,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Cases list
                  Expanded(
                    child: StreamBuilder<List<MedicalCase>>(
                      stream: _medService.casesStream(
                        uploadedBy: user?.uid,
                        status: _filterStatus == 'all' ? null : _filterStatus,
                      ),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: NVColors.error)));
                        }
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator(color: NVColors.doctorColor));
                        }
                        var cases = snap.data!;
                        if (_filterModality != 'all') {
                          cases = cases.where((c) => c.modality == _filterModality).toList();
                        }
                        if (cases.isEmpty) {
                          return _EmptyState(
                            icon: Icons.cases_rounded,
                            message: 'No cases found',
                            subtitle: 'Create a new case to get started',
                            color: NVColors.doctorColor,
                          );
                        }
                        return ListView.separated(
                          itemCount: cases.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _CaseCard(case_: cases[i]),
                        );
                      },
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

  void _showNewCaseDialog(BuildContext context, String userId) {
    String selectedModality = AppConstants.modalities.first;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NVColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: NVColors.border)),
        title: const Row(children: [
          Icon(Icons.add_circle_outline_rounded, color: NVColors.doctorColor, size: 20),
          SizedBox(width: 8),
          Text('New Medical Case', style: TextStyle(color: NVColors.textPrimary, fontSize: 16)),
        ]),
        content: StatefulBuilder(builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Imaging Modality', style: TextStyle(color: NVColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              ...AppConstants.modalities.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setDialogState(() => selectedModality = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedModality == m ? NVColors.doctorColor.withValues(alpha: 0.1) : NVColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selectedModality == m ? NVColors.doctorColor : NVColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.medical_information_rounded, color: selectedModality == m ? NVColors.doctorColor : NVColors.textMuted, size: 16),
                        const SizedBox(width: 10),
                        Text(m, style: TextStyle(color: selectedModality == m ? NVColors.doctorColor : NVColors.textSecondary, fontSize: 13)),
                        if (selectedModality == m) ...[
                          const Spacer(),
                          const Icon(Icons.check_rounded, color: NVColors.doctorColor, size: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NVColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NVColors.info.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'A unique anonymous Case ID will be auto-generated (e.g., CASE-2026-048)',
                  style: TextStyle(color: NVColors.info, fontSize: 11),
                ),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: NVColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final caseId = await _medService.createCase(modality: selectedModality, uploadedBy: userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(caseId != null ? 'Case $caseId created successfully' : 'Failed to create case'),
                  backgroundColor: caseId != null ? NVColors.success : NVColors.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NVColors.doctorColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create Case', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final MedicalCase case_;
  const _CaseCard({required this.case_});

  Color get _statusColor => switch (case_.status) {
    'validated' => NVColors.success,
    'in_review' => NVColors.warning,
    'completed' => NVColors.primary,
    _ => NVColors.info,
  };

  @override
  Widget build(BuildContext context) {
    return NVGlassCard(
      hoverable: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Modality icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: NVColors.doctorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NVColors.doctorColor.withValues(alpha: 0.3)),
            ),
            child: Icon(_modalityIcon(case_.modality), color: NVColors.doctorColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(case_.caseId, style: const TextStyle(color: NVColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(case_.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.medical_information_rounded, color: NVColors.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(case_.modality, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12)),
                    if (case_.aiPrediction != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.psychology_rounded, color: NVColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(case_.aiPrediction!, style: const TextStyle(color: NVColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (case_.aiConfidence != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${case_.aiConfidence!.toStringAsFixed(1)}%', style: const TextStyle(color: NVColors.doctorColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('AI Confidence', style: TextStyle(color: NVColors.textMuted, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Row(
            children: [
              if (!case_.radiologistValidated)
                Icon(Icons.radio_button_unchecked_rounded, color: NVColors.textMuted, size: 16)
              else
                const Icon(Icons.check_circle_rounded, color: NVColors.success, size: 16),
              const SizedBox(width: 4),
              if (!case_.doctorApproved)
                Icon(Icons.radio_button_unchecked_rounded, color: NVColors.textMuted, size: 16)
              else
                const Icon(Icons.verified_rounded, color: NVColors.doctorColor, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  IconData _modalityIcon(String modality) {
    return switch (modality) {
      'Brain MRI' => Icons.psychology_rounded,
      'Spine MRI' => Icons.accessible_rounded,
      'Chest X-Ray' => Icons.monitor_heart_rounded,
      'CT Scan' => Icons.image_search_rounded,
      _ => Icons.medical_information_rounded,
    };
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, Color> colorMap;

  const _FilterChips({required this.items, required this.selected, required this.onSelected, required this.colorMap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((s) {
        final color = colorMap[s] ?? NVColors.textMuted;
        final isSelected = selected == s;
        return GestureDetector(
            onTap: () => onSelected(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? color : NVColors.border),
              ),
              child: Text(
                s == 'all' ? 'All' : s.replaceAll('_', ' '),
                style: TextStyle(color: isSelected ? color : NVColors.textMuted, fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
              ),
            ),
          );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  final Color color;

  const _EmptyState({required this.icon, required this.message, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: NVColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
