import 'package:flutter/material.dart';
import 'package:yakku/presentation/screens/home/home_feed_dummy.dart';
import 'package:yakku/presentation/screens/home/widgets/home_feed_body.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: HomeFeedBody(feed: homeFeedDummy)),
    );
  }
}
