import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// "Ask back" pill beside a voter's reason. Tapping it starts the private
/// conversation for that vote (or opens the one that already exists).
///
/// [voteId] is the reason's id. Show it only for a reason with `canAskBack`;
/// the server decides again who may ask whom.
class AskBackButton extends StatefulWidget {
  const AskBackButton({super.key, required this.voteId});

  final String voteId;

  @override
  State<AskBackButton> createState() => _AskBackButtonState();
}

class _AskBackButtonState extends State<AskBackButton> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    final scope = AppScope.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final conversation = await scope.askBack.start(widget.voteId);
      if (!mounted) return;
      unawaited(router.push(AppRoutes.askBackChatLocation(conversation.id)));
    } catch (error) {
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not start the conversation',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YakkuPalette.pillPink,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _busy ? null : _start,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: YakkuPalette.primary,
                  ),
                )
              else
                const Icon(
                  Icons.reply_rounded,
                  size: 16,
                  color: YakkuPalette.primary,
                ),
              const SizedBox(width: 8),
              const Text(
                'Ask back',
                style: TextStyle(
                  color: YakkuPalette.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: YakkuPalette.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
