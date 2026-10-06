import 'package:flutter/material.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/remote_poll_list.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RemotePollList(
          emptyMessage: 'No polls asked yet',
          errorFallback: 'Could not load asked polls',
          ownerActions: true,
          loadPolls: () => AppScope.of(context).activityPolls.getCreatedPolls(),
        ),
      ),
    );
  }
}
