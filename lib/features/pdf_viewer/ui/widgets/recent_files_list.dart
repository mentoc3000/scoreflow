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
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No recent files',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open a PDF file to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: recentFiles.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (BuildContext context, int index) {
        final RecentFile file = recentFiles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
              size: 32,
            ),
            title: Text(
              file.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  file.path,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Opened ${_formatDate(file.lastOpened)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete button
                if (onFileRemoved != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Remove from recent files',
                    onPressed: () => onFileRemoved!(file.path),
                    color: Colors.grey[600],
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => onFileSelected(file.path),
          ),
        );
      },
    );
  }
}
