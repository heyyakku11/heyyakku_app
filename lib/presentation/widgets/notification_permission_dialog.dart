import 'package:flutter/material.dart';

/// Returns `true` if the user chose Allow, `false` if Skip.
Future<bool?> showNotificationPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Stay in the loop'),
        content: const Text(
          'Allow notifications so you know when friends answer your polls.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      );
    },
  );
}
