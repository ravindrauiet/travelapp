import 'dart:math';

/// Represents a position on the game board
class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Position($x, $y)';
}

/// Represents the direction the snake is moving
enum Direction {
  up,
  down,
  left,
  right,
}

/// Represents the game state
enum GameState {
  playing,
  paused,
  gameOver,
}

/// Snake game model with all game logic
class SnakeGame {
  static const int boardWidth = 20;
  static const int boardHeight = 20;
  static const int initialSnakeLength = 3;

  List<Position> _snake = [];
  Position? _food;
  Direction _direction = Direction.right;
  Direction _nextDirection = Direction.right;
  GameState _gameState = GameState.playing;
  int _score = 0;
  int _highScore = 0;
  bool _gameStarted = false;

  // Getters
  List<Position> get snake => List.unmodifiable(_snake);
  Position? get food => _food;
  Direction get direction => _direction;
  GameState get gameState => _gameState;
  int get score => _score;
  int get highScore => _highScore;
  bool get gameStarted => _gameStarted;

  /// Initialize the game
  void initialize() {
    _snake = [
      Position(boardWidth ~/ 2, boardHeight ~/ 2),
      Position(boardWidth ~/ 2 - 1, boardHeight ~/ 2),
      Position(boardWidth ~/ 2 - 2, boardHeight ~/ 2),
    ];
    _direction = Direction.right;
    _nextDirection = Direction.right;
    _gameState = GameState.playing;
    _score = 0;
    _gameStarted = true;
    _generateFood();
  }

  /// Change the snake's direction
  void changeDirection(Direction newDirection) {
    // Prevent the snake from going backwards into itself
    if (_direction == Direction.up && newDirection == Direction.down) return;
    if (_direction == Direction.down && newDirection == Direction.up) return;
    if (_direction == Direction.left && newDirection == Direction.right) return;
    if (_direction == Direction.right && newDirection == Direction.left) return;

    _nextDirection = newDirection;
  }

  /// Update the game state (move snake, check collisions, etc.)
  void update() {
    if (_gameState != GameState.playing) return;

    _direction = _nextDirection;

    // Calculate new head position
    Position head = _snake.first;
    Position newHead;

    switch (_direction) {
      case Direction.up:
        newHead = Position(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Position(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Position(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Position(head.x + 1, head.y);
        break;
    }

    // Check wall collision
    if (newHead.x < 0 || 
        newHead.x >= boardWidth || 
        newHead.y < 0 || 
        newHead.y >= boardHeight) {
      _gameOver();
      return;
    }

    // Check self collision
    if (_snake.contains(newHead)) {
      _gameOver();
      return;
    }

    // Add new head
    _snake.insert(0, newHead);

    // Check if food is eaten
    if (_food != null && newHead == _food) {
      _score += 10;
      if (_score > _highScore) {
        _highScore = _score;
      }
      _generateFood();
    } else {
      // Remove tail if no food eaten
      _snake.removeLast();
    }
  }

  /// Generate food at a random position
  void _generateFood() {
    final random = Random();
    Position newFood;

    do {
      newFood = Position(
        random.nextInt(boardWidth),
        random.nextInt(boardHeight),
      );
    } while (_snake.contains(newFood));

    _food = newFood;
  }

  /// End the game
  void _gameOver() {
    _gameState = GameState.gameOver;
  }

  /// Pause the game
  void pause() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
    }
  }

  /// Resume the game
  void resume() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
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

  /// Check if a position is occupied by the snake
  bool isSnakePosition(Position position) {
    return _snake.contains(position);
  }

  /// Check if a position is the food
  bool isFoodPosition(Position position) {
    return _food == position;
  }

  /// Get the snake head position
  Position? get snakeHead => _snake.isNotEmpty ? _snake.first : null;

  /// Get the snake tail position
  Position? get snakeTail => _snake.isNotEmpty ? _snake.last : null;
}
