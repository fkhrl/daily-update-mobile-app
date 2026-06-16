import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../utils/toast_util.dart';

class NotebookLmScreen extends StatefulWidget {
  const NotebookLmScreen({super.key});

  @override
  State<NotebookLmScreen> createState() => _NotebookLmScreenState();
}

class _NotebookLmScreenState extends State<NotebookLmScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  File? _imageFile;
  String? _answer;
  bool _isLoading = false;
  
  final _questionCtrl = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _answer = null; 
        });
      }
    } catch (e) {
      if (mounted) ToastUtil.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) {
      ToastUtil.showError(context, 'Please capture or select an image first.');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final result = await _apiService.askNotebookLM(base64Image, _questionCtrl.text);
      
      if (mounted) {
        setState(() {
          _answer = result;
        });
      }
    } catch (e) {
      if (mounted) ToastUtil.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark theme matching StudyHub
      appBar: AppBar(
        title: const Text('AI Study Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ask anything about your study materials.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Image Viewer with Premium Feel
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_imageFile!, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.6)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white),
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                      style: IconButton.styleFrom(backgroundColor: Colors.blueAccent),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo, size: 40, color: Colors.blueAccent),
                                ),
                                const SizedBox(height: 16),
                                const Text('Tap to Upload Image', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('Supports handwritten notes, formulas & diagrams', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Question Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      controller: _questionCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'What do you want to know? (Optional)',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                        prefixIcon: Icon(Icons.auto_awesome, color: Colors.blueAccent),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Analyze Button
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _analyzeImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Analyzing...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Analyze with AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Result
                  if (_answer != null) ...[
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amberAccent),
                        SizedBox(width: 10),
                        Text('AI Explanation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: MarkdownBody(
                        data: _answer!,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                          h1: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold),
                          h2: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold),
                          h3: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                          listBullet: const TextStyle(color: Colors.blueAccent, fontSize: 16),
                          code: TextStyle(backgroundColor: Colors.black45, color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
                          codeblockDecoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
