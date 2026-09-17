# Haffar — Game System v1.0 Implementation Plan

**Source:** `Haffar — UX Guide & Game System v1.0` PDF (22 slides) + `docs/plan.md` Phases 1-6 audit (2026-09-17)
**Goal:** Implement the full hearts / XP / streak / league / banner game loop and the final UI polish without breaking existing content (9 subjects, 54 lessons, 324+36 questions), auth, or progress persistence.
**Constraints:** No `subscribed` flag exists yet, 10-min heart regeneration must be **server-side**, timer is already tracked (elapsed `DateTime` in `PracticeQuizScreen`), real questions for `technical` will come later — use current ICT copy as placeholder.

> This plan supersedes the missing Phases 4-6 details and adds Phases 7-11 for the PDF. Phases 1-3 are done (1.1-1.8, 2.1-2.5, 3.1-3.4). All tasks are checkboxed subtasks with file/component targets.

---

## 0. Pre-flight & Ground Rules

- [ ] 0.1 Re-run `supabase_get_advisors` (security + performance) after *each* migration — keep RLS strict.
- [ ] 0.2 Migrations via `supabase_apply_migration` only; data fixes via `supabase_execute_sql`.
- [ ] 0.3 Keep existing Supabase project `qfngbhrlqyojfwoadher` — no new project.
- [ ] 0.4 Wire `flutter_svg` to real assets (`heart_small.svg`, `streak_*.svg`, `timer_*.svg`) — stop using `Icons.*` placeholders where PDF requires hearts.
- [ ] 0.5 Add central constants file `lib/utils/game_constants.dart` — single source for `7 / 5 / 5 XP / 18 XP / 100 / 150 / 10 / 15 / 10min` — remove scattered `addXp(3)` / `+10 XP` divergences.
- [ ] 0.6 Verify baseline: `flutter analyze lib/` + manual smoke (home → units → lesson → quiz → leaderboard → profile) passes before branching.

---

## Phase 7 — Hearts & Lives Engine + XP Engine (highest priority, blocks everything)

### 7A. Data model & server truth

- [ ] 7A.1 Migration `create_hearts_and_xp_engine`:
  - `profiles` additions: `is_subscribed BOOL DEFAULT false`, `hearts INT DEFAULT 7 CHECK (0..7)`, `hearts_updated_at TIMESTAMPTZ DEFAULT now()`, `last_lesson_completed_at TIMESTAMPTZ`, `last_streak_date DATE`
  - `heart_events` table: `id UUID PK`, `user_id FK`, `delta INT`, `reason TEXT (lesson_wrong|unit_wrong|regeneration|purchase|reset)`, `created_at`
  - `xp_events` table (from plan 6.1, now required): `id UUID`, `user_id FK`, `amount INT`, `source TEXT (lesson|unit|review|bonus)`, `subject_id TEXT`, `lesson_index INT`, `created_at`, RLS `insert own / select all`, index `user_id, created_at`
  - `weekly_xp` view or function: `SUM(xp_events.amount) WHERE created_at >= saturday 00:00 Africa/Khartoum AND < next saturday`
- [ ] 7A.2 Postgres function `get_hearts(user_id)` — computes regenerated hearts server-side: `elapsed = now() - hearts_updated_at`, `regained = floor(elapsed / 10min)`, `new_hearts = LEAST(7, hearts + regained)`, updates `hearts` + `hearts_updated_at += regained*10min` if regained>0, returns value. Called on every hearts read.
- [ ] 7A.3 Postgres function `consume_heart(user_id, reason)` — calls `get_hearts`, if `hearts==0` return 0, else `hearts-1`, insert `heart_events`, update `profiles`.
- [ ] 7A.4 RLS: `profiles` own-row UPDATE for hearts fields (restrict `is_subscribed` to service_role only if you want; for MVP allow own-row), `heart_events` insert own / select own, `xp_events` insert own / select all (for leaderboard).
- [ ] 7A.5 Seed check: `UPDATE profiles SET hearts=7, hearts_updated_at=now() WHERE hearts IS NULL`

### 7B. Dart — Repositories & Provider

