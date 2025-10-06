import 'dart:math';
import 'package:flutter/material.dart';

/// Represents a position on the Tetris board
class TetrisPosition {
  final int x;
  final int y;

  const TetrisPosition(this.x, this.y);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TetrisPosition && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'TetrisPosition($x, $y)';
}

/// Represents a Tetris piece (tetromino)
class TetrisPiece {
  final List<List<int>> shape;
  final Color color;
  final String name;

  const TetrisPiece({
    required this.shape,
    required this.color,
    required this.name,
  });

  /// Get all possible rotations of this piece
  List<List<List<int>>> get rotations {
    List<List<List<int>>> result = [shape];
    List<List<int>> current = shape;
    
    for (int i = 0; i < 3; i++) {
      current = _rotateMatrix(current);
      result.add(current);
    }
    
    return result;
  }

  /// Rotate a matrix 90 degrees clockwise
  List<List<int>> _rotateMatrix(List<List<int>> matrix) {
    int rows = matrix.length;
    int cols = matrix[0].length;
    List<List<int>> rotated = List.generate(cols, (_) => List.filled(rows, 0));
    
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        rotated[j][rows - 1 - i] = matrix[i][j];
      }
    }
    
    return rotated;
  }
}

/// Represents the current falling piece
class FallingPiece {
  final TetrisPiece piece;
  final int rotation;
  final TetrisPosition position;

  const FallingPiece({
    required this.piece,
    required this.rotation,
    required this.position,
  });

  /// Get the current shape of the falling piece
  List<List<int>> get currentShape => piece.rotations[rotation];

  /// Move the piece
  FallingPiece move(int dx, int dy) {
    return FallingPiece(
      piece: piece,
      rotation: rotation,
      position: TetrisPosition(position.x + dx, position.y + dy),
    );
  }

  /// Rotate the piece
  FallingPiece rotate() {
    return FallingPiece(
      piece: piece,
      rotation: (rotation + 1) % piece.rotations.length,
      position: position,
    );
  }

  /// Get all occupied positions of this piece
  List<TetrisPosition> get occupiedPositions {
    List<TetrisPosition> positions = [];
    List<List<int>> shape = currentShape;
    
    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          positions.add(TetrisPosition(
            position.x + x,
            position.y + y,
          ));
        }
      }
    }
    
    return positions;
  }
}

/// Represents the game state
enum TetrisGameState {
  playing,
  paused,
  gameOver,
}

/// Tetris game model with all game logic
class TetrisGame {
  static const int boardWidth = 10;
  static const int boardHeight = 20;
  static const int initialDropSpeed = 1000; // milliseconds

  // Game board (0 = empty, 1 = filled)
  List<List<int>> _board = [];
  FallingPiece? _currentPiece;
  TetrisPiece? _nextPiece;
  TetrisGameState _gameState = TetrisGameState.playing;
  int _score = 0;
  int _highScore = 0;
  int _level = 1;
  int _linesCleared = 0;
  int _dropSpeed = initialDropSpeed;
  bool _gameStarted = false;

  // Tetris pieces
  static const List<TetrisPiece> _pieces = [
    // I piece
    TetrisPiece(
      shape: [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ],
      color: Color(0xFF00FFFF), // Cyan
      name: 'I',
    ),
    // O piece
    TetrisPiece(
      shape: [
        [1, 1],
        [1, 1],
      ],
      color: Color(0xFFFFFF00), // Yellow
      name: 'O',
    ),
    // T piece
    TetrisPiece(
      shape: [
        [0, 1, 0],
        [1, 1, 1],
        [0, 0, 0],
      ],
      color: Color(0xFF800080), // Purple
      name: 'T',
    ),
    // S piece
    TetrisPiece(
      shape: [
        [0, 1, 1],
        [1, 1, 0],
        [0, 0, 0],
      ],
      color: Color(0xFF00FF00), // Green
      name: 'S',
    ),
    // Z piece
    TetrisPiece(
      shape: [
        [1, 1, 0],
        [0, 1, 1],
        [0, 0, 0],
      ],
      color: Color(0xFFFF0000), // Red
      name: 'Z',
    ),
    // J piece
    TetrisPiece(
      shape: [
        [1, 0, 0],
        [1, 1, 1],
        [0, 0, 0],
      ],
      color: Color(0xFF0000FF), // Blue
      name: 'J',
    ),
    // L piece
    TetrisPiece(
      shape: [
        [0, 0, 1],
        [1, 1, 1],
        [0, 0, 0],
      ],
      color: Color(0xFFFF8000), // Orange
      name: 'L',
    ),
  ];

  // Getters
  List<List<int>> get board => _board.map((row) => List<int>.from(row)).toList();
  FallingPiece? get currentPiece => _currentPiece;
  TetrisPiece? get nextPiece => _nextPiece;
  TetrisGameState get gameState => _gameState;
  int get score => _score;
  int get highScore => _highScore;
  int get level => _level;
  int get linesCleared => _linesCleared;
  int get dropSpeed => _dropSpeed;
  bool get gameStarted => _gameStarted;

  /// Initialize the game
  void initialize() {
    _board = List.generate(
      boardHeight,
      (_) => List.filled(boardWidth, 0),
    );
    _currentPiece = null;
    _nextPiece = null;
    _gameState = TetrisGameState.playing;
    _score = 0;
    _level = 1;
    _linesCleared = 0;
    _dropSpeed = initialDropSpeed;
    _gameStarted = true;
    _spawnNewPiece();
  }

