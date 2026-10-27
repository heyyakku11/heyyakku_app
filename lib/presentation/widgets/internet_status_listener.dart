import 'package:flutter/material.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakku/core/network/internet_status.dart';
import 'package:yakku/presentation/cubit/internet/internet_cubit.dart';
import 'package:yakku/presentation/widgets/offline_banner.dart';

/// Hosts the global offline banner and restored-connection snackbar.
///
/// Does not block interaction with the rest of the app.
class InternetStatusListener extends StatefulWidget {
  const InternetStatusListener({super.key, required this.child});

  final Widget? child;

  @override
  State<InternetStatusListener> createState() => _InternetStatusListenerState();
}

class _InternetStatusListenerState extends State<InternetStatusListener> {
  /// Avoids showing "restored" when the app boots already online
  /// (cubit starts as [InternetStatus.offline] until initialize completes).
  bool _sawOfflineWhileMounted = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternetCubit, InternetStatus>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, status) {
        if (status == InternetStatus.offline) {
          _sawOfflineWhileMounted = true;
          return;
        }

        if (!_sawOfflineWhileMounted || status != InternetStatus.online) {
          return;
        }

        AppToast.show(
          'Internet connection restored',
          duration: const Duration(seconds: 2),
        );
      },
      builder: (context, status) {
        final content = widget.child ?? const SizedBox.shrink();
        if (status != InternetStatus.offline) {
          return content;
        }

        return Column(
          children: [
            const OfflineBanner(),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
