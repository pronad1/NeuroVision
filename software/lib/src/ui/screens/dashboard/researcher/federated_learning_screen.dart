// lib/src/ui/screens/dashboard/researcher/federated_learning_screen.dart
//
// Feature: Federated Learning Network Dashboard
// Academic concept: Privacy-Preserving AI — hospitals train locally, only model
// weight updates are shared, never raw patient data. Addresses HIPAA compliance.
//
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../widgets/nv_sidebar.dart';
import '../../../widgets/nv_glass_card.dart';
import '../../../widgets/nv_top_bar.dart';
import '../../../widgets/nv_stat_card.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class _HospitalNode {
  final String id;
  final String name;
  final String location;
  final int localSamples;
  double localAccuracy;
  String status;
  Color statusColor;
  bool privacyEnabled;

  _HospitalNode({
    required this.id,
    required this.name,
    required this.location,
    required this.localSamples,
    required this.localAccuracy,
    required this.status,
    required this.statusColor,
    this.privacyEnabled = true,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class FederatedLearningScreen extends StatefulWidget {
  const FederatedLearningScreen({super.key});

  @override
  State<FederatedLearningScreen> createState() => _FederatedLearningScreenState();
}

class _FederatedLearningScreenState extends State<FederatedLearningScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  int _currentRound = 7;
  double _globalAccuracy = 91.4;
  bool _isTraining = false;

  final _rng = Random();

  final List<_HospitalNode> _nodes = [
    _HospitalNode(id: 'HOSP-01', name: 'Dhaka Medical College', location: 'Bangladesh', localSamples: 8420, localAccuracy: 92.1, status: 'Synchronized', statusColor: NVColors.success),
    _HospitalNode(id: 'HOSP-02', name: 'Chittagong General', location: 'Bangladesh', localSamples: 5310, localAccuracy: 89.7, status: 'Synchronized', statusColor: NVColors.success),
    _HospitalNode(id: 'HOSP-03', name: 'Apollo Hospitals', location: 'India', localSamples: 11240, localAccuracy: 94.3, status: 'Training', statusColor: NVColors.researcherColor),
    _HospitalNode(id: 'HOSP-04', name: 'AIIMS New Delhi', location: 'India', localSamples: 9870, localAccuracy: 93.8, status: 'Synchronized', statusColor: NVColors.success),
    _HospitalNode(id: 'HOSP-05', name: 'NUH Singapore', location: 'Singapore', localSamples: 7650, localAccuracy: 95.2, status: 'Aggregating', statusColor: NVColors.warning),
    _HospitalNode(id: 'HOSP-06', name: 'KFSH Riyadh', location: 'Saudi Arabia', localSamples: 6320, localAccuracy: 90.4, status: 'Idle', statusColor: NVColors.textMuted),
  ];

  // Convergence data across rounds
  final _convergenceData = <FlSpot>[
    const FlSpot(1, 74.2), const FlSpot(2, 79.8), const FlSpot(3, 83.5),
    const FlSpot(4, 86.9), const FlSpot(5, 88.7), const FlSpot(6, 90.1),
    const FlSpot(7, 91.4),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startFederatedRound() async {
    setState(() {
      _isTraining = true;
      for (final n in _nodes) {
        if (n.status != 'Idle') {
          n.status = 'Training';
          n.statusColor = NVColors.researcherColor;
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      for (final n in _nodes) {
        if (n.status == 'Training') {
          n.status = 'Aggregating';
          n.statusColor = NVColors.warning;
          n.localAccuracy += 0.3 + _rng.nextDouble() * 0.8;
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 900));
    final newAccuracy = _globalAccuracy + 0.8 + _rng.nextDouble() * 0.6;
    setState(() {
      _currentRound++;
      _globalAccuracy = double.parse(newAccuracy.toStringAsFixed(1));
      _convergenceData.add(FlSpot(_currentRound.toDouble(), _globalAccuracy));
      for (final n in _nodes) {
        if (n.status == 'Aggregating') {
          n.status = 'Synchronized';
          n.statusColor = NVColors.success;
        }
      }
      _isTraining = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NVScaffold(
      currentRoute: '/dashboard/researcher/federated',
      role: AppConstants.roleResearcher,
      title: 'Federated Learning',
      subtitle: 'Privacy-Preserving Collaborative AI Training',
      userName: 'Researcher',
      roleColor: NVColors.researcherColor,
      fadeAnimation: _fadeAnim,
      body: Column(
        children: [
          NVTopBar(
            title: 'Federated Learning Network',
            subtitle: 'Privacy-Preserving AI — HIPAA Compliant Collaborative Training',
            user: 'Researcher',
            roleColor: NVColors.researcherColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConceptBanner(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildMainContent(),
                  const SizedBox(height: 20),
                  _buildNodesGrid(),
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
          NVColors.researcherColor.withValues(alpha: 0.10),
          NVColors.secondary.withValues(alpha: 0.06),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NVColors.researcherColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [NVColors.researcherColor, Color(0xFF065F46)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Federated Learning — Privacy-First AI',
                    style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 3),
                Text(
                  'Multiple hospitals train the AI model locally on their patient data. '
                  'Only encrypted model weight updates are shared — never raw patient data. HIPAA/GDPR compliant.',
                  style: TextStyle(color: NVColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NVColors.researcherColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NVColors.researcherColor.withValues(alpha: 0.3)),
            ),
            child: const Text('FEDERATED AI',
                style: TextStyle(color: NVColors.researcherColor, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final count = w > 800 ? 4 : (w > 400 ? 2 : 1);
      final itemWidth = w / count;
      final ratio = w > 400 ? 1.8 : (itemWidth / 160.0);
      return GridView.count(
        crossAxisCount: count,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          NVStatCard(
            label: 'Federated Round',
            value: '$_currentRound',
            icon: Icons.loop_rounded,
            color: NVColors.researcherColor,
            subtitle: _isTraining ? 'Training in progress...' : 'Round complete',
          ),
          NVStatCard(
            label: 'Global Model Accuracy',
            value: '$_globalAccuracy%',
            icon: Icons.emoji_events_rounded,
            color: NVColors.warning,
            trend: '+${(_globalAccuracy - 74.2).toStringAsFixed(1)}%',
            trendPositive: true,
            subtitle: 'vs. Round 1',
          ),
          NVStatCard(
            label: 'Active Hospitals',
            value: '${_nodes.where((n) => n.status != 'Idle').length}',
            icon: Icons.local_hospital_rounded,
            color: NVColors.doctorColor,
            subtitle: '${_nodes.length} total nodes',
          ),
          NVStatCard(
            label: 'Total Training Samples',
            value: '${(_nodes.fold<int>(0, (s, n) => s + n.localSamples) / 1000).toStringAsFixed(0)}K',
            icon: Icons.storage_rounded,
            color: NVColors.secondary,
            subtitle: 'Across all institutions',
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
            Expanded(flex: 3, child: _buildNetworkTopology()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildConvergenceChart()),
          ],
        );
      }
      return Column(children: [_buildNetworkTopology(), const SizedBox(height: 16), _buildConvergenceChart()]);
    });
  }

  Widget _buildNetworkTopology() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: NVColors.researcherColor, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('Network Topology', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
              ElevatedButton.icon(
                onPressed: _isTraining ? null : _startFederatedRound,
                icon: _isTraining
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(_isTraining ? 'Training...' : 'Start Round ${_currentRound + 1}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NVColors.researcherColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 0),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: CustomPaint(
              painter: _FederatedTopologyPainter(
                nodeCount: _nodes.length,
                nodeColors: _nodes.map((n) => n.statusColor).toList(),
                nodeStatuses: _nodes.map((n) => n.status).toList(),
                isTraining: _isTraining,
                pulseValue: _pulseAnim.value,
              ),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) => const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _NetLegend(color: NVColors.success, label: 'Synchronized'),
              _NetLegend(color: NVColors.researcherColor, label: 'Training'),
              _NetLegend(color: NVColors.warning, label: 'Aggregating'),
              _NetLegend(color: NVColors.textMuted, label: 'Idle'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConvergenceChart() {
    return NVGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.trending_up_rounded, color: NVColors.researcherColor, size: 16),
            SizedBox(width: 8),
            Text('Global Model Convergence', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          const Text('Accuracy improvement across federated rounds',
              style: TextStyle(color: NVColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: NVColors.border, strokeWidth: 0.5),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                      style: const TextStyle(color: NVColors.textMuted, fontSize: 9)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text('R${v.toInt()}',
                      style: const TextStyle(color: NVColors.textMuted, fontSize: 9)),
                )),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 65,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: _convergenceData,
                  isCurved: true,
                  color: NVColors.researcherColor,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: NVColors.researcherColor,
                      strokeWidth: 2,
                      strokeColor: NVColors.bgDeep,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [NVColors.researcherColor.withValues(alpha: 0.15), Colors.transparent],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            )),
          ),
          const SizedBox(height: 16),
          // Privacy badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NVColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NVColors.success.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: NVColors.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DP-SGD Privacy Guarantee: ε = 2.0, δ = 1e-5\nNo raw patient data leaves any hospital node.',
                    style: TextStyle(color: NVColors.success, fontSize: 10, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.local_hospital_rounded, color: NVColors.researcherColor, size: 16),
          SizedBox(width: 8),
          Text('Hospital Node Status', style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final count = w > 900 ? 3 : (w > 500 ? 2 : 1);
          final itemWidth = w / count;
          final ratio = w > 300 ? 2.1 : (itemWidth / 120.0);
          return GridView.count(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ratio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _nodes.map((n) => _HospitalNodeCard(node: n)).toList(),
          );
        }),
      ],
    );
  }
}

// ─── Custom painter for topology ─────────────────────────────────────────────

class _FederatedTopologyPainter extends CustomPainter {
  final int nodeCount;
  final List<Color> nodeColors;
  final List<String> nodeStatuses;
  final bool isTraining;
  final double pulseValue;

  _FederatedTopologyPainter({
    required this.nodeCount,
    required this.nodeColors,
    required this.nodeStatuses,
    required this.isTraining,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.36;

    // Draw central aggregation server
    final serverPaint = Paint()
      ..color = NVColors.researcherColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final serverBorderPaint = Paint()
      ..color = NVColors.researcherColor.withValues(alpha: isTraining ? 0.5 * pulseValue : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 32, serverPaint);
    canvas.drawCircle(center, 32 + (isTraining ? 6 * pulseValue : 0), serverBorderPaint);

    // Draw lines from center to each node
    for (int i = 0; i < nodeCount; i++) {
      final angle = (2 * pi * i / nodeCount) - pi / 2;
      final nodePos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final linePaint = Paint()
        ..color = nodeColors[i].withValues(alpha: isTraining ? 0.5 * pulseValue : 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      if (isTraining && nodeStatuses[i] == 'Training') {
        linePaint
          ..color = NVColors.researcherColor.withValues(alpha: 0.7 * pulseValue)
          ..strokeWidth = 2;
      }
      canvas.drawLine(center, nodePos, linePaint);

      // Node circle
      final nodeFill = Paint()
        ..color = nodeColors[i].withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final nodeBorder = Paint()
        ..color = nodeColors[i].withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(nodePos, 22, nodeFill);
      canvas.drawCircle(nodePos, 22, nodeBorder);

      // Hospital icon (cross)
      final crossPaint = Paint()
        ..color = nodeColors[i]
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(nodePos + const Offset(-6, 0), nodePos + const Offset(6, 0), crossPaint);
      canvas.drawLine(nodePos + const Offset(0, -6), nodePos + const Offset(0, 6), crossPaint);
    }

    // Central server icon
    final iconPaint = Paint()
      ..color = NVColors.researcherColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 18, height: 14),
      iconPaint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(center + const Offset(-6, 3), center + const Offset(6, 3), iconPaint);
  }

  @override
  bool shouldRepaint(covariant _FederatedTopologyPainter old) =>
      old.isTraining != isTraining || old.pulseValue != pulseValue ||
      old.nodeStatuses.toString() != nodeStatuses.toString();
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _HospitalNodeCard extends StatelessWidget {
  final _HospitalNode node;
  const _HospitalNodeCard({required this.node});

  @override
  Widget build(BuildContext context) {
    return NVGlassCard(
      padding: const EdgeInsets.all(14),
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: node.statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(node.id,
                    style: const TextStyle(color: NVColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: node.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: node.statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(node.status, style: TextStyle(color: node.statusColor, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(node.name,
              style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis),
          Text(node.location, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${node.localAccuracy.toStringAsFixed(1)}%',
                      style: TextStyle(color: node.statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Local Acc', style: TextStyle(color: NVColors.textMuted, fontSize: 9)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(node.localSamples / 1000).toStringAsFixed(1)}K',
                      style: const TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const Text('Samples', style: TextStyle(color: NVColors.textMuted, fontSize: 9)),
                ],
              ),
              if (node.privacyEnabled)
                const Tooltip(
                  message: 'DP-SGD Privacy Enabled',
                  child: Icon(Icons.shield_rounded, color: NVColors.success, size: 14),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _NetLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
    ]);
  }
}
