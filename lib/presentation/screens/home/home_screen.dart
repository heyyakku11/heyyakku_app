import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/datasources/poll_list_datasource.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/poll_carousel_item.dart';
import 'package:yakku/presentation/screens/home/notification_screen.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onAskAnything});

  final VoidCallback? onAskAnything;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PollModel> _polls = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  void _loadPolls() {
    try {
      _polls = const PollListDataSource().fetchActivePolls();
      _error = null;
    } catch (error) {
      _polls = const [];
      _error = error;
    }
  }

  void _onShare(PollModel poll) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Share "${poll.question}"')));
  }

  void _onEdit(PollModel poll) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Edit "${poll.question}"')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          spacing: AppSpacing.xs,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'yakku'.toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'Stop guessing, Ask your people',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screen),
          itemCount: 1 + _itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PollCarousel(
                  polls: pollCarouselItems.map((item) => item.poll).toList(),
                ),
              );
            }

            if (_error != null) {
              return const _PollMessage(text: 'Could not load polls.');
            }

            if (_polls.isEmpty) {
              return const _PollMessage(text: 'No polls yet.');
            }

            final poll = _polls[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PollCard(
                poll: poll,
                onShare: () => _onShare(poll),
                onEdit: _onEdit,
              ),
            );
          },
        ),
      ),
    );
  }

  int get _itemCount {
    if (_error != null || _polls.isEmpty) return 1;
    return _polls.length;
  }
}

class _PollMessage extends StatelessWidget {
  const _PollMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

final List<PollCarouselItem> pollCarouselItems = [
  PollCarouselItem(
    backgroundColor: Colors.orange.shade100,
    poll: PollModel(
      id: 'poll-001',
      question: 'What do you prefer to drink in the morning?',
      categoryId: 'food',
      answerType: PollAnswerType.fromValue(1),
      allowCustomOption: false,
      status: PollStatus.fromValue(1),
      totalVoteCount: 124,
      options: [
        PollOptionModel(
          id: 'option-001',
          type: PollOptionType.fromValue(1),
          text: 'Coffee',
          imageUrl: null,
          sortOrder: 1,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-002',
          type: PollOptionType.fromValue(1),
          text: 'Tea',
          imageUrl: null,
          sortOrder: 2,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-003',
          type: PollOptionType.fromValue(1),
          text: 'Juice',
          imageUrl: null,
          sortOrder: 3,
          isCustom: false,
        ),
      ],
    ),
  ),

  PollCarouselItem(
    backgroundColor: Colors.blue.shade100,
    poll: PollModel(
      id: 'poll-002',
      question: 'Which technologies do you enjoy working with?',
      categoryId: 'technology',
      answerType: PollAnswerType.fromValue(2),
      allowCustomOption: false,
      status: PollStatus.fromValue(1),
      totalVoteCount: 89,
      options: [
        PollOptionModel(
          id: 'option-004',
          type: PollOptionType.fromValue(1),
          text: 'Flutter',
          imageUrl: null,
          sortOrder: 1,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-005',
          type: PollOptionType.fromValue(1),
          text: 'React',
          imageUrl: null,
          sortOrder: 2,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-006',
          type: PollOptionType.fromValue(1),
          text: 'Spring Boot',
          imageUrl: null,
          sortOrder: 3,
          isCustom: false,
        ),
      ],
    ),
  ),

  PollCarouselItem(
    backgroundColor: Colors.green.shade100,
    poll: PollModel(
      id: 'poll-003',
      question: 'Where would you rather spend your next vacation?',
      categoryId: 'travel',
      answerType: PollAnswerType.fromValue(1),
      allowCustomOption: true,
      status: PollStatus.fromValue(1),
      totalVoteCount: 216,
      options: [
        PollOptionModel(
          id: 'option-008',
          type: PollOptionType.fromValue(1),
          text: 'Mountains',
          imageUrl: null,
          sortOrder: 1,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-009',
          type: PollOptionType.fromValue(1),
          text: 'Beach',
          imageUrl: null,
          sortOrder: 2,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-010',
          type: PollOptionType.fromValue(1),
          text: 'City',
          imageUrl: null,
          sortOrder: 3,
          isCustom: false,
        ),
      ],
    ),
  ),
];

class PollCarousel extends StatefulWidget {
  const PollCarousel({super.key, required this.polls});

  final List<PollModel> polls;

  @override
  State<PollCarousel> createState() => _PollCarouselState();
}

class _PollCarouselState extends State<PollCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.90);

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.polls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.polls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final poll = widget.polls[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: pollCarouselItems[index].backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(
                        poll.question,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: poll.options.length,
                            itemBuilder: (context, optionIndex) {
                              final option = poll.options[optionIndex];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${option.text}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.8),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add),
                                const SizedBox(width: 4),
                                Text('Add your own option'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.black.withOpacity(0.8),
                          ),
                        ),
                        onPressed: () {
                          // Handle vote action
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Make it yours',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 15),
                          Text('Friends can add anonymously'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        _CarouselIndicator(
          count: widget.polls.length,
          currentIndex: _currentPage,
        ),
      ],
    );
  }
}

class _CarouselIndicator extends StatelessWidget {
  const _CarouselIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
