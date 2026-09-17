import 'package:flutter/material.dart';

/// The app mascot — an energetic owl character with a pose for every moment.
enum MascotPose {
  cheer,      // (1) cheering with heart fan — quiz/lesson complete
  starstruck, // (2) starry-eyed amazed — correct answers, achievements
  panicSkate, // (3) panicking on roller skates — wrong answer (funny)
  determined, // (4) skating hard — streak push / hard mode
  sleepy,     // (5) sleepy — idle / come-back nudge
  panicRun,   // (6) running panicked — wrong answer / time pressure
  jump,       // (7) jumping excited — correct answer
  celebrate,  // (8) confetti surprise — unit exercise / level-up
  shyWave,    // (9) shy wave — onboarding
  wave,       // (10) excited wave — welcome / lesson start
  sad,        // (11) crying sad — wrong answer empathy
  study,      // (12) taking notes — summary / study content
  love,       // (13) in love — favorites / rewards
}

class Mascot extends StatelessWidget {
  final MascotPose pose;
  final double size;

  const Mascot({super.key, required this.pose, this.size = 96});

  static const _assets = <MascotPose, String>{
    MascotPose.cheer: 'assets/character/cheer.png',
    MascotPose.starstruck: 'assets/character/starstruck.png',
    MascotPose.panicSkate: 'assets/character/panic_skate.png',
    MascotPose.determined: 'assets/character/determined.png',
    MascotPose.sleepy: 'assets/character/sleepy.png',
    MascotPose.panicRun: 'assets/character/panic_run.png',
    MascotPose.jump: 'assets/character/jump.png',
    MascotPose.celebrate: 'assets/character/celebrate.png',
    MascotPose.shyWave: 'assets/character/shy_wave.png',
    MascotPose.wave: 'assets/character/wave.png',
    MascotPose.sad: 'assets/character/sad.png',
    MascotPose.study: 'assets/character/study.png',
    MascotPose.love: 'assets/character/love.png',
  };

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assets[pose]!,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
