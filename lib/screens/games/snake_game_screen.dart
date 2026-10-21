import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/snake_game.dart';
import '../../utils/app_theme.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'game_chrome.dart';

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
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.background,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              _handleKeyPress(event.logicalKey);
            }
            return KeyEventResult.handled;
          },
          child: Column(
            children: [
              _buildScoreBoard(),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: _buildGameBoard(),
                    ),
                    if (_game.gameState == GameState.gameOver || _game.gameState == GameState.paused)
                      GameOverlay(child: _buildGameStatus()),
                  ],
                ),
              ),
              _buildControls(),
            ],
          ),
        ),
        bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return GameHeader(
      title: 'Snake Game',
      gradient: AppTheme.emeraldGradient,
      actions: [
        HeaderIconButton(
          icon: _isGameRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          tooltip: _isGameRunning ? 'Pause' : 'Play',
          onTap: _isGameRunning ? _pauseGame : _startGame,
        ),
        HeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Restart',
          onTap: _restartGame,
        ),
      ],
      stats: [
        GameStat('Score', _game.score.toString(), Icons.star_rounded),
        GameStat('Best', _game.highScore.toString(), Icons.emoji_events_rounded),
        GameStat('Length', _game.snake.length.toString(), Icons.straighten_rounded),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Touch instruction
          const GameHintBar(
            icon: Icons.swipe_rounded,
            text: 'Swipe on the game board to move the snake',
            color: AppTheme.metroGreen,
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  _isGameRunning ? 'Pause' : 'Play',
                  _isGameRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                  _isGameRunning ? _pauseGame : _startGame,
                  _isGameRunning ? GamesPalette.amber : AppTheme.emeraldGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Restart',
                  Icons.refresh_rounded,
                  _restartGame,
                  AppTheme.sunsetGradient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, LinearGradient gradient) {
    return GradientButton(
      label: text,
      icon: icon,
      onPressed: onPressed,
      gradient: gradient,
    );
  }

  Widget _buildGameStatus() {
    if (_game.gameState == GameState.gameOver) {
      return GameStatusCard(
        icon: Icons.sentiment_very_dissatisfied_rounded,
        title: 'Game Over!',
        lines: ['Final Score: ${_game.score}'],
        color: AppTheme.errorColor,
        actionLabel: 'Play Again',
        actionIcon: Icons.replay_rounded,
        onAction: _restartGame,
      );
    } else if (_game.gameState == GameState.paused) {
      return GameStatusCard(
        icon: Icons.pause_rounded,
        title: 'Game Paused',
        color: AppTheme.metroGreen,
        actionLabel: 'Resume',
        actionIcon: Icons.play_arrow_rounded,
        onAction: _startGame,
        actionGradient: AppTheme.emeraldGradient,
      );
    }

    return const SizedBox.shrink();
  }
}
