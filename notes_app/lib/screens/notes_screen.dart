import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/models.dart' as models;
import '../providers/auth_provider.dart';
import '../services/note_service.dart';
import '../widgets/note_item.dart';
import '../widgets/add_note_modal.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  List<models.Document> _notes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer fetch until after build to access context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotes();
    });
  }

  // Function to fetch notes from the database
  Future<void> _fetchNotes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.$id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fetchedNotes = await _noteService.getNotes(userId: userId);

      setState(() {
        _notes = fetchedNotes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notes: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load notes. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // Show the add note dialog
  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNoteModal(onNoteAdded: _handleNoteAdded),
    );
  }

  // Add the new note to the state and avoid refetching
  void _handleNoteAdded(Map<String, dynamic> noteData) {
    final newNote = models.Document(
      $id: noteData['\$id'] ?? 'temp-id',
      $collectionId: 'notes',
      $databaseId: 'NotesDB',
      $createdAt: DateTime.now().toString(),
      $updatedAt: DateTime.now().toString(),
      $permissions: [],
      data: noteData,
      $sequence: 0, // Added dummy sequence for optimistic update
    );

    setState(() {
      _notes = [newNote, ..._notes];
    });
  }

  // Handle note deletion by removing it from state
  void _handleNoteDeleted(String noteId) {
    setState(() {
      _notes = _notes.where((note) => note.$id != noteId).toList();
    });
  }

  // Handle note update
  void _handleNoteUpdated(models.Document updatedNote) {
    setState(() {
      final index = _notes.indexWhere((note) => note.$id == updatedNote.$id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Notes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton(
                  onPressed: _showAddNoteDialog,
                  child: const Text('+ Add Note'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show loading indicator
            if (_isLoading && _notes.isEmpty)
              const Center(child: CircularProgressIndicator()),

            // Show error message
            if (_error != null && _notes.isEmpty)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),

            // Show the notes list
            if (!_isLoading || _notes.isNotEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchNotes,
                  child: ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      return NoteItem(
                        note: _notes[index],
                        onNoteDeleted: _handleNoteDeleted,
                        onNoteUpdated: _handleNoteUpdated,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
