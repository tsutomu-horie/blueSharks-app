import 'package:flutter/material.dart';

class MenuDataStatus extends StatelessWidget {
  const MenuDataStatus({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      ]));
}
