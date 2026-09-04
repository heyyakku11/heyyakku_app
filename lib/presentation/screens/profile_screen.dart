import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/utils/number_formatters.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/create_poll_screen.dart';
import 'package:yakku/presentation/screens/edit_profile_screen.dart';
import 'package:yakku/presentation/screens/poll_detail_screen.dart';
import 'package:yakku/presentation/screens/setting_screen.dart';
import 'package:yakku/presentation/widgets/anonymous_avatar.dart';
import 'package:yakku/presentation/widgets/empty_state.dart';
import 'package:yakku/presentation/widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingScreen()),
    );
  }

  void _openCreatePoll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePollScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polls = AppScope.of(context).polls;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      drawer: Drawer(
        child: Builder(
          builder: (drawerContext) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Yakku',
                      style: Theme.of(drawerContext).textTheme.headlineMedium,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.of(drawerContext).pop();
                    _openEditProfile(drawerContext);
                  },
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreatePoll(context),
        tooltip: 'Create poll',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: polls,
        builder: (context, _) {
          final user = polls.getCurrentUser();
          final myPolls = polls.getMyPolls();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              88,
            ),
            children: [
              Center(child: AnonymousAvatar(seed: user.avatarSeed, size: 84)),
              const SizedBox(height: AppSpacing.md),
              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Anonymous',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  _StatCard(
                    label: 'Questions',
                    value: compactNumber(user.questionsCount),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatCard(
                    label: 'Votes Received',
                    value: compactNumber(user.votesReceived),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatCard(
                    label: 'Answers',
                    value: compactNumber(user.answersCount),
                  ),
                ],
              ),
              const SectionHeader(
                title: 'My Questions',
                padding: EdgeInsets.only(
                  top: AppSpacing.xl,
                  bottom: AppSpacing.md,
                ),
              ),
              if (myPolls.isEmpty)
                const EmptyState(
                  title: 'No questions yet',
                  message: 'Your anonymous polls will appear here.',
                )
              else
                for (final poll in myPolls) ...[
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      title: Text(poll.question),
                      subtitle: Text(
                        '${compactNumber(poll.totalVotes)} votes',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PollDetailScreen(pollId: poll.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
