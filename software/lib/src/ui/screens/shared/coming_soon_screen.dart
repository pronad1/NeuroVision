// lib/src/ui/screens/shared/coming_soon_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/nv_sidebar.dart';
import '../../widgets/nv_top_bar.dart';
import '../../widgets/nv_glass_card.dart';

class ComingSoonScreen extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;
  final Color color;
  final String role;
  final String currentRoute;

  const ComingSoonScreen({
    super.key,
    required this.featureName,
    required this.description,
    required this.icon,
    required this.color,
    required this.role,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<NVAuthProvider>(context);
    final user = auth.nvUser;

    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Row(
        children: [
          NVSidebar(currentRoute: currentRoute, role: role),
          Expanded(
            child: Column(
              children: [
                NVTopBar(
                  title: featureName,
                  subtitle: description,
                  user: user?.name ?? '',
                  roleColor: color,
                ),
                Expanded(
                  child: Center(
                    child: NVGlassCard(
                      width: 480,
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated icon container
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
                              ),
                              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                            ),
                            child: Icon(icon, color: color, size: 48),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            featureName,
                            style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: NVColors.textSecondary, fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: NVColors.warning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: NVColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: NVColors.warning, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                const Text('Under Active Development', style: TextStyle(color: NVColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Planned features list
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: NVColors.bgDeep,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NVColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Planned Features', style: TextStyle(color: NVColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                ..._getPlannedFeatures(featureName).map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded, color: color, size: 14),
                                      const SizedBox(width: 8),
                                      Text(f, style: const TextStyle(color: NVColors.textMuted, fontSize: 12)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Back to Dashboard'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: color,
                              side: BorderSide(color: color),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getPlannedFeatures(String name) {
    final map = {
      'AI Diagnosis': ['AI prediction review', 'Confidence score analysis', 'Severity classification'],
      'Segmentation': ['Lesion segmentation masks', 'Volume measurement', 'Region-of-interest tools'],
      'Heatmaps': ['Grad-CAM visualization', 'Activation map overlay', 'Lesion attention heatmaps'],
      'Comparative': ['Multi-scan comparison', 'Timeline progression', 'Delta analysis'],
      'Clinical Notes': ['Structured note templates', 'Voice-to-text input', 'Report generation'],
      'DICOM Viewer': ['DICOM format rendering', 'Window/level adjustment', 'Multi-slice navigation'],
      'Annotations': ['Bounding box tools', 'Polygon annotation', 'Measurement tools'],
      'Lesion Localization': ['Spatial lesion mapping', 'AI vs manual comparison', 'Region highlighting'],
      'Explainability': ['Grad-CAM overlays', 'Attention weights', 'Feature attribution maps'],
      'Model Monitor': ['Real-time accuracy tracking', 'Loss curve monitoring', 'Alert thresholds'],
      'Metrics': ['Precision/Recall/F1', 'ROC-AUC curves', 'Per-class metrics'],
      'Confusion Matrix': ['Interactive matrix', 'Per-class analysis', 'Error pattern detection'],
      'Experiments': ['Hyperparameter tracking', 'Version comparison', 'Best model selection'],
      'Datasets': ['Dataset statistics', 'Class distribution', 'Split management'],
      'GPU Monitor': ['GPU utilization live', 'Memory usage tracking', 'Training job queue'],
    };
    return map[name] ?? ['Advanced analysis tools', 'Real-time processing', 'Export capabilities'];
  }
}
