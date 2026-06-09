import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/toast_util.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';

class NotesScreen extends StatefulWidget {
  final int? taskId;
  const NotesScreen({super.key, this.taskId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notes = [];
  bool _isLoading = true;
  final TextEditingController _noteContentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isMarkdown = true;
  
  // Speech to Text states
  bool _isListening = false;
  late final stt.SpeechToText _speechToText;
  
  // Real Image states
  List<String> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedFilterTag;
  final Map<int, String> _summaries = {};
  final Map<int, bool> _isSummarizing = {};

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteContentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getNotes(taskId: widget.taskId);
      setState(() => _notes = data);
    } catch (e) {
      _showSnackbar('Error loading notes: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNote() async {
    final content = _noteContentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) return;

    try {
      await _apiService.createNote(
        content,
        taskId: widget.taskId,
        images: _selectedImages,
        isMarkdown: _isMarkdown,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      _noteContentController.clear();
      _tagsController.clear();
      setState(() {
        _selectedImages = [];
      });
      _loadNotes();
      _showSnackbar('Note saved successfully!');
    } catch (e) {
      _showSnackbar('Failed to save note: $e', isError: true);
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      await _apiService.deleteNote(noteId);
      setState(() {
        _notes.removeWhere((n) => n['id'] == noteId);
        _summaries.remove(noteId);
      });
      _showSnackbar('Note deleted.');
    } catch (e) {
      _showSnackbar('Failed to delete note: $e', isError: true);
    }
  }

  Future<void> _summarizeNote(int noteId, String content) async {
    setState(() => _isSummarizing[noteId] = true);
    try {
      final summaryData = await _apiService.summarizeNote(content);
      setState(() {
        _summaries[noteId] = summaryData['summary'] ?? 'No summary available.';
      });
    } catch (e) {
      _showSnackbar('Failed to summarize: $e', isError: true);
    } finally {
      setState(() => _isSummarizing[noteId] = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((e) => e.path));
        });
      }
    } catch (e) {
      _showSnackbar('Failed to pick images: $e', isError: true);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          _showSnackbar('Speech recognition error: ${errorNotification.errorMsg}', isError: true);
          setState(() => _isListening = false);
        },
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              // Append to existing text or replace it
              // We'll append it
              _noteContentController.text = "${_noteContentController.text} ${result.recognizedWords}".trimLeft();
            });
          },
        );
      } else {
        _showSnackbar('Speech recognition not available', isError: true);
      }
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (isError) {
      ToastUtil.showError(context, msg);
    } else {
      ToastUtil.showSuccess(context, msg);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.taskId != null ? 'Task Attachments & Notes' : 'Journal & Thoughts',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Editor Panel
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _noteContentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Write notes here... (Use # for title, - for list)',
                    hintStyle: TextStyle(color: Color(0xFF64748B)),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagsController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Tags (comma separated)',
                          hintStyle: TextStyle(color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Markdown', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Switch(
                      value: _isMarkdown,
                      onChanged: (val) => setState(() => _isMarkdown = val),
                      activeThumbColor: Colors.indigoAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (ctx, idx) => Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: kIsWeb 
                                    ? NetworkImage(_selectedImages[idx]) as ImageProvider
                                    : FileImage(File(_selectedImages[idx])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(idx)),
                              child: const CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                // Attachments Controls
                Row(
                  children: [
                    // Voice record
                    IconButton(
                      onPressed: _toggleListening,
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.redAccent : const Color(0xFF94A3B8),
                      ),
                    ),
                    // Image picker
                    IconButton(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _createNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tag Filter Bar
          if (_notes.isNotEmpty)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedFilterTag == null,
                    onSelected: (val) => setState(() => _selectedFilterTag = null),
                    selectedColor: Colors.indigoAccent,
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(color: _selectedFilterTag == null ? Colors.white : Colors.white70),
                    showCheckmark: false,
                  ),
                  ..._notes
                      .expand((n) => (n['tags'] as List?)?.map((t) => t.toString()).toList() ?? <String>[])
                      .toSet()
                      .map((tag) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ChoiceChip(
                              label: Text('#$tag'),
                              selected: _selectedFilterTag == tag,
                              onSelected: (val) => setState(() => _selectedFilterTag = val ? tag : null),
                              selectedColor: Colors.indigoAccent,
                              backgroundColor: const Color(0xFF1E293B),
                              labelStyle: TextStyle(color: _selectedFilterTag == tag ? Colors.white : Colors.white70),
                              showCheckmark: false,
                            ),
                          )),
                ],
              ),
            ),

          // 2. Notes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? const Center(
                        child: Text(
                          'No attachments or notes found.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : Builder(builder: (context) {
                        final filteredNotes = _selectedFilterTag == null
                            ? _notes
                            : _notes.where((n) {
                                final tags = (n['tags'] as List?)?.map((t) => t.toString()) ?? [];
                                return tags.contains(_selectedFilterTag);
                              }).toList();
                              
                        if (filteredNotes.isEmpty) {
                          return const Center(child: Text('No notes found for this tag.', style: TextStyle(color: Color(0xFF64748B))));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredNotes.length,
                          itemBuilder: (ctx, idx) {
                            final note = filteredNotes[idx];
                            final imagesList = note['images'] as List?;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Journal Entry',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteNote(note['id']),
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFF475569), size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),

                                // Text Render
                                (note['is_markdown'] == 1 || note['is_markdown'] == true) 
                                    ? MarkdownBody(
                                        data: note['content'] ?? '',
                                        styleSheet: MarkdownStyleSheet(
                                          p: const TextStyle(color: Colors.white70, fontSize: 14),
                                          h1: const TextStyle(color: Colors.indigoAccent, fontSize: 18, fontWeight: FontWeight.bold),
                                          listBullet: const TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : Text(note['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 10),

                                // Tags Row
                                if (note['tags'] != null && (note['tags'] as List).isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    children: (note['tags'] as List).map((t) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('#$t', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                    )).toList(),
                                  ),

                                // AI Summarize Button
                                if ((note['content']?.toString() ?? '').length > 50)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _isSummarizing[note['id']] == true ? null : () => _summarizeNote(note['id'], note['content']),
                                      icon: _isSummarizing[note['id']] == true 
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 14),
                                      label: const Text('AI Summarize', style: TextStyle(color: Colors.indigoAccent, fontSize: 11)),
                                    ),
                                  ),

                                // AI Summary Box
                                if (_summaries.containsKey(note['id']))
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1B4B).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _summaries[note['id']]!,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 10),

                                // Image list attachments preview
                                if (imagesList != null && imagesList.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: imagesList.map((img) {
                                        final imageUrl = "${ApiService.baseUrl.replaceFirst('/api', '/storage')}/$img";
                                        return GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                backgroundColor: Colors.transparent,
                                                insetPadding: const EdgeInsets.all(10),
                                                child: Stack(
                                                  alignment: Alignment.topRight,
                                                  children: [
                                                    InteractiveViewer(
                                                      panEnabled: true,
                                                      minScale: 0.5,
                                                      maxScale: 4,
                                                      child: Image.network(imageUrl, fit: BoxFit.contain),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                                      onPressed: () => Navigator.pop(context),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 80,
                                                height: 80,
                                                color: const Color(0xFF0F172A),
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
          ),
        ],
      ),
    );
  }
}
