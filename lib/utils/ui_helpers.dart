import 'package:flutter/material.dart';

class UIHelpers {
  static void showErrorDialog(BuildContext context, String title, dynamic error) {
    String message = error.toString().replaceAll('Exception: ', '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          title, 
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.indigoAccent),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
