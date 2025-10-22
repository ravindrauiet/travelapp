import 'dart:math';
import 'package:flutter/material.dart';

enum Game2048State { playing, gameOver, won }

class Game2048 {
  static const int boardSize = 4;
  late List<List<int>> board;
  int score = 0;
  int bestScore = 0;
  Game2048State gameState = Game2048State.playing;
  bool hasWon = false;

  Game2048() {
    initialize();
  }

  void initialize() {
    board = List.generate(
      boardSize,
      (i) => List.generate(boardSize, (j) => 0),
    );
    score = 0;
    gameState = Game2048State.playing;
    hasWon = false;
    addRandomTile();
    addRandomTile();
  }

  void addRandomTile() {
    List<List<int>> emptyCells = [];
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == 0) {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final random = Random();
      final cell = emptyCells[random.nextInt(emptyCells.length)];
      board[cell[0]][cell[1]] = random.nextInt(10) < 9 ? 2 : 4;
    }
  }

  bool moveLeft() {
    bool moved = false;
    for (int i = 0; i < boardSize; i++) {
      List<int> row = board[i].where((cell) => cell != 0).toList();
      List<int> newRow = [];
      
      for (int j = 0; j < row.length; j++) {
        if (j < row.length - 1 && row[j] == row[j + 1]) {
          newRow.add(row[j] * 2);
          score += row[j] * 2;
          if (row[j] * 2 == 2048 && !hasWon) {
            hasWon = true;
            gameState = Game2048State.won;
          }
          j++; // Skip next tile
        } else {
          newRow.add(row[j]);
        }
      }
      
      while (newRow.length < boardSize) {
        newRow.add(0);
      }
      
      if (!_listsEqual(board[i], newRow)) {
        moved = true;
        board[i] = newRow;
      }
    }
    
    if (moved) {
      addRandomTile();
      if (!canMove()) {
        gameState = Game2048State.gameOver;
      }
    }
    
    return moved;
  }

  bool moveRight() {
    bool moved = false;
    for (int i = 0; i < boardSize; i++) {
      List<int> row = board[i].where((cell) => cell != 0).toList();
      List<int> newRow = [];
      
      for (int j = row.length - 1; j >= 0; j--) {
        if (j > 0 && row[j] == row[j - 1]) {
          newRow.insert(0, row[j] * 2);
          score += row[j] * 2;
          if (row[j] * 2 == 2048 && !hasWon) {
            hasWon = true;
            gameState = Game2048State.won;
          }
          j--; // Skip previous tile
        } else {
          newRow.insert(0, row[j]);
        }
      }
      
      while (newRow.length < boardSize) {
        newRow.insert(0, 0);
      }
      
      if (!_listsEqual(board[i], newRow)) {
        moved = true;
        board[i] = newRow;
      }
    }
    
    if (moved) {
      addRandomTile();
      if (!canMove()) {
        gameState = Game2048State.gameOver;
      }
    }
    
    return moved;
  }

  bool moveUp() {
    bool moved = false;
    for (int j = 0; j < boardSize; j++) {
      List<int> column = [];
      for (int i = 0; i < boardSize; i++) {
        if (board[i][j] != 0) {
          column.add(board[i][j]);
        }
      }
      
      List<int> newColumn = [];
      for (int i = 0; i < column.length; i++) {
        if (i < column.length - 1 && column[i] == column[i + 1]) {
          newColumn.add(column[i] * 2);
          score += column[i] * 2;
          if (column[i] * 2 == 2048 && !hasWon) {
            hasWon = true;
            gameState = Game2048State.won;
          }
          i++; // Skip next tile
        } else {
          newColumn.add(column[i]);
        }
      }
      
      while (newColumn.length < boardSize) {
        newColumn.add(0);
      }
      
      List<int> oldColumn = [];
      for (int i = 0; i < boardSize; i++) {
        oldColumn.add(board[i][j]);
      }
      
      if (!_listsEqual(oldColumn, newColumn)) {
        moved = true;
        for (int i = 0; i < boardSize; i++) {
          board[i][j] = newColumn[i];
        }
      }
    }
    
    if (moved) {
      addRandomTile();
      if (!canMove()) {
        gameState = Game2048State.gameOver;
      }
    }
    
    return moved;
  }

  bool moveDown() {
    bool moved = false;
    for (int j = 0; j < boardSize; j++) {
      List<int> column = [];
      for (int i = 0; i < boardSize; i++) {
        if (board[i][j] != 0) {
          column.add(board[i][j]);
        }
      }
      
      List<int> newColumn = [];
      for (int i = column.length - 1; i >= 0; i--) {
        if (i > 0 && column[i] == column[i - 1]) {
          newColumn.insert(0, column[i] * 2);
          score += column[i] * 2;
          if (column[i] * 2 == 2048 && !hasWon) {
            hasWon = true;
            gameState = Game2048State.won;
          }
          i--; // Skip previous tile
        } else {
          newColumn.insert(0, column[i]);
        }
      }
      
      while (newColumn.length < boardSize) {
        newColumn.insert(0, 0);
      }
      
      List<int> oldColumn = [];
      for (int i = 0; i < boardSize; i++) {
        oldColumn.add(board[i][j]);
      }
      
      if (!_listsEqual(oldColumn, newColumn)) {
        moved = true;
        for (int i = 0; i < boardSize; i++) {
          board[i][j] = newColumn[i];
        }
      }
    }
    
    if (moved) {
      addRandomTile();
      if (!canMove()) {
        gameState = Game2048State.gameOver;
      }
    }
    
    return moved;
  }

  bool canMove() {
    // Check for empty cells
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == 0) return true;
      }
    }
    
    // Check for possible merges
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        int current = board[i][j];
        if ((i < boardSize - 1 && board[i + 1][j] == current) ||
            (j < boardSize - 1 && board[i][j + 1] == current)) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _listsEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void restart() {
    initialize();
  }

  Color getTileColor(int value) {
    switch (value) {
      case 0: return const Color(0xFFCDC1B4);
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return const Color(0xFF3C3A32);
    }
  }

  Color getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : const Color(0xFFF9F6F2);
  }
}
