import 'package:flutter/material.dart';
import 'package:yakku/data/datasources/poll_list_datasource.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/presentation/screens/notification_screen.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';

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
        title: Text(
          'yakku'.toUpperCase(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
          padding: const EdgeInsets.all(10),
          itemCount: 1 + _itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _HomeHero(onAskAnything: widget.onAskAnything),
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

class _HomeHero extends StatelessWidget {
  const _HomeHero({this.onAskAnything});

  final VoidCallback? onAskAnything;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Expanded(
          child: Column(
            spacing: 10,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: 'Stop guessing.\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: 'Get a '),
                    TextSpan(
                      text: 'reality check.',
                      style: TextStyle(color: Colors.yellow),
                    ),
                  ],
                ),
              ),
              const Text(
                'Ask your friends what they \nreally think.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              GestureDetector(
                onTap: onAskAnything,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 14.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Ask Yours',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 20),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: Image.asset('assets/images/home.png')),
      ],
    );
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
