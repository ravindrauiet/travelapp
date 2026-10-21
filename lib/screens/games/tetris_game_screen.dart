import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tetris_game.dart';
import '../../utils/app_theme.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'game_chrome.dart';

class TetrisGameScreen extends StatefulWidget {
  const TetrisGameScreen({super.key});

  @override
  State<TetrisGameScreen> createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends State<TetrisGameScreen> {
  late TetrisGame _game;
  Timer? _gameTimer;
  bool _isGameRunning = false;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _game = TetrisGame();
    _game.initialize();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    if (_game.gameState == TetrisGameState.gameOver) {
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
    _gameTimer = Timer.periodic(Duration(milliseconds: _game.dropSpeed), (timer) {
      setState(() {
        _game.moveDown();
      });
    });
  }

  void _stopTimer() {
    _gameTimer?.cancel();
    _isGameRunning = false;
  }

  void _handleKeyPress(LogicalKeyboardKey key) {
    if (_game.gameState != TetrisGameState.playing) return;

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        _game.moveLeft();
        break;
      case LogicalKeyboardKey.arrowRight:
        _game.moveRight();
        break;
      case LogicalKeyboardKey.arrowDown:
        _game.moveDown();
        break;
      case LogicalKeyboardKey.arrowUp:
        _game.rotate();
        break;
      case LogicalKeyboardKey.space:
        _game.drop();
        break;
      case LogicalKeyboardKey.keyP:
        if (_game.gameState == TetrisGameState.playing) {
          _pauseGame();
        } else if (_game.gameState == TetrisGameState.paused) {
          _startGame();
        }
        break;
      default:
        break;
    }
  }

  void _handleSwipe(DragUpdateDetails details) {
    if (_game.gameState != TetrisGameState.playing) return;
    
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
          _game.moveRight();
        } else {
          _game.moveLeft();
        }
      } else {
        // Vertical swipe
        if (delta.dy > 0) {
          _game.moveDown();
        } else {
          _game.rotate();
        }
      }
      _lastPanPosition = null; // Reset to prevent multiple actions
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final showStatus = _game.gameState == TetrisGameState.gameOver ||
        _game.gameState == TetrisGameState.paused;
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
              // Score board at top
              _buildScoreBoard(),
              // Game board in center - takes most space
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildGameBoard()),
                    if (showStatus) GameOverlay(child: _buildGameStatus()),
                  ],
                ),
              ),
              // Controls at bottom
              _buildControls(),
            ],
          ),
        ),
        bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
      ),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: AspectRatio(
          aspectRatio: TetrisGame.boardWidth / TetrisGame.boardHeight,
          child: GestureDetector(
            onPanUpdate: _handleSwipe,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[900]!,
                    Colors.purple[900]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[300]!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
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
                    crossAxisCount: TetrisGame.boardWidth,
                    childAspectRatio: 1,
                  ),
                  itemCount: TetrisGame.boardWidth * TetrisGame.boardHeight,
                  itemBuilder: (context, index) {
                    final x = index % TetrisGame.boardWidth;
                    final y = index ~/ TetrisGame.boardWidth;
                    final position = TetrisPosition(x, y);

                    return _buildGameCell(position);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCell(TetrisPosition position) {
    final color = _game.getPositionColor(position);
    
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        border: color != null 
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
        boxShadow: color != null ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
    );
  }

  Widget _buildScoreBoard() {
    return GameHeader(
      title: 'Block Drop',
      gradient: AppTheme.transitGradient,
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
        GameStat('Level', _game.level.toString(), Icons.trending_up_rounded),
        GameStat('Lines', _game.linesCleared.toString(), Icons.view_headline_rounded),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Touch instruction - compact
          const GameHintBar(
            icon: Icons.swipe_rounded,
            text: 'Swipe to move • swipe up to rotate',
            color: AppTheme.metroBlue,
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
                  _isGameRunning ? GamesPalette.amber : AppTheme.transitGradient,
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
    if (_game.gameState == TetrisGameState.gameOver) {
      return GameStatusCard(
        icon: Icons.sentiment_very_dissatisfied_rounded,
        title: 'Game Over!',
        lines: ['Final Score: ${_game.score}'],
        color: AppTheme.errorColor,
        actionLabel: 'Play Again',
        actionIcon: Icons.replay_rounded,
        onAction: _restartGame,
      );
    } else if (_game.gameState == TetrisGameState.paused) {
      return GameStatusCard(
        icon: Icons.pause_rounded,
        title: 'Game Paused',
        color: AppTheme.metroBlue,
        actionLabel: 'Resume',
        actionIcon: Icons.play_arrow_rounded,
        onAction: _startGame,
        actionGradient: AppTheme.transitGradient,
      );
    }

    return const SizedBox.shrink();
  }
}
