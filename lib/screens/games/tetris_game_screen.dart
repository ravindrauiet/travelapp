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
          child: Row(
            children: [
              // Game board
              Expanded(
                flex: 3,
                child: _buildGameBoard(),
              ),
              // Side panel
              Expanded(
                flex: 1,
                child: _buildSidePanel(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: AspectRatio(
          aspectRatio: TetrisGame.boardWidth / TetrisGame.boardHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
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
    );
  }

  Widget _buildGameCell(TetrisPosition position) {
    final color = _game.getPositionColor(position);
    
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(2),
        border: color != null 
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 0.5)
            : null,
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
          _buildScoreItem('Score', _game.score.toString(), AppTheme.metroBlue),
          const SizedBox(height: 8),
          _buildScoreItem('High Score', _game.highScore.toString(), AppTheme.metroRed),
          const SizedBox(height: 8),
          _buildScoreItem('Level', _game.level.toString(), AppTheme.metroGreen),
          const SizedBox(height: 8),
          _buildScoreItem('Lines', _game.linesCleared.toString(), AppTheme.metroOrange),
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
            'Controls',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildControlRow('← →', 'Move'),
          _buildControlRow('↓', 'Soft Drop'),
          _buildControlRow('↑', 'Rotate'),
          _buildControlRow('Space', 'Hard Drop'),
          _buildControlRow('P', 'Pause'),
        ],
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
