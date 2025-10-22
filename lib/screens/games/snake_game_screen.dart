import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/snake_game.dart';
import '../../utils/app_theme.dart';
import '../../widgets/game_bottom_navigation.dart';

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  late SnakeGame _game;
  Timer? _gameTimer;
  bool _isGameRunning = false;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _game = SnakeGame();
    _game.initialize();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    if (_game.gameState == GameState.gameOver) {
      _game.restart();
    }
    _game.resume();
    _startTimer();
  }

  void _pauseGame() {
    _game.pause();
    _stopTimer();
  }

  void _restartGame() {
    _game.restart();
    _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    _isGameRunning = true;
    _gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        _game.update();
      });
    });
  }

  void _stopTimer() {
    _gameTimer?.cancel();
    _isGameRunning = false;
  }

  void _handleKeyPress(LogicalKeyboardKey key) {
    if (_game.gameState != GameState.playing) return;

    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        _game.changeDirection(Direction.up);
        break;
      case LogicalKeyboardKey.arrowDown:
        _game.changeDirection(Direction.down);
        break;
      case LogicalKeyboardKey.arrowLeft:
        _game.changeDirection(Direction.left);
        break;
      case LogicalKeyboardKey.arrowRight:
        _game.changeDirection(Direction.right);
        break;
      case LogicalKeyboardKey.space:
        if (_game.gameState == GameState.playing) {
          _pauseGame();
        } else if (_game.gameState == GameState.paused) {
          _startGame();
        }
        break;
      default:
        break;
    }
  }

  void _handleSwipe(DragUpdateDetails details) {
    if (_game.gameState != GameState.playing) return;
    
    if (_lastPanPosition == null) {
      _lastPanPosition = details.globalPosition;
      return;
    }

    final delta = details.globalPosition - _lastPanPosition!;
    final threshold = 50.0; // Minimum distance for a swipe

    if (delta.distance > threshold) {
      if (delta.dx.abs() > delta.dy.abs()) {
        // Horizontal swipe
        if (delta.dx > 0) {
          _game.changeDirection(Direction.right);
        } else {
          _game.changeDirection(Direction.left);
        }
      } else {
        // Vertical swipe
        if (delta.dy > 0) {
          _game.changeDirection(Direction.down);
        } else {
          _game.changeDirection(Direction.up);
        }
      }
      _lastPanPosition = null; // Reset to prevent multiple direction changes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake Game'),
        backgroundColor: AppTheme.metroGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isGameRunning ? Icons.pause : Icons.play_arrow),
            onPressed: _isGameRunning ? _pauseGame : _startGame,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            _handleKeyPress(event.logicalKey);
          }
          return KeyEventResult.handled;
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.metroGreen.withOpacity(0.1),
                AppTheme.metroBlue.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildScoreBoard(),
              Expanded(
                child: Center(
                  child: _buildGameBoard(),
                ),
              ),
              _buildControls(),
              _buildGameStatus(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard('Score', _game.score.toString(), AppTheme.metroBlue),
          _buildScoreCard('High Score', _game.highScore.toString(), AppTheme.metroRed),
          _buildScoreCard('Length', _game.snake.length.toString(), AppTheme.metroGreen),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onPanUpdate: _handleSwipe,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[50]!,
                  Colors.green[100]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[300]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: SnakeGame.boardWidth,
                  childAspectRatio: 1,
                ),
                itemCount: SnakeGame.boardWidth * SnakeGame.boardHeight,
                itemBuilder: (context, index) {
                  final x = index % SnakeGame.boardWidth;
                  final y = index ~/ SnakeGame.boardWidth;
                  final position = Position(x, y);

                  return _buildGameCell(position);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCell(Position position) {
    Color cellColor = Colors.green[50]!;
    Widget? cellContent;

    if (_game.isSnakePosition(position)) {
      final isHead = _game.snakeHead == position;
      cellColor = isHead ? Colors.green[600]! : Colors.green[400]!;
      cellContent = Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isHead ? Icons.circle : Icons.circle_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      );
    } else if (_game.isFoodPosition(position)) {
      cellColor = Colors.red[500]!;
      cellContent = Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.star,
            color: Colors.white,
            size: 18,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: cellContent,
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Touch instruction
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[100]!, Colors.green[50]!],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[300]!, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe to Control',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Swipe on the game board to move the snake',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  _isGameRunning ? 'Pause' : 'Play',
                  _isGameRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  _isGameRunning ? _pauseGame : _startGame,
                  _isGameRunning ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Restart',
                  Icons.refresh,
                  _restartGame,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.metroGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppTheme.metroGreen.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          color: AppTheme.metroGreen,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildGameStatus() {
    if (_game.gameState == GameState.gameOver) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: AppTheme.metroRed.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.sentiment_very_dissatisfied,
                  size: 48,
                  color: AppTheme.metroRed,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Game Over!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.metroRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Final Score: ${_game.score}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _restartGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.metroRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Play Again'),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_game.gameState == GameState.paused) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: AppTheme.metroBlue.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.pause_circle_outline,
                  size: 48,
                  color: AppTheme.metroBlue,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Game Paused',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.metroBlue,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.metroBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Resume'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