- [ ] 7B.1 `lib/services/hearts_repository.dart` — `getHearts()`, `consumeHeart(reason)`, `refillIfNeeded()`, listens to Supabase RPC `get_hearts`.
- [ ] 7B.2 `lib/services/xp_repository.dart` (or extend `ProgressRepository`) — `addXpEvent(amount, source, subjectId, lessonIndex)` inserts `xp_events` + updates `profiles.xp` aggregate.
- [ ] 7B.3 `lib/providers/app_provider.dart`:
  - Add state `hearts`, `heartsUpdatedAt`, `isSubscribed`, `currentWeekXp` + getters.
  - Replace `addXp(3)` with `addXpEvent(5 or 18, source)` driven by `game_constants`.
  - Add `consumeHeartForWrong({required bool isUnitExam})` → `false` for subscriber lesson exams (infinite), `true` for unit exams (5 cap) and free lesson exams (7 cap).
  - Add `syncHeartsFromServer()` called on `initUserData`, `resume`, and before entering any exam.
  - Add `Ticker` (1-min poll) or `Stream` to refresh hearts countdown in UI.
- [ ] 7B.4 `lib/utils/game_constants.dart`:
  ```dart
  lessonHeartsFree = 7; unitHearts = 5; lessonXpBase = 100; unitXpBase = 150;
  reviewXp = 10; lessonWrongPenalty = 5; unitWrongPenalty = 18;
  unitBonusThreshold = Duration(minutes:2); unitBonusXp = 15;
  heartRegen = Duration(minutes:10);
  ```

### 7C. Lesson exam flow — `lib/screens/practice_quiz_screen.dart` (+ `question_screen.dart` if legacy)

- [ ] 7C.1 On entry: `syncHeartsFromServer()` + gate: if `hearts==0 && !isSubscribed` → show Haffour out-of-hearts dialog `“قلوبك خلصت! ⏱ استنى وارجع”` + countdown `mm:ss` to next heart (10min), button `استنى وارجع` pops. No exam starts.
- [ ] 7C.2 During exam: progress header = `Linear progress + 7❤ pill` (same style as first design). Each wrong: free `hearts--` + `pendingPenalty +=5`, subscriber `pendingPenalty +=5` only. Show heart decrement animation (use `heart_small.svg`).
- [ ] 7C.3 Mid-exam depletion: if free and `hearts` hits 0 **before** answering all questions → immediate fail: cancel quiz, `0 XP`, snackbar/dialog with Haffour, do **not** enter fix phase, return to lesson detail. Subscriber never hits this — always continues.
- [ ] 7C.4 After all questions answered **with remaining hearts** (or subscriber regardless): transition to **Fix Mistakes phase** — full-screen Haffour `“يلا تعال نصلح أخطائك ونظبط الفاتنا!”` + `يلا` button. This phase is **بدون قلوب** (no hearts), **بدون شرح** not needed for MVP. Loop: re-queue only wrong `questionIds`; if wrong again → re-queue at end `→ يكرر`; until all correct.
- [ ] 7C.5 On fix phase complete: `finalXp = base - (initialMistakes × penalty)` (lesson `100-5×n`, unit `150-18×n`, clamp 0). For unit, add bonus `+15` if `elapsed < 2min`. Call `xp_repository.addXpEvent(finalXp)`, `completeSubjectLesson` / `completeUnitExercise`, and `AttemptRepository` save with `correct = total - initialMistakes` (or final correct after fix?). Show `CelebrationDialog` with final XP pill + timer `m:ss` Arabic numerals + streak increment.
- [ ] 7C.6 “Review mistakes” vs “Fix mistakes” distinction: keep existing `“راجع أخطاءك (N)”` button (kind=review, `10 XP`) separate from mandatory fix phase inside the same exam.

### 7D. Unit exam flow — `lib/screens/unit_exercise_screen.dart`

- [ ] 7D.1 Same as 7C but entry hearts = `5` for **both** free and subscribed. Penalty `18` per wrong. Intro card text: `“الخمسه القلوب دي ليك كل غلط هيخسرك قلب حافظ عليهم ، عشان تنجح في الوحدة”`.
- [ ] 7D.2 Depletion during unit exam: if lose all 5 before end → `ينتهي بدون نقاط` + `يعيد من البداية` — full restart, no partial credit.
- [ ] 7D.3 Fix phase identical: `بدون قلوب`, `بدون شرح`, `لو غلط تاني السؤال يرجع`, loop until correct.
- [ ] 7D.4 Final calc + bonus as in 7C.5.

### 7E. Summary / Lesson content — no hearts gate

- [ ] 7E.1 `LessonDetailScreen` summary tab (and any `LessonDetail` content) must be accessible **without hearts** — hearts only gate the `PracticeQuizScreen` entry button. Add guard: `“ابدأ التمرين”` checks hearts; `“لقد فهمت الدرس”` and summary `key_points` never check hearts.
- [ ] 7E.2 If broader request “لو في مجال الدروس تنفتح بدون قلوب اعملو” is interpreted as unlocking next lesson without quiz: **not** recommended — keep `isSubjectLessonUnlocked` logic; document decision.

