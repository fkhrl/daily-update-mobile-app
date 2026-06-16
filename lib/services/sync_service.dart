import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'local_db_service.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void initialize() {
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      
      if (wasOffline && _isOnline) {
        if (kDebugMode) print('Connection restored! Triggering sync...');
        _syncQueue();
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    if (_isOnline) {
      _syncQueue();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _syncQueue() async {
    if (!_isOnline) return;

    final dbService = LocalDbService();
    final queue = await dbService.getSyncQueue();

    if (queue.isEmpty) return;

    if (kDebugMode) print('Syncing ${queue.length} items from queue...');

    for (var item in queue) {
      try {
        final id = item['id'];
        final action = item['action']; // CREATE, UPDATE, DELETE
        final entity = item['entity']; // task
        final entityId = item['entity_id'];
        final payload = jsonDecode(item['payload']);

        if (entity == 'task') {
          if (action == 'CREATE') {
            await ApiService().createTask(
              payload['title'],
              payload['description'],
              DateTime.parse(payload['scheduled_at']),
              payload['is_instant'] == 1,
              priority: payload['priority'],
              category: payload['category'],
              status: payload['status'],
              recurrence: payload['recurrence'],
              recurrenceInterval: payload['recurrence_interval'] ?? 1,
            );
          } else if (action == 'UPDATE') {
             await ApiService().updateTask(
              entityId,
              payload['title'] ?? '',
              payload['description'],
              DateTime.parse(payload['scheduled_at'] ?? DateTime.now().toIso8601String()),
              payload['is_instant'] == 1,
              payload['is_notified'] == 1,
              priority: payload['priority'],
              category: payload['category'],
              status: payload['status'],
              recurrence: payload['recurrence'],
              recurrenceInterval: payload['recurrence_interval'],
            );
          } else if (action == 'DELETE') {
            await ApiService().deleteTask(entityId);
          }
        }
        
        // Remove from queue on success
        await dbService.removeFromSyncQueue(id);
      } catch (e) {
        if (kDebugMode) print('Sync failed for item ${item['id']}: $e');
        // If it's an auth error or unrecoverable, we might want to handle it, but for now just leave it in queue
      }
    }
    
    // Refresh local DB after sync completes
    try {
      final tasksData = await ApiService().getTasks(page: 1); // Ideally fetch all pages, keeping simple for now
      final List<dynamic> rawTasks = tasksData['tasks'].map((t) => t.toJson()).toList();
      await dbService.saveTasks(rawTasks);
    } catch (e) {
      if (kDebugMode) print('Failed to refresh tasks after sync: $e');
    }
  }
}
