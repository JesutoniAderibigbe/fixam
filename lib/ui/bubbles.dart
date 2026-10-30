import 'dart:typed_data';

import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.text, required this.mine, this.photo});

  final String text;
  final bool mine;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(photo!, height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
              ],
              Text(text, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
