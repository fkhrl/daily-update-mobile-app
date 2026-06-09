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
}
