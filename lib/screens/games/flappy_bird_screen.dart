import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/flappy_bird.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../utils/app_theme.dart';

class FlappyBirdScreen extends StatefulWidget {
  const FlappyBirdScreen({super.key});

  @override
  State<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends State<FlappyBirdScreen> with TickerProviderStateMixin {
  late FlappyBird _game;
  late Timer _gameTimer;
  bool _isGameRunning = false;

  @override
  void initState() {
    super.initState();
    _game = FlappyBird();
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameRunning = true;
      _game.resume();
    });
    _startGameLoop();
  }

  void _pauseGame() {
    setState(() {
      _isGameRunning = false;
      _game.pause();
    });
    _gameTimer.cancel();
  }

  void _restartGame() {
    setState(() {
      _game.restart();
      _isGameRunning = false;
    });
    _gameTimer.cancel();
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        _game.update();
      });
    });
  }

  void _handleTap() {
    if (_game.gameState == FlappyBirdState.playing) {
      _game.jump();
    } else if (_game.gameState == FlappyBirdState.gameOver) {
      _restartGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flappy Bird'),
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
      body: GestureDetector(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[300]!,
                Colors.blue[100]!,
              ],
            ),
          ),
          child: Column(
            children: [
              // Score board at top
              _buildScoreBoard(),
              // Game area
              Expanded(
                child: _buildGameArea(),
              ),
              // Controls at bottom
              _buildControls(),
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
          colors: [Colors.green[50]!, Colors.blue[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard('Score', _game.score.toString(), Colors.green),
          _buildScoreCard('Best', _game.bestScore.toString(), Colors.blue),
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

  Widget _buildGameArea() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue[300]!,
                  Colors.blue[100]!,
                ],
              ),
            ),
          ),
          // Pipes
          ..._game.pipes.map((pipe) => _buildPipe(pipe)),
          // Bird
          _buildBird(),
          // Game over overlay
          if (_game.gameState == FlappyBirdState.gameOver) _buildGameOverOverlay(),
          // Start screen
          if (_game.gameState == FlappyBirdState.playing && !_isGameRunning) _buildStartScreen(),
        ],
      ),
    );
  }

  Widget _buildPipe(Pipe pipe) {
    return Stack(
      children: [
        // Top pipe
        Positioned(
          left: pipe.x,
          top: 0,
          child: Container(
            width: FlappyBird.pipeWidth,
            height: pipe.topHeight,
            decoration: BoxDecoration(
              color: Colors.green[600],
              border: Border.all(color: Colors.green[800]!, width: 2),
            ),
          ),
        ),
        // Bottom pipe
        Positioned(
          left: pipe.x,
          top: pipe.topHeight + FlappyBird.pipeGap,
          child: Container(
            width: FlappyBird.pipeWidth,
            height: 600 - (pipe.topHeight + FlappyBird.pipeGap),
            decoration: BoxDecoration(
              color: Colors.green[600],
              border: Border.all(color: Colors.green[800]!, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBird() {
    return Positioned(
      left: 100,
      top: _game.birdY,
      child: Container(
        width: FlappyBird.birdSize,
        height: FlappyBird.birdSize,
        decoration: BoxDecoration(
          color: Colors.yellow[600],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange[800]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.pets,
          color: Colors.orange[800],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to Start',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to make the bird fly!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_very_dissatisfied,
              color: Colors.red[400],
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Game Over!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${_game.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to restart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
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
                colors: [Colors.green[100]!, Colors.blue[100]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[300]!, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.green[600], size: 16),
                const SizedBox(width: 6),
                Text(
                  'Tap to make bird fly',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
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
}
