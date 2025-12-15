import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/recent_file.dart';

/// Widget for displaying a list of recently opened files
class RecentFilesList extends StatelessWidget {
  final List<RecentFile> recentFiles;
  final Function(String) onFileSelected;
  final Function(String)? onFileRemoved;

  const RecentFilesList({
    super.key,
    required this.recentFiles,
    required this.onFileSelected,
    this.onFileRemoved,
  });

  String _formatDate(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recentFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'No recent files',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your recently opened PDFs will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: recentFiles.length,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      itemBuilder: (BuildContext context, int index) {
        final RecentFile file = recentFiles[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              Icons.picture_as_pdf,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            title: Text(
              file.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  file.path,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Opened ${_formatDate(file.lastOpened)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete button
                if (onFileRemoved != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove from recent files',
                    onPressed: () => onFileRemoved!(file.path),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            onTap: () => onFileSelected(file.path),
          ),
        );
      },
    );
  }
}
