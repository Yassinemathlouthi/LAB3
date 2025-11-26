import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import '../services/note_service.dart';
import 'edit_note_modal.dart';

class NoteItem extends StatefulWidget {
  final models.Document note;
  final Function(String)? onNoteDeleted;
  final Function(models.Document)? onNoteUpdated;

  const NoteItem({
    Key? key,
    required this.note,
    this.onNoteDeleted,
    this.onNoteUpdated,
  }) : super(key: key);

  @override
  _NoteItemState createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
  final NoteService _noteService = NoteService();
  bool _isDeleting = false;

  // Format the date for display
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  // Handle delete confirmation and execution
  Future<void> _handleDelete() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // If user confirmed deletion
    if (confirmed == true) {
      try {
        setState(() {
          _isDeleting = true;
        });

        // Call the deleteNote service function
        await _noteService.deleteNote(widget.note.$id);

        // Notify parent component if callback exists
        if (widget.onNoteDeleted != null) {
          widget.onNoteDeleted!(widget.note.$id);
        }
      } catch (e) {
        print('Error deleting note: $e');

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete note. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => EditNoteModal(
        note: widget.note,
        onNoteUpdated: (updatedNote) {
          if (widget.onNoteUpdated != null) {
            widget.onNoteUpdated!(updatedNote);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract note data
    final title = widget.note.data['title'] as String;
    final content = widget.note.data['content'] as String;
    final updatedAt = widget.note.$updatedAt;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Note content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${_formatDate(updatedAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _showEditDialog,
            ),

            // Delete button
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : _handleDelete,
            ),
          ],
        ),
      ),
    );
  }
}
