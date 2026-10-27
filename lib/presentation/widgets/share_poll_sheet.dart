import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/share/share_coordinator.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Opens the custom share sheet for [payload]. After a successful action the
/// sheet closes and, if the adapter provided one, a confirmation is shown.
Future<ShareResult?> showSharePollSheet(
  BuildContext context, {
  required SharePayload payload,
  ShareCoordinator? coordinator,
}) async {
  final result = await showModalBottomSheet<ShareResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (_) => SharePollSheet(
      payload: payload,
      coordinator: coordinator ?? ShareCoordinator(),
    ),
  );
  if (result is ShareSuccess && result.feedbackMessage != null) {
    AppToast.show(result.feedbackMessage!);
  }
  return result;
}

/// Convenience for call sites that hold an existing poll model. Shows a
/// snackbar and returns without opening the sheet if the poll can't be shared.
Future<ShareResult?> sharePollModel(BuildContext context, PollModel poll) =>
    _shareFrom(context, () => SharePayload.fromPollModel(poll));

Future<ShareResult?> sharePollResponse(
  BuildContext context,
  PollResponse poll,
) => _shareFrom(context, () => SharePayload.fromPollResponse(poll));

Future<ShareResult?> _shareFrom(
  BuildContext context,
  SharePayload Function() build,
) async {
  final SharePayload payload;
  try {
    payload = build();
  } on SharePayloadException {
    AppToast.show("This poll can't be shared right now.");
    return null;
  }
  if (!context.mounted) return null;
  return showSharePollSheet(context, payload: payload);
}

/// Generic sheet: renders whatever adapters the coordinator's registry offers
/// and delegates all sharing to it.
class SharePollSheet extends StatefulWidget {
  const SharePollSheet({
    super.key,
    required this.payload,
    required this.coordinator,
  });

  final SharePayload payload;
  final ShareCoordinator coordinator;

  @override
  State<SharePollSheet> createState() => _SharePollSheetState();
}

class _SharePollSheetState extends State<SharePollSheet> {
  late final Future<List<SharePlatformAdapter>> _platforms = widget.coordinator
      .availablePlatforms(widget.payload);
  SharePlatformId? _running;
  String? _error;

  Future<void> _onTap(SharePlatformAdapter adapter) async {
    if (_running != null) return;
    setState(() {
      _running = adapter.id;
      _error = null;
    });
    final result = await widget.coordinator.share(adapter.id, widget.payload);
    if (!mounted) return;
    switch (result) {
      case ShareSuccess():
        Navigator.of(context).pop(result);
      case ShareCancelled():
        setState(() => _running = null);
      case ShareUnsupported(:final userMessage):
        setState(() {
          _running = null;
          _error = userMessage;
        });
      case ShareFailure(:final userMessage):
        setState(() {
          _running = null;
          _error = userMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Share poll',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                widget.payload.question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FutureBuilder<List<SharePlatformAdapter>>(
              future: _platforms,
              builder: (context, snapshot) {
                final adapters = snapshot.data;
                if (adapters == null) {
                  return const SizedBox(
                    height: 76,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    for (final adapter in adapters)
                      _ShareOption(
                        adapter: adapter,
                        busy: _running == adapter.id,
                        enabled: _running == null,
                        onTap: () => _onTap(adapter),
                      ),
                  ],
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.adapter,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final SharePlatformAdapter adapter;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Share via ${adapter.displayName}',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 88, minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: adapter.brandColor,
                  ),
                  child: busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: adapter.onBrandColor,
                          ),
                        )
                      : Icon(
                          adapter.icon,
                          color: adapter.onBrandColor,
                          size: 26,
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  adapter.displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
