import 'package:flutter/material.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/remote_poll_list.dart';

class AnsweredPollsScreen extends StatelessWidget {
  const AnsweredPollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answered')),
      body: RemotePollList(
        emptyMessage: 'No polls answered yet',
        errorFallback: 'Could not load answered polls',
        loadPolls: () => AppScope.of(context).activityPolls.getAnsweredPolls(),
      ),
    );
  }
}
