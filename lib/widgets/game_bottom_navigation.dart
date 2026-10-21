import 'package:flutter/material.dart';
import 'bottom_navigation.dart';

class GameBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const GameBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return const AppBottomNavigation(currentIndex: -1);
  }
}