### 7F. Verification

- [ ] 7F.1 Free user loses 7 hearts mid-lesson → immediate 0 XP dialog appears, countdown ticks.
- [ ] 7F.2 Subscriber makes 7 mistakes in lesson → never blocked, still reaches fix phase.
- [ ] 7F.3 Kill app, wait 20 min → reopen → `get_hearts` returns +2 hearts (server truth, not local).
- [ ] 7F.4 Unit exam with 2 mistakes → final `150-36=114` XP, if elapsed 01:45 → `129` XP.

---

## Phase 8 — Streak (الحماسة) System `🔥`

- [ ] 8.1 Migration additions (if not in 7A): `profiles.last_streak_date DATE`, `profiles.streak INT` already exists — add `streak_freeze_count INT DEFAULT 0` optional, index on `last_streak_date`.
- [ ] 8.2 Server function `update_streak(user_id)` — called after successful lesson/unit completion (not review): if `last_streak_date == CURRENT_DATE` do nothing; else if `== CURRENT_DATE -1` → `streak+1`; else if gap >1 → `streak=1` (first day) ; set `last_streak_date = CURRENT_DATE`. Called from `completeSubjectLesson` trigger or client RPC.
- [ ] 8.3 Client: `AppProvider.completeSubjectLesson` → after DB success → call `update_streak` RPC → hydrate `streak` + `last_streak_date`. Home `🔥 ${streak} يوم` and profile `أيام الحماسة` chips update instantly (replace `Icons.local_fire_department` with `streak_medium.svg`).
- [ ] 8.4 Warning job: When `last_streak_date == CURRENT_DATE -1` and no completion today → show `⚠` card: `“يا بطل! Streak 🔥 بتاعك في خطر! ما قريت اليوم ، ادخل هسي قبل ما تخسر {streak} يوم !”` on HomeScreen. Schedule via in-app check on `initUserData` + daily at 20:00 local with `flutter_local_notifications` (or simple in-app banner for MVP).
- [ ] 8.5 Edge: Streak loss → reset to 0, show Haffour sleepy/panicRun mascot (use `assets/icons/streak_large.svg` + `mascot.dart` `sleepy` pose).
- [ ] 8.6 Verify: Complete lesson Day 1 → streak 1, Day 2 complete → 2, skip Day 3 → Day 4 shows 0 then 1 on next completion, warning shown on Day 3 evening.

---

## Phase 9 — Weekly League (نظام الدوري — حفّار)

- [ ] 9.1 Time window: **Saturday 00:00 → Friday 23:59** `Africa/Khartoum` (UTC+2). Implement helper `weeklyWindow(now)` returning `(start, end)`. Use `xp_events.created_at` for aggregation (not `profiles.xp`).
- [ ] 9.2 View/function `weekly_leaderboard` : `SELECT user_id, SUM(amount) as week_xp, MAX(profiles.display_name) as display_name FROM xp_events JOIN profiles ON ... WHERE created_at BETWEEN $start AND $end GROUP BY user_id ORDER BY week_xp DESC LIMIT 20`.
- [ ] 9.3 `LeaderboardRepository` — `fetchWeeklyTop20()`, `fetchCurrentUserRank()`.
- [ ] 9.4 `LeaderboardScreen` — replace static 5-player mock (`lib/screens/leaderboard_screen.dart:10-51`) with live data:
  - Podium heights `100/130/80` kept, but data from top 3 `week_xp`.
  - Rows scrollable beyond 2, highlight current user row (orange `primaryLight` bg).
  - Bronze badge `Color(0xFFcd7f32)` kept for now — single league `mvp` per PDF: “دوري واحد أسبوعي مافي مستويات في الmvp كل الطلاب في نفس دوري”. No silver/gold yet; `league` field stays `bronze` or `mvp`.
  - Empty state if no `week_xp`.
- [ ] 9.5 Wire `GoRouter` route `Routes.leaderboard` in `main.dart` (currently defined in `routes.dart` but not in router).
- [ ] 9.6 Verify: Earn 20 XP on Saturday, appears on leaderboard before Friday 23:59, resets to 0 next Saturday.

---

## Phase 10 — Banners (البانرات)

- [ ] 10.1 Migration `create_banners`:
  - `banners` table: `id TEXT PK (banner-1|banner-2|banner-3a|banner-3b)`, `title TEXT`, `image_url TEXT`, `condition_streak INT`, `condition_lessons INT`
  - `user_banners` table: `user_id FK`, `banner_id FK`, `earned_at`, `selected BOOL`, unique(user_id, banner_id)
  - RLS: public read `banners`, own-row for `user_banners`.
