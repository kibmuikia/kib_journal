import 'package:flutter/material.dart';
import 'package:kib_journal/data/models/journal_entry.dart';
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';

class JournalEntryCard extends StatelessWidgetK {
  final JournalEntry entry;

  JournalEntryCard({super.key, required super.tag, required this.entry});

  @override
  Widget buildWithTheme(BuildContext context) {
    // final dateFormatter = DateFormat('MMM dd, yyyy • h:mm a');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              // dateFormatter.format(entry.createdAt),
              '${entry.createdAt.hour}:${entry.createdAt.minute}  ${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              entry.content,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
