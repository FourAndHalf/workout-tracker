import 'package:flutter/material.dart';

class SessionDetailScreen extends StatelessWidget {
  final int sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Session #$sessionId')),
      body: Center(
        child: Text('Session Detail for ID: $sessionId'),
      ),
    );
  }
}
