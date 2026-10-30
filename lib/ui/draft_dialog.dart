import 'package:flutter/material.dart';

import '../models/ticket.dart';

/// The ticket the agent wants to file, shown before anything is written.
class DraftDialog extends StatelessWidget {
  const DraftDialog({super.key, required this.draft});

  final TicketDraft draft;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File this ticket?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row('Where', '${draft.hall} Hall, Block ${draft.block}, Room ${draft.room}'),
          _Row('Problem', draft.category),
          _Row('Urgency', draft.urgency),
          const SizedBox(height: 8),
          Text(draft.description),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Change something'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('File ticket'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
