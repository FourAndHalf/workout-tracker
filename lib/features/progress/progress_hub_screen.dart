import 'package:flutter/material.dart';

import '../../core/widgets/sliding_segmented_control.dart';
import '../history/history_screen.dart';
import 'progress_screen.dart';

enum _HubTab { stats, history }

/// Progress charts and workout history behind one bottom-nav tab.
class ProgressHubScreen extends StatefulWidget {
  const ProgressHubScreen({super.key});

  @override
  State<ProgressHubScreen> createState() => _ProgressHubScreenState();
}

class _ProgressHubScreenState extends State<ProgressHubScreen> {
  _HubTab _tab = _HubTab.stats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _tab.index.toDouble()),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                builder: (context, position, _) => SlidingSegmentedControl(
                  labels: const ['Stats', 'History'],
                  position: position,
                  onSelected: (i) => setState(() => _tab = _HubTab.values[i]),
                ),
              ),
            ),
          ),
          Expanded(
            // IndexedStack keeps each tab's scroll position and loaded data.
            child: IndexedStack(
              index: _tab.index,
              children: const [
                ProgressScreen(embedded: true),
                HistoryScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
