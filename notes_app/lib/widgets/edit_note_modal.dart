import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import '../services/note_service.dart';

class EditNoteModal extends StatefulWidget {
  final models.Document note;
  final Function(models.Document) onNoteUpdated;

  const EditNoteModal({
    Key? key,
    required this.note,
    required this.onNoteUpdated,
  }) : super(key: key);

  @override
  _EditNoteModalState createState() => _EditNoteModalState();
}

class _EditNoteModalState extends State<EditNoteModal> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _noteService = NoteService();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with note data
    _titleController = TextEditingController(text: widget.note.data['title']);
    _contentController = TextEditingController(
      text: widget.note.data['content'],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Reset form error state
  void _resetForm() {
    setState(() {
      _error = null;
    });
  }

  // Save the updated note
  Future<void> _handleSave() async {
    // Basic form validation
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() {
        _error = 'Please fill in both title and content';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Prepare update data
      final updateData = {'title': title, 'content': content};

      // Call update note service
      final updatedNote = await _noteService.updateNote(
        widget.note.$id,
        updateData,
      );

      // Reset form
      _resetForm();

      // Notify parent component and close modal
      widget.onNoteUpdated(updatedNote);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating note: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to update note. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Show error message if there is one
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Title input field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Content input field
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),

            // Buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
