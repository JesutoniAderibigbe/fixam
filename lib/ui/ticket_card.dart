import 'package:flutter/material.dart';

import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final Ticket ticket;

  static const _urgencyColors = {
    'high': Color(0xFFEA4335),
    'medium': Color(0xFFF9AB00),
    'low': Color(0xFF34A853),
  };

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final urgencyColor = _urgencyColors[t.urgency] ?? Colors.grey;
    final reports = t.reportCount == 1 ? '1 report' : '${t.reportCount} reports';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(t.code,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Chip(label: Text(t.status), visualDensity: VisualDensity.compact),
              ],
            ),
            Text('${t.hall} Hall, Block ${t.block}, Room ${t.room}'),
            const SizedBox(height: 6),
            Text(t.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(t.category), visualDensity: VisualDensity.compact),
                Chip(
                  avatar: CircleAvatar(backgroundColor: urgencyColor, radius: 6),
                  label: Text('${t.urgency} urgency'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(label: Text(reports), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
