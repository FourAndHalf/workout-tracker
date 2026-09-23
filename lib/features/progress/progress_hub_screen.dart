import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text('Progress'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<_HubTab>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _HubTab.stats, label: Text('Stats')),
                ButtonSegment(value: _HubTab.history, label: Text('History')),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) =>
                  setState(() => _tab = selection.first),
            ),
          ),
        ),
      ),
      // IndexedStack keeps each tab's scroll position and loaded data.
      body: IndexedStack(
        index: _tab.index,
        children: const [
          ProgressScreen(embedded: true),
          HistoryScreen(embedded: true),
        ],
      ),
    );
  }
}
