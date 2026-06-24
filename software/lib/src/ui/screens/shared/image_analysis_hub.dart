// lib/src/ui/screens/shared/image_analysis_hub.dart
// Medical Image Upload & AI Analysis Hub — 4-step flow

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/analysis_provider.dart';
import '../../widgets/nv_sidebar.dart';
import '../../widgets/nv_glass_card.dart';
import '../../../config/constants.dart';
import '../../../services/medical_service.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

String _roleFromUser(String? role) {
  switch (role) {
    case 'radiologist':
      return AppConstants.roleRadiologist;
    case 'researcher':
      return AppConstants.roleResearcher;
    default:
      return AppConstants.roleDoctor;
  }
}

Color _roleColor(String? role) {
  switch (role) {
    case 'radiologist':
      return NVColors.radiologistColor;
    case 'researcher':
      return NVColors.researcherColor;
    default:
      return NVColors.doctorColor;
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ImageAnalysisHub extends StatefulWidget {
  const ImageAnalysisHub({super.key});

  @override
  State<ImageAnalysisHub> createState() => _ImageAnalysisHubState();
}

class _ImageAnalysisHubState extends State<ImageAnalysisHub>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<NVAuthProvider>(context).nvUser;
    final role = user?.role;

    return NVScaffold(
      currentRoute: '/analysis',
      role: _roleFromUser(role),
      title: 'AI Analysis',
      subtitle: 'Upload a medical image and run AI inference',
      userName: user?.name ?? 'User',
      roleColor: _roleColor(role),
      fadeAnimation: _fade,
      body: Column(
        children: [
          // Top bar replacement (web only, NVScaffold adds it on mobile)
          _HubTopBar(role: role),
          Expanded(
            child: Consumer<AnalysisProvider>(
              builder: (context, provider, _) {
                return _buildStepContent(context, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, AnalysisProvider provider) {
    final isMobile = isMobileLayout(context);

    Widget content;
    switch (provider.step) {
      case AnalysisStep.selectModality:
        content = _ModalitySelectionStep(key: const ValueKey('modality'));
      case AnalysisStep.selectModel:
        content = _ModelSelectionStep(key: const ValueKey('model'));
      case AnalysisStep.uploadImage:
        content = _UploadStep(key: const ValueKey('upload'));
      case AnalysisStep.running:
        content = const _RunningStep(key: ValueKey('running'));
      case AnalysisStep.results:
        content = _ResultsStep(key: const ValueKey('results'));
      case AnalysisStep.error:
        content = _ErrorStep(key: const ValueKey('error'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepProgressBar(currentStep: provider.step),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _HubTopBar extends StatelessWidget {
  final String? role;
  const _HubTopBar({required this.role});

  @override
  Widget build(BuildContext context) {
    if (isMobileLayout(context)) return const SizedBox.shrink();
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: NVColors.bgCard,
        border: Border(bottom: BorderSide(color: NVColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.biotech_rounded, color: NVColors.primary, size: 20),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medical Image Analysis',
                  style: TextStyle(
                      color: NVColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text('Upload · Analyze · Interpret',
                  style: TextStyle(
                      color: NVColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 11)),
            ],
          ),
          const Spacer(),
          Consumer<AnalysisProvider>(
            builder: (context, provider, _) {
              if (provider.step == AnalysisStep.selectModality) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () => provider.goBack(),
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                label: const Text('Back', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: NVColors.textSecondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step Progress Bar ────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final AnalysisStep currentStep;
  const _StepProgressBar({required this.currentStep});

  int get _stepIndex => switch (currentStep) {
        AnalysisStep.selectModality => 0,
        AnalysisStep.selectModel => 0,
        AnalysisStep.uploadImage => 1,
        AnalysisStep.running || AnalysisStep.results || AnalysisStep.error => 2,
      };

  @override
  Widget build(BuildContext context) {
    const steps = ['Modality', 'Upload', 'Results'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          final isActive = lineIndex < _stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [NVColors.primary, NVColors.accent])
                    : null,
                color: isActive ? null : NVColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = stepIndex <= _stepIndex;
        final isDone = stepIndex < _stepIndex;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                        colors: [NVColors.primary, NVColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : NVColors.border.withValues(alpha: 0.3),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: NVColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : NVColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                color: isActive ? NVColors.textPrimary : NVColors.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Step 1: Modality Selection ───────────────────────────────────────────────

class _ModalitySelectionStep extends StatelessWidget {
  const _ModalitySelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context, listen: false);
    final isMobile = isMobileLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Imaging Modality',
          style: TextStyle(
            color: NVColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select the type of medical image you want to analyze with AI',
          style: TextStyle(color: NVColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, constraints) {
          final crossCount = isMobile ? 2 : 4;
          final itemWidth =
              (constraints.maxWidth - (crossCount - 1) * 12) / crossCount;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: MedicalModality.values
                .map((m) => SizedBox(
                      width: itemWidth,
                      child: _ModalityCard(
                        modality: m,
                        onTap: m.isAvailable
                            ? () => provider.selectModality(m)
                            : null,
                      ),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }
}

class _ModalityCard extends StatefulWidget {
  final MedicalModality modality;
  final VoidCallback? onTap;
  const _ModalityCard({required this.modality, this.onTap});

  @override
  State<_ModalityCard> createState() => _ModalityCardState();
}

class _ModalityCardState extends State<_ModalityCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.modality;
    final isAvailable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isAvailable
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _hovered
                        ? [
                            m.color.withValues(alpha: 0.25),
                            m.color.withValues(alpha: 0.08),
                          ]
                        : [
                            m.color.withValues(alpha: 0.12),
                            const Color(0xFF0d0d1a),
                          ],
                  )
                : null,
            color: isAvailable ? null : NVColors.bgDeep,
            border: Border.all(
              color: _hovered && isAvailable
                  ? m.color
                  : isAvailable
                      ? m.color.withValues(alpha: 0.35)
                      : NVColors.border.withValues(alpha: 0.4),
              width: _hovered && isAvailable ? 1.5 : 1,
            ),
            boxShadow: _hovered && isAvailable
                ? [
                    BoxShadow(
                      color: m.color.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAvailable
                            ? [
                                m.color.withValues(alpha: 0.3),
                                m.color.withValues(alpha: 0.1),
                              ]
                            : [
                                NVColors.border.withValues(alpha: 0.2),
                                NVColors.border.withValues(alpha: 0.1),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      m.icon,
                      color: isAvailable ? m.color : NVColors.textMuted,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (!isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NVColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: NVColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          color: NVColors.warning,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NVColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: NVColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Ready',
                        style: TextStyle(
                          color: NVColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                m.displayName,
                style: TextStyle(
                  color: isAvailable ? NVColors.textPrimary : NVColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAvailable
                    ? '${m.availableModels.length} models available'
                    : m.unavailableReason,
                style: TextStyle(
                  color: isAvailable
                      ? m.color.withValues(alpha: 0.8)
                      : NVColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isAvailable) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Select →',
                      style: TextStyle(
                        color: _hovered ? m.color : NVColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 2: Model Selection ──────────────────────────────────────────────────

class _ModelSelectionStep extends StatelessWidget {
  const _ModelSelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final modality = provider.selectedModality!;
    final isMobile = isMobileLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [modality.color, modality.color.withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(modality.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modality.displayName,
                  style: const TextStyle(
                    color: NVColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'Select an AI model',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...modality.availableModels.map((m) => _ModelCard(
              model: m,
              isSelected: provider.selectedModel?.id == m.id,
              accentColor: modality.color,
              onTap: () => provider.selectModel(m),
              isMobile: isMobile,
            )),
      ],
    );
  }
}

class _ModelCard extends StatefulWidget {
  final ModelOption model;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isMobile;
  const _ModelCard({
    required this.model,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.isMobile,
  });

  @override
  State<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<_ModelCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final isSelected = widget.isSelected;
    final c = widget.accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isSelected
                ? LinearGradient(
                    colors: [c.withValues(alpha: 0.2), c.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : NVColors.bgCard,
            border: Border.all(
              color: isSelected
                  ? c
                  : _hovered
                      ? c.withValues(alpha: 0.4)
                      : NVColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: c.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? c : NVColors.border,
                    width: 2,
                  ),
                  color: isSelected ? c : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            color: isSelected ? NVColors.textPrimary : NVColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (m.isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [NVColors.primary, NVColors.accent]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.description,
                      style: const TextStyle(
                          color: NVColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.withValues(alpha: 0.3)),
                ),
                child: Text(
                  m.metric,
                  style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 3: Upload Image ─────────────────────────────────────────────────────

class _UploadStep extends StatefulWidget {
  const _UploadStep({super.key});

  @override
  State<_UploadStep> createState() => _UploadStepState();
}

class _UploadStepState extends State<_UploadStep> {
  bool _dragHovered = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final modality = provider.selectedModality!;
    final hasImage = provider.imageBytes != null;
    final isMobile = isMobileLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [modality.color, modality.color.withValues(alpha: 0.5)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(modality.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload ${modality.displayName}',
                    style: const TextStyle(
                      color: NVColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Model: Ensemble (all available models)',
                    style: TextStyle(
                        color: modality.color.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Upload zone
        if (!hasImage)
          GestureDetector(
            onTap: () => provider.pickImage(),
            child: MouseRegion(
              onEnter: (_) => setState(() => _dragHovered = true),
              onExit: (_) => setState(() => _dragHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: isMobile ? 200 : 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: _dragHovered
                      ? LinearGradient(
                          colors: [
                            modality.color.withValues(alpha: 0.12),
                            modality.color.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _dragHovered ? null : NVColors.bgDeep,
                  border: Border.all(
                    color: _dragHovered
                        ? modality.color
                        : NVColors.border.withValues(alpha: 0.5),
                    width: _dragHovered ? 2 : 1.5,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            modality.color.withValues(alpha: 0.2),
                            modality.color.withValues(alpha: 0.06),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        color: modality.color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isMobile ? 'Tap to select image' : 'Click or drag & drop image here',
                      style: const TextStyle(
                        color: NVColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PNG, JPEG or DICOM format supported',
                      style: TextStyle(color: NVColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          _ImagePreview(
            imageBytes: provider.imageBytes!,
            fileName: provider.imageFileName ?? 'image',
            accentColor: modality.color,
            onRemove: () => provider.clearImageOnly(),
            onReplace: () => provider.pickImage(),
          ),

        const SizedBox(height: 20),

        // Run Analysis button
        if (hasImage)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => provider.runAnalysis(),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Run AI Analysis',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: modality.color,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: modality.color.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (!hasImage)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => provider.pickImage(),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Browse Files'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: modality.color,
                side: BorderSide(color: modality.color.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List imageBytes;
  final String fileName;
  final Color accentColor;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _ImagePreview({
    required this.imageBytes,
    required this.fileName,
    required this.accentColor,
    required this.onRemove,
    required this.onReplace,
  });

  String get _fileSize {
    final kb = imageBytes.length / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: NVColors.success, size: 16),
              const SizedBox(width: 8),
              const Text('Image Ready',
                  style: TextStyle(
                      color: NVColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: onReplace,
                style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4)),
                child: const Text('Replace', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded,
                    color: NVColors.textMuted, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  imageBytes,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: NVColors.bgDeep,
                    child: const Icon(Icons.broken_image_rounded,
                        color: NVColors.textMuted, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                          color: NVColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fileSize,
                      style: const TextStyle(
                          color: NVColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NVColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: NVColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '✓ Ready for analysis',
                        style: TextStyle(
                            color: NVColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step: Running ────────────────────────────────────────────────────────────

class _RunningStep extends StatelessWidget {
  const _RunningStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final modality = provider.selectedModality!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(modality.color),
                  ),
                  Icon(modality.icon, color: modality.color, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Running AI Analysis...',
              style: TextStyle(
                color: NVColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Processing with Ensemble model (all available models) — this may take 10–30 seconds',
              style: TextStyle(color: NVColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: modality.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: modality.color.withValues(alpha: 0.2)),
              ),
              child: Text(
                '⚡ Ensure the FastAPI server is running on localhost:8000',
                style: TextStyle(
                    color: modality.color.withValues(alpha: 0.9), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step: Error ──────────────────────────────────────────────────────────────

class _ErrorStep extends StatelessWidget {
  const _ErrorStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: NVColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: NVColors.error.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: NVColors.error, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Analysis Failed',
              style: TextStyle(
                color: NVColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NVColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NVColors.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                provider.errorMessage ?? 'An unknown error occurred.',
                style: const TextStyle(
                    color: NVColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => provider.goBack(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NVColors.textSecondary,
                    side: const BorderSide(color: NVColors.border),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => provider.resetAll(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Start Over'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step: Results ────────────────────────────────────────────────────────────

class _ResultsStep extends StatelessWidget {
  const _ResultsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);
    final result = provider.result!;
    final modality = provider.selectedModality!;
    final isMobile = isMobileLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success header
        _ResultHeader(result: result, modality: modality),
        const SizedBox(height: 20),

        // Main content
        isMobile
            ? Column(children: [
                _ResultImagePanel(result: result, modality: modality),
                const SizedBox(height: 16),
                _ResultStatsPanel(result: result, modality: modality),
              ])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 3,
                      child:
                          _ResultImagePanel(result: result, modality: modality)),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 2,
                      child: _ResultStatsPanel(
                          result: result, modality: modality)),
                ],
              ),

        const SizedBox(height: 20),

        // Action buttons
        _ResultActions(modality: modality, provider: provider),

        const SizedBox(height: 12),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NVColors.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NVColors.warning.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: NVColors.warning, size: 16),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'For research and educational purposes only. Clinical validation by a qualified professional is required before any diagnostic or treatment decision.',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final dynamic result;
  final MedicalModality modality;
  const _ResultHeader({required this.result, required this.modality});

  @override
  Widget build(BuildContext context) {
    return NVGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [modality.color, modality.color.withValues(alpha: 0.5)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(modality.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis Complete',
                  style: TextStyle(
                    color: NVColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  result.prediction,
                  style: const TextStyle(
                    color: NVColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  result.message,
                  style: const TextStyle(
                      color: NVColors.textMuted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.confidence.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: modality.color,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Confidence',
                style: TextStyle(color: NVColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultImagePanel extends StatelessWidget {
  final dynamic result;
  final MedicalModality modality;
  const _ResultImagePanel({required this.result, required this.modality});

  @override
  Widget build(BuildContext context) {
    final heatmapB64 = result.heatmapBase64 as String?;
    final maskB64 = result.segmentationMaskBase64 as String?;

    return NVGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.image_rounded, color: modality.color, size: 14),
            const SizedBox(width: 6),
            const Text('Analysis Output',
                style: TextStyle(
                    color: NVColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          if (heatmapB64 != null || maskB64 != null)
            _Base64ImageView(
              b64: heatmapB64 ?? maskB64!,
              label: heatmapB64 != null
                  ? 'Segmentation Mask / Heatmap'
                  : 'Segmentation Mask',
              accentColor: modality.color,
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NVColors.bgDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(modality.icon, color: modality.color.withValues(alpha: 0.3), size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'No visual output for this modality',
                    style: TextStyle(color: NVColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Base64ImageView extends StatelessWidget {
  final String b64;
  final String label;
  final Color accentColor;
  const _Base64ImageView(
      {required this.b64, required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(b64);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: NVColors.bgDeep,
                child: const Center(
                  child: Text('Failed to render image',
                      style: TextStyle(color: NVColors.textMuted)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style:
                TextStyle(color: accentColor.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      );
    } catch (_) {
      return const Text('Invalid image data',
          style: TextStyle(color: NVColors.error, fontSize: 12));
    }
  }
}

class _ResultStatsPanel extends StatelessWidget {
  final dynamic result;
  final MedicalModality modality;
  const _ResultStatsPanel({required this.result, required this.modality});

  @override
  Widget build(BuildContext context) {
    final probs = result.allProbabilities as Map<String, double>;

    return Column(
      children: [
        NVGlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.analytics_rounded, color: modality.color, size: 14),
                const SizedBox(width: 6),
                const Text('Prediction Summary',
                    style: TextStyle(
                        color: NVColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 14),
              _StatRow('Prediction', result.prediction, modality.color),
              _StatRow('Confidence',
                  '${result.confidence.toStringAsFixed(1)}%', modality.color),
              _StatRow('Severity', result.severity,
                  _severityColor(result.severity as String)),
              _StatRow('Model Used', result.modelUsed, NVColors.textSecondary),
              _StatRow('Modality', result.modality, NVColors.textSecondary),
              if (result.lesionCoveragePct != null && result.lesionCoveragePct > 0)
                _StatRow(
                  'Lesion Coverage',
                  '${(result.lesionCoveragePct as double).toStringAsFixed(2)}%',
                  NVColors.warning,
                ),
            ],
          ),
        ),
        if (probs.isNotEmpty) ...[
          const SizedBox(height: 12),
          NVGlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.bar_chart_rounded, color: modality.color, size: 14),
                  const SizedBox(width: 6),
                  const Text('Probabilities',
                      style: TextStyle(
                          color: NVColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 14),
                ...probs.entries.map((e) => _ProbabilityBar(
                      label: e.key,
                      value: e.value,
                      accentColor: modality.color,
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _severityColor(String severity) => switch (severity) {
        'High' || 'Critical' => NVColors.error,
        'Medium' => NVColors.warning,
        'None' => NVColors.success,
        _ => NVColors.accent,
      };
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: NVColors.textMuted, fontSize: 12)),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  final String label;
  final double value;
  final Color accentColor;
  const _ProbabilityBar(
      {required this.label, required this.value, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: NVColors.textSecondary, fontSize: 12)),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              backgroundColor: NVColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  final MedicalModality modality;
  final AnalysisProvider provider;
  const _ResultActions({required this.modality, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: () => provider.resetAll(),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('New Analysis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: modality.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            // Navigate to detailed screens based on modality
            switch (modality) {
              case MedicalModality.brain:
                Navigator.pushNamed(
                    context, '/dashboard/radiologist/lesions');
              case MedicalModality.spine:
                Navigator.pushNamed(
                    context, '/dashboard/radiologist/segmentation');
              case MedicalModality.chest:
                Navigator.pushNamed(
                    context, '/dashboard/radiologist/segmentation');
              case MedicalModality.heart:
                Navigator.pushNamed(
                    context, '/dashboard/radiologist/explainability');
            }
          },
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Detailed View'),
          style: OutlinedButton.styleFrom(
            foregroundColor: modality.color,
            side: BorderSide(color: modality.color.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(
                context, '/dashboard/radiologist/explainability');
          },
          icon: const Icon(Icons.visibility_rounded, size: 16),
          label: const Text('Explainability'),
          style: OutlinedButton.styleFrom(
            foregroundColor: NVColors.accent,
            side: BorderSide(color: NVColors.accent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final userId = Provider.of<NVAuthProvider>(context, listen: false).nvUser?.uid ?? 'unknown';
            final result = provider.result;
            if (result == null) return;
            
            final medService = MedicalService();
            final caseId = await medService.createCase(
              modality: modality.apiModality,
              uploadedBy: userId,
              aiPrediction: result.prediction,
              aiConfidence: result.confidence,
              aiSeverity: result.severity,
              aiModelUsed: result.modelUsed,
              heatmapUrl: result.heatmapBase64,
              segmentationMaskUrl: result.segmentationMaskBase64,
            );
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(caseId != null ? 'Saved to Medical Cases ($caseId)' : 'Failed to save case'),
                backgroundColor: caseId != null ? NVColors.success : NVColors.error,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
          icon: const Icon(Icons.save_rounded, size: 16),
          label: const Text('Save as Case'),
          style: ElevatedButton.styleFrom(
            backgroundColor: NVColors.success,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

