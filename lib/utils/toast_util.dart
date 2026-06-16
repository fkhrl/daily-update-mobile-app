import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtil {
  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      autoCloseDuration: const Duration(seconds: 3),
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      showProgressBar: false,
      borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static void showError(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      autoCloseDuration: const Duration(seconds: 4),
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      showProgressBar: false,
      borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static void handleApiError(BuildContext context, String moduleName, dynamic error) {
    String message = 'An unexpected error occurred.';
    final errStr = error.toString().toLowerCase();

    if (errStr.contains('socketexception') || errStr.contains('network') || errStr.contains('failed host lookup')) {
      message = 'No internet connection. Please check your network.';
    } else if (errStr.contains('[500]') || errStr.contains('internal server error')) {
      message = 'Internal Server Error. Please try again later.';
    } else if (errStr.contains('[404]') || errStr.contains('not found')) {
      message = 'Data not found for $moduleName.';
    } else if (errStr.contains('[401]') || errStr.contains('unauthorized')) {
      message = 'Session expired. Please login again.';
    } else if (errStr.contains('[403]')) {
      message = 'You do not have permission to perform this action.';
    } else if (errStr.contains('[422]')) {
      message = 'Validation failed. Please check your inputs.';
    } else {
      // Remove generic 'Exception: ' prefix
      message = error.toString().replaceAll('Exception: ', '');
      if (message.isEmpty || message == 'null') {
        message = 'Failed to process $moduleName request.';
      }
    }
    
    showError(context, message);
  }
}
