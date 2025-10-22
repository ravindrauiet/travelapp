import 'dart:math';
import 'dart:ui';

enum FlappyBirdState { playing, gameOver, paused }

class FlappyBird {
  static const double gravity = 0.6;
  static const double jumpStrength = -12.0;
  static const double pipeWidth = 80.0;
  static const double pipeGap = 200.0;
  static const double pipeSpeed = 3.0;
  static const double birdSize = 30.0;

  late double birdY;
  late double birdVelocity;
  late List<Pipe> pipes;
  late int score;
  int bestScore = 0;
  late FlappyBirdState gameState;
  late double gameSpeed;

  FlappyBird() {
    initialize();
  }

  void initialize() {
    birdY = 300.0;
    birdVelocity = 0.0;
    pipes = [];
    score = 0;
    gameState = FlappyBirdState.playing;
    gameSpeed = pipeSpeed;
    _addPipe();
  }

  void jump() {
    if (gameState == FlappyBirdState.playing) {
      birdVelocity = jumpStrength;
    }
  }

  void update() {
    if (gameState != FlappyBirdState.playing) return;

    // Update bird physics
    birdVelocity += gravity;
    birdY += birdVelocity;

    // Update pipes
    for (int i = pipes.length - 1; i >= 0; i--) {
      pipes[i].x -= gameSpeed;
      
      // Check if bird passed pipe
      if (!pipes[i].scored && pipes[i].x + pipeWidth < 100) {
        pipes[i].scored = true;
        score++;
        gameSpeed += 0.1; // Increase speed slightly
      }
      
      // Remove pipes that are off screen
      if (pipes[i].x + pipeWidth < 0) {
        pipes.removeAt(i);
      }
    }

    // Add new pipes
    if (pipes.isEmpty || pipes.last.x < 400) {
      _addPipe();
    }

    // Check collisions
    _checkCollisions();
  }

  void _addPipe() {
    final random = Random();
    final pipeHeight = 100 + random.nextInt(200).toDouble();
    pipes.add(Pipe(400, pipeHeight));
  }

  void _checkCollisions() {
    // Check ground and ceiling collision
    if (birdY > 600 - birdSize || birdY < 0) {
      gameState = FlappyBirdState.gameOver;
      return;
    }

    // Check pipe collisions
    for (final pipe in pipes) {
      if (100 < pipe.x + pipeWidth && 100 + birdSize > pipe.x) {
        if (birdY < pipe.topHeight || birdY + birdSize > pipe.topHeight + pipeGap) {
          gameState = FlappyBirdState.gameOver;
          return;
        }
      }
    }
  }

  void pause() {
    if (gameState == FlappyBirdState.playing) {
      gameState = FlappyBirdState.paused;
    }
  }

  void resume() {
    if (gameState == FlappyBirdState.paused) {
      gameState = FlappyBirdState.playing;
    }
  }

  void restart() {
    initialize();
  }
}

class Pipe {
  double x;
  double topHeight;
  bool scored;

  Pipe(this.x, this.topHeight) : scored = false;
}
