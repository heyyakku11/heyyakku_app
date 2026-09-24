import 'package:flutter/material.dart';
import 'package:yakku/data/models/Poll.dart';

class PollCarouselItem {
  const PollCarouselItem({required this.poll, required this.backgroundColor});

  final PollModel poll;
  final Color backgroundColor;
}
