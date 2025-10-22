import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tetris_game.dart';
import '../../utils/app_theme.dart';
import '../../widgets/game_bottom_navigation.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetris Game'),
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
                AppTheme.metroMagenta.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              // Score board at top
              _buildScoreBoard(),
              // Game board in center - takes most space
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
            color: color!.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildScoreBoard(),
          const SizedBox(height: 20),
          _buildNextPiece(),
          const SizedBox(height: 20),
          _buildControls(),
          const Spacer(),
          _buildGameStatus(),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard('Score', _game.score.toString(), Colors.blue),
          _buildScoreCard('Level', _game.level.toString(), Colors.purple),
          _buildScoreCard('Lines', _game.linesCleared.toString(), Colors.green),
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

  Widget _buildScoreItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNextPiece() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Next Piece',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          if (_game.nextPiece != null)
            _buildPiecePreview(_game.nextPiece!)
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPiecePreview(TetrisPiece piece) {
    return Container(
      width: 60,
      height: 60,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          final x = index % 4;
          final y = index ~/ 4;
          
          if (y < piece.shape.length && x < piece.shape[y].length && piece.shape[y][x] == 1) {
            return Container(
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                color: piece.color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
              ),
            );
          }
          
          return Container();
        },
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Touch instruction - compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[100]!, Colors.purple[100]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.blue[600], size: 16),
                const SizedBox(width: 6),
                Text(
                  'Swipe to control pieces',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
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
                  _isGameRunning ? Colors.orange : Colors.blue,
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

  Widget _buildControlRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.metroBlue,
            ),
          ),
          Text(
            action,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatus() {
    if (_game.gameState == TetrisGameState.gameOver) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.metroRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.metroRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: ${_game.score}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
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
      );
    } else if (_game.gameState == TetrisGameState.paused) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.metroBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.metroBlue,
              ),
            ),
            const SizedBox(height: 12),
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
      );
    }

    return const SizedBox.shrink();
  }
}
