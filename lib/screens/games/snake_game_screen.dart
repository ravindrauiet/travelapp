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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
      padding: const EdgeInsets.all(20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildGameCell(Position position) {
    Color cellColor = Colors.grey[200]!;
    Widget? cellContent;

    if (_game.isSnakePosition(position)) {
      final isHead = _game.snakeHead == position;
      cellColor = isHead ? AppTheme.metroGreen : AppTheme.metroGreen.withOpacity(0.7);
      cellContent = Icon(
        isHead ? Icons.circle : Icons.circle_outlined,
        color: Colors.white,
        size: 16,
      );
    } else if (_game.isFoodPosition(position)) {
      cellColor = AppTheme.metroRed;
      cellContent = const Icon(
        Icons.star,
        color: Colors.white,
        size: 16,
      );
    }

    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(child: cellContent),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Controls',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.keyboard_arrow_up, () {
                _game.changeDirection(Direction.up);
              }),
              const SizedBox(width: 8),
              _buildControlButton(Icons.keyboard_arrow_left, () {
                _game.changeDirection(Direction.left);
              }),
              const SizedBox(width: 8),
              _buildControlButton(Icons.keyboard_arrow_down, () {
                _game.changeDirection(Direction.down);
              }),
              const SizedBox(width: 8),
              _buildControlButton(Icons.keyboard_arrow_right, () {
                _game.changeDirection(Direction.right);
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                _isGameRunning ? 'Pause' : 'Play',
                _isGameRunning ? Icons.pause : Icons.play_arrow,
                _isGameRunning ? _pauseGame : _startGame,
                AppTheme.metroBlue,
              ),
              _buildActionButton(
                'Restart',
                Icons.refresh,
                _restartGame,
                AppTheme.metroRed,
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
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
