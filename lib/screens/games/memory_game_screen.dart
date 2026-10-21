import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/memory_game.dart';
import '../../widgets/game_bottom_navigation.dart';
import '../../widgets/ui_kit.dart';
import 'game_chrome.dart';
import '../../utils/app_theme.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late MemoryGame _game;

  @override
  void initState() {
    super.initState();
    _game = MemoryGame();
  }

  void _restartGame() {
    setState(() {
      _game.restart();
    });
  }

  void _flipCard(int index) {
    setState(() {
      _game.flipCard(index);
    });
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
            // Game board in center
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildGameBoard()),
                  if (_game.gameState == MemoryGameState.won) GameOverlay(child: _buildGameStatus()),
                ],
              ),
            ),
            // Controls at bottom
            _buildControls(),
          ],
        ),
        bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return GameHeader(
      title: 'Memory Game',
      gradient: AppTheme.sunsetGradient,
      actions: [
        HeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Restart',
          onTap: _restartGame,
        ),
      ],
      stats: [
        GameStat('Score', _game.score.toString(), Icons.star_rounded),
        GameStat('Moves', _game.moves.toString(), Icons.touch_app_rounded),
        GameStat('Pairs', '${_game.pairsFound}/${_game.totalPairs}', Icons.style_rounded),
      ],
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _game.cards.length,
            itemBuilder: (context, index) {
              return _buildMemoryCard(index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryCard(int index) {
    final card = _game.cards[index];
    
    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _game.getCardColor(card),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isMatched ? Colors.green[600]! : Colors.grey[600]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: card.isFlipped || card.isMatched
                ? Text(
                    card.emoji,
                    key: ValueKey('${card.id}_flipped'),
                    style: const TextStyle(fontSize: 32),
                  )
                : Container(
                    key: ValueKey('${card.id}_back'),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
          ),
        ),
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
            icon: Icons.touch_app_rounded,
            text: 'Tap cards to find matching pairs',
            color: AppTheme.brandRose,
          ),
          const SizedBox(height: 12),
          // Action button
          _buildActionButton(
            'Restart Game',
            Icons.refresh_rounded,
            _restartGame,
            AppTheme.sunsetGradient,
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
    if (_game.gameState == MemoryGameState.won) {
      return GameStatusCard(
        icon: Icons.celebration_rounded,
        title: 'Congratulations!',
        lines: [
          'You found all pairs in ${_game.moves} moves!',
          'Final Score: ${_game.score}',
        ],
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