  /// Spawn a new piece
  void _spawnNewPiece() {
    final random = Random();
    final piece = _pieces[random.nextInt(_pieces.length)];
    
    _currentPiece = FallingPiece(
      piece: piece,
      rotation: 0,
      position: TetrisPosition(boardWidth ~/ 2 - 1, 0),
    );

    // Check if the new piece can be placed
    if (_isCollision(_currentPiece!)) {
      _gameOver();
      return;
    }

    // Generate next piece
    _nextPiece = _pieces[random.nextInt(_pieces.length)];
  }

  /// Move the current piece left
  void moveLeft() {
    if (_gameState != TetrisGameState.playing || _currentPiece == null) return;
    
    final newPiece = _currentPiece!.move(-1, 0);
    if (!_isCollision(newPiece)) {
      _currentPiece = newPiece;
    }
  }

  /// Move the current piece right
  void moveRight() {
    if (_gameState != TetrisGameState.playing || _currentPiece == null) return;
    
    final newPiece = _currentPiece!.move(1, 0);
    if (!_isCollision(newPiece)) {
      _currentPiece = newPiece;
    }
  }

  /// Move the current piece down
  void moveDown() {
    if (_gameState != TetrisGameState.playing || _currentPiece == null) return;
    
    final newPiece = _currentPiece!.move(0, 1);
    if (!_isCollision(newPiece)) {
      _currentPiece = newPiece;
    } else {
      _placePiece();
    }
  }

  /// Drop the current piece to the bottom
  void drop() {
    if (_gameState != TetrisGameState.playing || _currentPiece == null) return;
    
    FallingPiece newPiece = _currentPiece!;
    while (!_isCollision(newPiece.move(0, 1))) {
      newPiece = newPiece.move(0, 1);
    }
    _currentPiece = newPiece;
    _placePiece();
  }

  /// Rotate the current piece
  void rotate() {
    if (_gameState != TetrisGameState.playing || _currentPiece == null) return;
    
    final newPiece = _currentPiece!.rotate();
    if (!_isCollision(newPiece)) {
      _currentPiece = newPiece;
    }
  }

  /// Check if a piece collides with the board or boundaries
  bool _isCollision(FallingPiece piece) {
    for (final pos in piece.occupiedPositions) {
      // Check boundaries
      if (pos.x < 0 || pos.x >= boardWidth || pos.y >= boardHeight) {
        return true;
      }
      
      // Check if position is already filled (and not above the board)
      if (pos.y >= 0 && _board[pos.y][pos.x] == 1) {
        return true;
      }
    }
    
    return false;
  }

  /// Place the current piece on the board
  void _placePiece() {
    if (_currentPiece == null) return;
    
    for (final pos in _currentPiece!.occupiedPositions) {
      if (pos.y >= 0) {
        _board[pos.y][pos.x] = 1;
      }
    }
    
    _currentPiece = null;
    _clearLines();
    _spawnNewPiece();
  }

  /// Clear completed lines and update score
  void _clearLines() {
    List<int> linesToClear = [];
    
    for (int y = 0; y < boardHeight; y++) {
      if (_board[y].every((cell) => cell == 1)) {
        linesToClear.add(y);
      }
    }
    
    if (linesToClear.isNotEmpty) {
      // Remove cleared lines
      for (int y in linesToClear.reversed) {
        _board.removeAt(y);
        _board.insert(0, List.filled(boardWidth, 0));
      }
      
      // Update score and level
      _linesCleared += linesToClear.length;
      _score += _calculateScore(linesToClear.length);
      
      if (_score > _highScore) {
        _highScore = _score;
      }
      
      // Increase level every 10 lines
      _level = (_linesCleared ~/ 10) + 1;
      _dropSpeed = (initialDropSpeed * 0.8).round().clamp(100, initialDropSpeed);
    }
  }

  /// Calculate score for cleared lines
  int _calculateScore(int linesCleared) {
    switch (linesCleared) {
      case 1:
        return 100 * _level;
      case 2:
        return 300 * _level;
      case 3:
        return 500 * _level;
      case 4:
        return 800 * _level;
      default:
        return 0;
    }
  }

  /// End the game
  void _gameOver() {
    _gameState = TetrisGameState.gameOver;
  }

  /// Pause the game
  void pause() {
    if (_gameState == TetrisGameState.playing) {
      _gameState = TetrisGameState.paused;
    }
  }

  /// Resume the game
  void resume() {
    if (_gameState == TetrisGameState.paused) {
      _gameState = TetrisGameState.playing;
    }
  }

  /// Restart the game
  void restart() {
    initialize();
  }

  /// Set high score (for persistence)
  void setHighScore(int score) {
    _highScore = score;
  }

  /// Check if a position is occupied by a falling piece
  bool isFallingPiecePosition(TetrisPosition position) {
    if (_currentPiece == null) return false;
    return _currentPiece!.occupiedPositions.contains(position);
  }

  /// Get the color of a position (for rendering)
  Color? getPositionColor(TetrisPosition position) {
    if (position.y < 0 || position.y >= boardHeight || 
        position.x < 0 || position.x >= boardWidth) {
      return null;
    }
    
    if (_board[position.y][position.x] == 1) {
      return Colors.grey[600];
    }
    
    if (isFallingPiecePosition(position)) {
      return _currentPiece!.piece.color;
    }
    
    return null;
  }
}
