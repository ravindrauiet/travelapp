import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_2048.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'game_chrome.dart';
import '../../utils/app_theme.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  late Game2048 _game;
  bool _isGameRunning = false;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _game = Game2048();
  }

  void _startGame() {
    setState(() {
      _isGameRunning = true;
    });
  }

  void _pauseGame() {
    setState(() {
      _isGameRunning = false;
    });
  }

  void _restartGame() {
    setState(() {
      _game.restart();
      _isGameRunning = false;
    });
  }

  void _handleKeyPress(LogicalKeyboardKey key) {
    if (_game.gameState != Game2048State.playing) return;

    bool moved = false;
    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        moved = _game.moveLeft();
        break;
      case LogicalKeyboardKey.arrowRight:
        moved = _game.moveRight();
        break;
      case LogicalKeyboardKey.arrowUp:
        moved = _game.moveUp();
        break;
      case LogicalKeyboardKey.arrowDown:
        moved = _game.moveDown();
        break;
      default:
        break;
    }

    if (moved) {
      setState(() {});
    }
  }

  void _handleSwipe(DragUpdateDetails details) {
    if (_game.gameState != Game2048State.playing) return;
    
    if (_lastPanPosition == null) {
      _lastPanPosition = details.globalPosition;
      return;
    }

    final delta = details.globalPosition - _lastPanPosition!;
    final threshold = 50.0;

    if (delta.distance > threshold) {
      bool moved = false;
      if (delta.dx.abs() > delta.dy.abs()) {
        // Horizontal swipe
        if (delta.dx > 0) {
          moved = _game.moveRight();
        } else {
          moved = _game.moveLeft();
        }
      } else {
        // Vertical swipe
        if (delta.dy > 0) {
          moved = _game.moveDown();
        } else {
          moved = _game.moveUp();
        }
      }
      
      if (moved) {
        setState(() {});
        _lastPanPosition = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final showStatus = _game.gameState == Game2048State.gameOver ||
        _game.gameState == Game2048State.won;
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
              // Game board in center
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

  Widget _buildScoreBoard() {
    return GameHeader(
      title: '2048',
      gradient: GamesPalette.amber,
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
        GameStat('Best', _game.bestScore.toString(), Icons.emoji_events_rounded),
      ],
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
            onPanUpdate: _handleSwipe,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFBBADA0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[300]!, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
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
                    crossAxisCount: Game2048.boardSize,
                    childAspectRatio: 1,
                  ),
                  itemCount: Game2048.boardSize * Game2048.boardSize,
                  itemBuilder: (context, index) {
                    final x = index % Game2048.boardSize;
                    final y = index ~/ Game2048.boardSize;
                    final value = _game.board[y][x];

                    return _buildGameCell(value);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCell(int value) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _game.getTileColor(value),
        borderRadius: BorderRadius.circular(6),
        boxShadow: value != 0 ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: value != 0
            ? Text(
                value.toString(),
                style: TextStyle(
                  fontSize: value < 100 ? 24 : value < 1000 ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: _game.getTextColor(value),
                ),
              )
            : null,
      ),
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
            text: 'Swipe to move tiles',
            color: AppTheme.metroOrange,
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
    if (_game.gameState == Game2048State.gameOver) {
      return GameStatusCard(
        icon: Icons.sentiment_very_dissatisfied_rounded,
        title: 'Game Over!',
        lines: ['Final Score: ${_game.score}'],
        color: AppTheme.errorColor,
        actionLabel: 'Restart',
        actionIcon: Icons.replay_rounded,
        onAction: _restartGame,
      );
    } else if (_game.gameState == Game2048State.won) {
      return GameStatusCard(
        icon: Icons.celebration_rounded,
        title: 'You Win!',
        lines: const ['You reached 2048!'],
        color: AppTheme.successColor,
        actionLabel: 'Play Again',
        actionIcon: Icons.replay_rounded,
        onAction: _restartGame,
        actionGradient: AppTheme.emeraldGradient,
      );
    }
    return const SizedBox.shrink();
  }
}
