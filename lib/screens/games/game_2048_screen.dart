import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_2048.dart';
import '../../widgets/game_bottom_navigation.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048 Game'),
        backgroundColor: AppTheme.metroBlue,
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
                AppTheme.metroBlue.withOpacity(0.1),
                AppTheme.metroPurple.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              // Score board at top
              _buildScoreBoard(),
              // Game board in center
              Expanded(
                child: _buildGameBoard(),
              ),
              // Controls at bottom
              _buildControls(),
              // Game status
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.red[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard('Score', _game.score.toString(), Colors.orange),
          _buildScoreCard('Best', _game.bestScore.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Touch instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[100]!, Colors.red[100]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[300]!, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.orange[600], size: 16),
                const SizedBox(width: 6),
                Text(
                  'Swipe to move tiles',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          shadowColor: color.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildGameStatus() {
    if (_game.gameState == Game2048State.gameOver) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!, width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.sentiment_very_dissatisfied, color: Colors.red[600], size: 48),
            const SizedBox(height: 8),
            Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: ${_game.score}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      );
    } else if (_game.gameState == Game2048State.won) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[300]!, width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.celebration, color: Colors.green[600], size: 48),
            const SizedBox(height: 8),
            Text(
              'You Win!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reached 2048!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
