import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/toast_util.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _sessions = [];
  List<dynamic> _loginHistory = [];
  bool _isLoadingSessions = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSessions();
    _fetchHistory();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final data = await ApiService().getSessions();
      setState(() => _sessions = data);
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Failed to load sessions: $e');
    } finally {
      setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final data = await ApiService().getLoginHistory();
      setState(() => _loginHistory = data);
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Failed to load login history: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _revokeSession(int id) async {
    try {
      await ApiService().revokeSession(id);
      if (!mounted) return;
      ToastUtil.showSuccess(context, 'Session revoked successfully');
      _fetchSessions();
    } catch (e) {
      if (!mounted) return;
      ToastUtil.showError(context, 'Failed to revoke session: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Sessions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Sessions'),
            Tab(text: 'Login History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessions.isEmpty) {
      return const Center(child: Text('No active sessions found.', style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final lastUsed = session['last_used_at'] != null 
            ? DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(session['last_used_at']).toLocal())
            : 'Never';
            
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.devices, color: Color(0xFF818CF8)),
            title: Text(session['name'] ?? 'Device', style: const TextStyle(color: Colors.white)),
            subtitle: Text('Last used: $lastUsed', style: const TextStyle(color: Colors.white60)),
            trailing: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _revokeSession(session['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loginHistory.isEmpty) {
      return const Center(child: Text('No login history found.', style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loginHistory.length,
      itemBuilder: (context, index) {
        final history = _loginHistory[index];
        final loginTime = DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(history['login_at']).toLocal());
        
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF818CF8)),
            title: Text(history['device_name'] ?? 'Unknown Device', style: const TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IP: ${history['ip_address'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white60)),
                Text(loginTime, style: const TextStyle(color: Colors.white60)),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
