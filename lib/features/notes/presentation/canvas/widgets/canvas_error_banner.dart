import 'package:flutter/material.dart';
import '../../../../../core/errors/failures.dart';

class CanvasErrorBanner extends StatelessWidget {
  final Failure error;
  final VoidCallback onDismiss;

  const CanvasErrorBanner({
    super.key,
    required this.error,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: Colors.red.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.message,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}