- [ ] 10.2 Assets: keep `assets/banners/banner-1.jpg` (Banner 1: `حفّار — أحفر طريقك نحو النجاح` — auto on new account). Add Banner 2 assets (10-day) and Banner 3a/3b (`gold “انا التوب والباقي فوتوشب”` male + pink female graduate) to `assets/banners/` — ensure `pubspec.yaml` `assets/banners/` already covers them.
- [ ] 10.3 Award logic (trigger or client after streak/lesson completion):
  - Banner 1: `INSERT user_banners(banner-1)` on `profiles` creation (existing trigger).
  - Banner 2: when `streak >=10 AND completedLessons >=20` → earn `banner-2`.
  - Banner 3: when `streak >=30 AND completedLessons >=40` → earn **both** `banner-3a` and `banner-3b` — user sees both in profile `Wrap` and picks one as `selected`. Store `selected` toggle.
- [ ] 10.4 UI:
  - `ProfileScreen` `_achievementsSection` / banner header: replace hard-coded `banner-1.jpg height:160` with dynamic `selected banner` (160×320). Avatar overlapping `88px primary` kept.
  - `AchievementsScreen` grid `crossAxisCount:2` (currently 6 hard-coded ✨) → drive from `banners` + `user_banners` (locked shows `Lock` icon + grey `surfaceHigh`, unlocked white).
  - Share button (currently commented `profile_screen:162-181`) — re-enable or keep hidden per product decision.
- [ ] 10.5 Also update subject banner `أرضنا الطيبة..` if it is Banner 2 art: decide mapping — PDF shows Sudan map mascot banner likely Banner 2 visual; confirm with design.
- [ ] 10.6 Verify: new user sees Banner 1 immediately, user hitting 10/20 sees Banner 2 appear, 30/40 sees both 3a & 3b with picker.

---

## Phase 11 — UI Polish (اخر تعديلات + شاشات الاسئله)

### 11A. Subject cards — equal squares

- [ ] 11A.1 `HomeScreen._subjectCard` (currently `Container width:150`, image `72×72`, `Wrap spacing10`) and `SubjectSelectScreen` grid `childAspectRatio 1.1, 64×64`:
  - Enforce fixed square: `AspectRatio 1` + `height == width` (use `GridView` with `SliverGridDelegateWithFixedCrossAxisCount childAspectRatio:1` for both screens). Test with long name `تكنولوجيا المعلومات والاتصالات` (wraps to 2 lines `12px`?) — ensure `maxLines:2, overflow:ellipsis` and same container height. Keep orange `primary` + `12 radius` + shadow `blur8 offset0,4` consistent.
  - Remove `SingleChildScrollView horizontal Wrap` divergence on Home — use same `GridView` logic as `SubjectSelect` for parity.

### 11B. Question screens — unified style

- [ ] 11B.1 `PracticeQuizScreen` + `QuestionScreen` header: **شريط تقدم علوي** — use `widgets/progress_bar.dart` or `progress_bar_ring.dart` (`height 12`, pill `9999`, `centerRight` for RTL) with **heart pill** `7❤` same style as first design (use `heart_small.svg 26×21` + `BeVietnamPro 13`). Position: `SafeArea` top row = heart pill left, progress center, `X` right.
- [ ] 11B.2 All 12 `question_widget_factory` types render inside `QuestionBase` (white card, `16 radius`, `outline 0.2` etc.) — audit that `multiple_choice`, `true_false`, `fill_blank`, `ordering` etc. share same `QuestionHeader` padding `16/12`, same `HaffarSpeechBubble` bottom padding logic (already fixed for tail), same bottom-sheet trigger.
- [ ] 11B.3 Feedback bottom-sheet:
  - Correct → green `HaffarColors` (or `#58cc02` if missing, add to `colors.dart`), Wrong → red `#ba1a1a`.
  - Component: `FeedbackDrawer` / `_feedbackBar` (currently `CircularProgress` colors primary/error, row with mascot 52, column `أحسنت!`, button `التالي` white pill) — animate with `SlideTransition` from bottom `400ms cubic`, anchored **تحت** (bottom `SafeArea`, not top). `AnimatedSize` already exists — move to `Positioned(bottom:0, left:0, right:0)` overlay inside `Stack`.

### 11C. Hearts in stats bar

