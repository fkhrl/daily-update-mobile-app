import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _workspaces = [];
  bool _isLoading = true;

  int? _activeWorkspaceId;
  Map<String, dynamic>? _activeWorkspaceDetails;
  List<dynamic> _activityLogs = [];
  bool _isLoadingDetails = false;

  // New forms inputs
  final TextEditingController _wsNameController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _selectedTemplate = 'blank';

  @override
  void initState() {
    super.initState();
    _loadWorkspaces();
  }

  Future<void> _loadWorkspaces() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getWorkspaces();
      setState(() {
        _workspaces = list;
        if (_workspaces.isNotEmpty) {
          _activeWorkspaceId = _workspaces.first['id'];
        }
      });
      if (_activeWorkspaceId != null) {
        _loadWorkspaceDetails(_activeWorkspaceId!);
      }
    } catch (e) {
      _showSnackbar('Failed to load workspaces: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWorkspaceDetails(int id) async {
    setState(() => _isLoadingDetails = true);
    try {
      final details = await _apiService.getWorkspaceDetails(id);
      final logs = await _apiService.getWorkspaceActivity(id);
      setState(() {
        _activeWorkspaceDetails = details;
        _activityLogs = logs;
      });
    } catch (e) {
      _showSnackbar('Failed to load details: $e', isError: true);
    } finally {
      setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _createWorkspace() async {
    final name = _wsNameController.text.trim();
    if (name.isEmpty) return;

    try {
      await _apiService.createWorkspace(name, templateType: _selectedTemplate == 'blank' ? null : _selectedTemplate);
      _wsNameController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackbar('Workspace created!');
      _loadWorkspaces();
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorDialog(context, 'Creation Failed', e);
    }
  }

  Future<void> _inviteMember() async {
    if (_activeWorkspaceId == null) return;
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    try {
      await _apiService.inviteWorkspaceMember(_activeWorkspaceId!, email);
      _inviteEmailController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackbar('Team member invited successfully!');
      _loadWorkspaceDetails(_activeWorkspaceId!);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorDialog(context, 'Invitation Failed', e);
    }
  }

  Future<void> _leaveWorkspace() async {
    if (_activeWorkspaceId == null) return;
    try {
      await _apiService.leaveWorkspace(_activeWorkspaceId!);
      _showSnackbar('Left workspace.');
      _loadWorkspaces();
    } catch (e) {
      _showSnackbar('Failed: $e', isError: true);
    }
  }

  // Task Comments sheet
  Future<void> _openCommentsSheet(int taskId, String taskTitle) async {
    List<dynamic> comments = [];
    bool loadingComments = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          if (loadingComments) {
            _apiService.getTaskComments(taskId).then((data) {
              setSheetState(() {
                comments = data;
                loadingComments = false;
              });
            });
          }

          Future<void> postComment() async {
            final content = _commentController.text.trim();
            if (content.isEmpty) return;
            try {
              final newComment = await _apiService.addTaskComment(taskId, content);
              setSheetState(() {
                comments.add(newComment);
              });
              _commentController.clear();
              _showSnackbar('Comment posted!');
              // reload workspace activity
              if (_activeWorkspaceId != null) {
                _apiService.getWorkspaceActivity(_activeWorkspaceId!).then((logs) {
                  setState(() => _activityLogs = logs);
                });
              }
            } catch (e) {
              if (!mounted) return;
              UIHelpers.showErrorDialog(context, 'Comment Failed', e);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SizedBox(
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Comments: $taskTitle',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: loadingComments
                        ? const Center(child: CircularProgressIndicator())
                        : comments.isEmpty
                            ? const Center(child: Text('No comments posted yet.', style: TextStyle(color: Color(0xFF64748B))))
                            : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (c, idx) {
                                  final comment = comments[idx];
                                  final author = comment['user']['name'] ?? 'Teammate';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(author, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent, fontSize: 12)),
                                        const SizedBox(height: 3),
                                        Text(comment['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Add team comment...',
                            hintStyle: const TextStyle(color: Color(0xFF475569)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: postComment,
                        icon: const Icon(Icons.send, color: Colors.indigoAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddWorkspaceDialog() {
    _selectedTemplate = 'blank'; // reset

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (stCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New Workspace Name', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              TextField(
                controller: _wsNameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Acme Marketing, Mobile Dev',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Text('Workspace Template', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Blank'),
                    selected: _selectedTemplate == 'blank',
                    onSelected: (val) => setSheetState(() => _selectedTemplate = 'blank'),
                    selectedColor: Colors.indigoAccent,
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: _selectedTemplate == 'blank' ? Colors.white : Colors.white54),
                  ),
                  ChoiceChip(
                    label: const Text('Student Routine (Auto-setup)'),
                    selected: _selectedTemplate == 'student',
                    onSelected: (val) => setSheetState(() => _selectedTemplate = 'student'),
                    selectedColor: Colors.indigoAccent,
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: _selectedTemplate == 'student' ? Colors.white : Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createWorkspace,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                child: const Text('Create Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Invite Teammate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Enter email address of registered user:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            const SizedBox(height: 12),
            TextField(
              controller: _inviteEmailController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. member@workplace.com',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _inviteMember,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
              child: const Text('Send Invitation', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (isError) {
      ToastUtil.handleApiError(context, 'WORKSPACE', msg);
    } else {
      ToastUtil.showSuccess(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Workspace & Teams', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _showAddWorkspaceDialog, icon: const Icon(Icons.add_business, color: Colors.indigoAccent)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workspaces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No team workspaces yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: _showAddWorkspaceDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Workspace'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Workspaces Selector list
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _workspaces.length,
                        itemBuilder: (ctx, idx) {
                          final ws = _workspaces[idx];
                          final active = ws['id'] == _activeWorkspaceId;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(ws['name'] ?? ''),
                              selected: active,
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _activeWorkspaceId = ws['id']);
                                  _loadWorkspaceDetails(ws['id']);
                                }
                              },
                              selectedColor: Colors.indigoAccent,
                              backgroundColor: const Color(0xFF1E293B),
                              labelStyle: TextStyle(
                                color: active ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Color(0xFF1E293B)),

                    // Workspace Detail Panel
                    Expanded(
                      child: _isLoadingDetails
                          ? const Center(child: CircularProgressIndicator())
                          : _activeWorkspaceDetails == null
                              ? const Center(child: Text('Select a workspace to view details', style: TextStyle(color: Color(0xFF64748B))))
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Workspace Admin panel card
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Active Team Members', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                                          Row(
                                            children: [
                                              TextButton.icon(
                                                onPressed: _showInviteDialog,
                                                icon: const Icon(Icons.person_add, size: 16),
                                                label: const Text('Invite', style: TextStyle(fontSize: 12)),
                                              ),
                                              TextButton.icon(
                                                onPressed: _leaveWorkspace,
                                                icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.redAccent),
                                                label: const Text('Leave', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 5),

                                      // Members list horizontal
                                      SizedBox(
                                        height: 70,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: (_activeWorkspaceDetails!['members'] as List).length,
                                          itemBuilder: (ctx, idx) {
                                            final m = _activeWorkspaceDetails!['members'][idx];
                                            return Card(
                                              color: const Color(0xFF1E293B),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    const CircleAvatar(radius: 12, backgroundColor: Colors.indigoAccent, child: Icon(Icons.person, size: 14, color: Colors.white)),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(m['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                        Text(m['pivot']['role'] ?? 'member', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 25),

                                      // Tasks Scoped
                                      Text('Team Shared Tasks', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                                      const SizedBox(height: 8),
                                      if ((_activeWorkspaceDetails!['tasks'] as List).isEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: const Color(0xFF1E293B).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                                          child: const Text('No shared tasks in this workspace. Create task inside board.', style: TextStyle(color: Color(0xFF94A3B8))),
                                        )
                                      else
                                        ...(_activeWorkspaceDetails!['tasks'] as List).map((task) => Card(
                                              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                                              child: ListTile(
                                                title: Text(task['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                subtitle: Text('Status: ${task['status'] ?? 'pending'}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.indigoAccent),
                                                  onPressed: () => _openCommentsSheet(task['id'], task['title']),
                                                ),
                                              ),
                                            )),

                                      const SizedBox(height: 25),

                                      // Activity Feed logs
                                      Text('Workspace Activity Timeline', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigoAccent)),
                                      const SizedBox(height: 8),
                                      ..._activityLogs.map((log) {
                                        final actor = log['user']['name'] ?? 'Someone';
                                        final actionText = (log['action'] as String).replaceAll('_', ' ').toUpperCase();
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF1E293B)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.schedule, size: 16, color: Colors.indigoAccent),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  '$actor $actionText',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
    );
  }
}

