import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';

/// Shown right after a check is made: confirms it and offers the share code.
class CreatedCheckScreen extends StatelessWidget {
  const CreatedCheckScreen({super.key, required this.userCheck});

  final UserCheckResponse userCheck;

  static const _ink = Color(0xFF21191D);

  @override
  Widget build(BuildContext context) {
    final background = parseHexColor(
      userCheck.backgroundColor,
      fallback: YakkuPalette.cream,
    );

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, size: 44, color: _ink),
              const SizedBox(height: 16),
              const Text(
                'Your check is live',
                style: TextStyle(
                  color: _ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userCheck.question.isNotEmpty
                    ? userCheck.question
                    : userCheck.title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Share code',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SelectableText(
                        userCheck.shareCode,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: userCheck.shareCode),
                      );
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Share code copied')),
                        );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
