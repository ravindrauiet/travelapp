import 'dart:math';
import 'package:flutter/material.dart';

enum MemoryGameState { playing, gameOver, won }

class MemoryCard {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryGame {
  static const List<String> emojis = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
    '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔',
    '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇', '🐺',
    '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞',
  ];

  late List<MemoryCard> cards;
  late int score;
  late int moves;
  late int pairsFound;
  late MemoryGameState gameState;
  late List<int> flippedCards;
  late int totalPairs;

  MemoryGame() {
    initialize();
  }

  void initialize() {
    score = 0;
    moves = 0;
    pairsFound = 0;
    gameState = MemoryGameState.playing;
    flippedCards = [];
    totalPairs = 8; // 4x4 grid with 8 pairs
    
    _generateCards();
  }

  void _generateCards() {
    cards = [];
    final random = Random();
    final selectedEmojis = emojis.take(totalPairs).toList();
    
    // Create pairs
    for (int i = 0; i < totalPairs; i++) {
      cards.add(MemoryCard(id: i * 2, emoji: selectedEmojis[i]));
      cards.add(MemoryCard(id: i * 2 + 1, emoji: selectedEmojis[i]));
    }
    
    // Shuffle cards
    cards.shuffle(random);
  }

  void flipCard(int index) {
    if (gameState != MemoryGameState.playing) return;
    if (cards[index].isFlipped || cards[index].isMatched) return;
    if (flippedCards.length >= 2) return;

    setState(() {
      cards[index].isFlipped = true;
      flippedCards.add(index);
    });

    if (flippedCards.length == 2) {
      moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final card1 = cards[flippedCards[0]];
    final card2 = cards[flippedCards[1]];

    if (card1.emoji == card2.emoji) {
      // Match found
      card1.isMatched = true;
      card2.isMatched = true;
      pairsFound++;
      score += 10;
      
      if (pairsFound == totalPairs) {
        gameState = MemoryGameState.won;
      }
    } else {
      // No match, flip back after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        card1.isFlipped = false;
        card2.isFlipped = false;
      });
    }

    flippedCards.clear();
  }

  void restart() {
    initialize();
  }

  Color getCardColor(MemoryCard card) {
    if (card.isMatched) {
      return Colors.green[300]!;
    } else if (card.isFlipped) {
      return Colors.blue[200]!;
    } else {
      return Colors.grey[400]!;
    }
  }

  void setState(VoidCallback callback) {
    callback();
  }
}

typedef VoidCallback = void Function();
