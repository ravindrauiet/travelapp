import 'package:flutter/material.dart';
import '../../models/memory_game.dart';
import '../../widgets/game_bottom_navigation.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        backgroundColor: AppTheme.metroBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
          ),
        ],
      ),
      body: Container(
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
      bottomNavigationBar: const GameBottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.pink[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard('Score', _game.score.toString(), Colors.purple),
          _buildScoreCard('Moves', _game.moves.toString(), Colors.pink),
          _buildScoreCard('Pairs', '${_game.pairsFound}/${_game.totalPairs}', Colors.green),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Touch instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[100]!, Colors.pink[100]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[300]!, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.purple[600], size: 16),
                const SizedBox(width: 6),
                Text(
                  'Tap cards to find matching pairs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action button
          _buildActionButton(
            'Restart Game',
            Icons.refresh,
            _restartGame,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      height: 40,
      width: double.infinity,
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
    if (_game.gameState == MemoryGameState.won) {
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
              'Congratulations!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You found all pairs in ${_game.moves} moves!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: ${_game.score}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
