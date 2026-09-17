# Mascot Guide — أبطال المذاكرة

The app mascot is an energetic orange owl with 13 poses. Each pose maps to a
specific learning moment so the character always reacts consistently.

**Usage in code:**

```dart
import '../widgets/mascot.dart';

const Mascot(pose: MascotPose.jump, size: 64)
```

---

## Pose Reference

| Pose | Enum | File | Description | Best Use |
|------|------|------|-------------|----------|
| Cheering | `MascotPose.cheer` | `cheer.png` | Cheering while holding a heart fan | Quiz complete, lesson complete, streak milestones |
| Starstruck | `MascotPose.starstruck` | `starstruck.png` | Starry-eyed, hands on face | Correct answers (big moments), achievements, XP popups |
| Panic Skating | `MascotPose.panicSkate` | `panic_skate.png` | Panicking on roller skates | Wrong answer (funny tone), timer running out |
| Determined | `MascotPose.determined` | `determined.png` | Skating hard, tongue out | Hard-mode challenges, streak pushes, "keep going" moments |
| Sleepy | `MascotPose.sleepy` | `sleepy.png` | Sleepy / unimpressed | Idle states, "come back tomorrow", streak-lost nudges |
| Panic Running | `MascotPose.panicRun` | `panic_run.png` | Running in a panic | Wrong answer, weekly-competition urgency |
| Jumping | `MascotPose.jump` | `jump.png` | Jumping excited | Correct answers, small wins |
| Celebrating | `MascotPose.celebrate` | `celebrate.png` | Surprised with confetti | Unit exercise complete, level-up, league promotion |
| Shy Wave | `MascotPose.shyWave` | `shy_wave.png` | Shy waving hello | Onboarding, signup/login screens |
| Excited Wave | `MascotPose.wave` | `wave.png` | Excited waving | Welcome screen, lesson start, greetings |
| Sad | `MascotPose.sad` | `sad.png` | Crying, teary-eyed | Wrong-answer feedback (empathetic tone), hearts depleted |
| Studying | `MascotPose.study` | `study.png` | Taking notes with pencil | Lesson summaries, tips, "نقاط مهمة" sections |
| In Love | `MascotPose.love` | `love.png` | In love with floating hearts | Shop, favorites, rewards, "لقد فهمت الدرس" praise |

---

## Current Integration Map

| Screen / Moment | Pose | Status |
|-----------------|------|--------|
| Welcome screen hero | `wave` | Done |
| Quiz feedback bar — correct | `jump` | Done |
| Quiz feedback bar — wrong | `sad` | Done |
| Lesson summary tab ("محتوى الدرس") | `study` | Done |
| Lesson quiz tab ("ابدأ التمرين") | `determined` | Done |
| Unit exercise screen hero | `celebrate` | Done |
| Lesson-complete dialog | `cheer` | Done |
| Unit-complete dialog | `celebrate` | Done |
| Signup screen | `shyWave` | Done |
| Login screen | `shyWave` | Done |

## Suggested Next Integrations

| Screen / Moment | Pose |
|-----------------|------|
| Achievements screen header | `starstruck` |
| Shop screen | `love` |
| Streak-lost / return-tomorrow prompt | `sleepy` |
| Weekly competition banner | `panicRun` |

---

## Tone Rules

1. **Celebrate big, empathize small** — use `celebrate`/`cheer` for milestones,
   `sad` (not `panic*`) when the user fails, so failure feels gentle.
2. **One mascot moment per screen** — the character should react to *the* key
   action, not decorate everything.
3. **Keep reactions consistent** — correct answers are always `jump`-family,
   wrong answers always `sad`/`panic`-family. Never swap tones between screens.
