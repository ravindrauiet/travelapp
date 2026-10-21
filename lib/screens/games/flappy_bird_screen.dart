import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/flappy_bird.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'game_chrome.dart';
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
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(
          children: [
            // Score board at top
            _buildScoreBoard(),
            Expanded(
              child: GestureDetector(
                onTap: _handleTap,
                child: Column(
                  children: [
                    // Game area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _buildGameArea(),
                        ),
                      ),
                    ),
                    // Controls at bottom
                    _buildControls(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return GameHeader(
      title: 'Sky Hopper',
      gradient: AppTheme.oceanGradient,
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
      color: AppTheme.brandNight.withValues(alpha: 0.45),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: AppTheme.oceanGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                  boxShadow: AppTheme.glow(AppTheme.metroAqua, alpha: 0.45),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap to Start',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to make the bird fly!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: AppTheme.brandNight.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: GameStatusCard(
            icon: Icons.sentiment_very_dissatisfied_rounded,
            title: 'Game Over!',
            lines: ['Score: ${_game.score}', 'Tap to restart'],
            color: AppTheme.errorColor,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Touch instruction
          const GameHintBar(
            icon: Icons.touch_app_rounded,
            text: 'Tap to make bird fly',
            color: AppTheme.infoColor,
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
                  _isGameRunning ? GamesPalette.amber : AppTheme.oceanGradient,
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
}