- [ ] 11C.1 `HomeScreen` top stats: currently `21 XP ⚡ | 0 يوم 🔥 | 0 درس 🎓`. The PDF arrow `هنا 7❤` points to the `0 درس` chip — confirm chip should show `hearts` count? Actually PDF code snippet: `7 قلوب كل خطا = قلب واحد ...` So stat chips remain `XP / streak / completedLessons` — add heart count pill next to them or replace `0 درس` with `7 ❤`? Decision: keep `0 درس` chip + add heart pill `7 ❤` beside it (use `HaffarColors.primary` border). Update `HomeScreen:49-52` to include `Icons.favorite` `red` pill.

### 11D. Routing & deep links

- [ ] 11D.1 Migrate imperative `Navigator.push(MaterialPageRoute->UnitsScreen/LessonDetail/PracticeQuiz)` to `GoRouter` `extra` in `main.dart` router (add routes for `units`, `lessonDetail`, `practiceQuiz`, `unitExercise`) to keep back-stack `arrow_back_rounded` on right (RTL) consistent.

### 11E. Verification

- [ ] 11E.1 All question types render with identical header/progress/heart pill/fonts (`DIN2014Rounded` vs `BeVietnamPro` — normalize to `HaffarTextStyles.fontFamily`).
- [ ] 11E.2 Correct shows green drawer from bottom, wrong red, both with mascot `mascot.dart` `cheer`/`sad` poses.
- [ ] 11E.3 Subject card for `ict` with 2-line name has pixel-identical height to `science` card on iPhone SE + Pixel 7.

---

## Phase 12 — QA, Migration Order & Rollout

### Order

1. **Migrations first** (7A + 8.1 + 9.2 + 10.1) → advisors green.
2. **Repositories + constants** (7B) — no UI.
3. **Lesson flow** (7C) — behind feature flag `heartsEnabled` if needed for QA.
4. **Unit flow** (7D) → **Streak** (8.2-8.4) → **League** (9.3-9.4) → **Banners** (10.3-10.4) → **UI polish** (11).
5. Each phase ends with `flutter analyze lib/` + `flutter test` (add `test/hearts_test.dart`, `test/xp_test.dart`, `test/streak_test.dart`).

### Rollout risks

- `technical` subject copy used ICT questions — will be replaced by real content later; ensure IDs stable (`tech_l01_q01` etc.) so replacement is `DELETE WHERE subject_id=technical` + re-insert.
- Timer already elapsed via `_startTime` — unit bonus 15 XP depends on it; ensure `PracticeQuizScreen` passes elapsed to `unit_exercise_screen` award logic.
- No `subscribed` flag yet — default all users to `false` for testing free path first; add `UPDATE profiles SET is_subscribed=false`.

### Definition of Done

- [ ] All 22 PDF slides have a mapped checklist item above (traceability).
- [ ] `flutter analyze lib/` 0 issues on every commit.
- [ ] Supabase advisors 0 errors.
- [ ] Manual QA: free lesson lose-all-hearts → 0 XP + wait, subscriber lesson never blocked, unit 5 hearts, streak warning appears, weekly leaderboard resets Saturday, Banner 2/3 unlock at thresholds, subject cards equal height, feedback sheet slides from bottom green/red.

---

## Appendix — File Map for Implementer

| System | Primary files to edit | New files |
|---|---|---|
| Hearts/XP | `lib/providers/app_provider.dart`, `lib/services/progress_repository.dart`, `lib/screens/practice_quiz_screen.dart`, `lib/screens/unit_exercise_screen.dart`, `lib/screens/lesson_detail_screen.dart` | `lib/services/hearts_repository.dart`, `lib/services/xp_repository.dart`, `lib/utils/game_constants.dart` |
| Streak | `app_provider.dart`, `home_screen.dart`, `profile_screen.dart` | `lib/services/streak_service.dart` |
| League | `lib/screens/leaderboard_screen.dart`, `lib/main.dart` | `lib/services/leaderboard_repository.dart` |
| Banners | `lib/screens/profile_screen.dart`, `lib/screens/achievements_screen.dart`, `lib/models/achievement.dart` | `supabase/migrations/*_banners.sql` |
| UI Polish | `lib/screens/home_screen.dart`, `lib/screens/subject_select_screen.dart`, `lib/widgets/question_widgets/*`, `lib/widgets/feedback_drawer.dart`, `lib/design_system/colors.dart` | — |
| Schema | — | `supabase/migrations/20260907_hearts_xp_streak_league_banners.sql` |

> Keep `pre-built` question content untouched — `technical` placeholder stays until real questions arrive.

