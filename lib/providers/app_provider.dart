import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../services/hearts_repository.dart';
import '../services/progress_repository.dart';
import '../services/xp_repository.dart';
import 'content_provider.dart';
import 'economy_provider.dart';
import 'progress_provider.dart';
import 'session_provider.dart';

// ContentStatus is re-exported so existing `import app_provider` sites
// (e.g. splash) keep compiling; Economy/Progress/Session are imported
// explicitly where used for clearer dependency boundaries.
export 'content_provider.dart' show ContentStatus;

/// Compatibility facade over the split providers.
///
/// Screens can keep watching [AppProvider] for mixed concerns, or watch
/// [ContentProvider] / [EconomyProvider] / [ProgressProvider] directly for
/// finer rebuild granularity. Logic lives in the split files.
class AppProvider extends ChangeNotifier {
  AppProvider() {
    content.addListener(notifyListeners);
    economy.addListener(notifyListeners);
    progress.addListener(notifyListeners);
    session.addListener(notifyListeners);
  }

  final ContentProvider content = ContentProvider();
  final EconomyProvider economy = EconomyProvider();
  final ProgressProvider progress = ProgressProvider();
  late final SessionProvider session = SessionProvider(
    content: content,
    economy: economy,
    progress: progress,
  );

  // ── Session ───────────────────────────────────────────────────────────────
  bool get remoteSyncEnabled => session.remoteSyncEnabled;

  Future<void> loadContent() => content.loadContent();

  Future<void> initUserData() => session.initUserData();

  // ── Content ───────────────────────────────────────────────────────────────
  ContentStatus get contentStatus => content.status;

  List<Subject> get subjects => content.subjects;

  Subject? subjectById(String id) => content.subjectById(id);

  List<Lesson> lessonsOf(String subjectId) => content.lessonsOf(subjectId);

  Lesson? lessonOf(String subjectId, int lessonIndex) =>
      content.lessonOf(subjectId, lessonIndex);

  List<Question> questionsOf(String subjectId) =>
      content.questionsOf(subjectId);

  List<Question> getQuestions(String subjectId, int lessonIndex) =>
      content.getQuestions(subjectId, lessonIndex);

  List<Question> getUnitQuestions(String subjectId, int unitIndex) =>
      content.getUnitQuestions(subjectId, unitIndex);

  int lessonCountOf(String subjectId) => content.lessonCountOf(subjectId);

  int totalQuestionCount() => content.totalQuestionCount();

  // ── Economy ───────────────────────────────────────────────────────────────
  int get xp => economy.xp;

  set xp(int v) => economy.xp = v;

  int get streak => economy.streak;

  set streak(int v) => economy.streak = v;

  int get gems => economy.gems;

  set gems(int v) => economy.gems = v;

  String get league => economy.league;

  set league(String v) => economy.league = v;

  bool get isSubscribed => economy.isSubscribed;

  set isSubscribed(bool v) => economy.isSubscribed = v;

  int get hearts => economy.hearts;

  set hearts(int v) => economy.hearts = v;

  DateTime? get heartsUpdatedAt => economy.heartsUpdatedAt;

  set heartsUpdatedAt(DateTime? v) => economy.heartsUpdatedAt = v;

  Duration? get heartsRegenRemaining => economy.heartsRegenRemaining;

  double get heartsRegenProgress => economy.heartsRegenProgress;

  Future<void> refreshHearts() => economy.refreshHearts();

  Future<void> syncHeartsFromServer() => economy.syncHeartsFromServer();

  Future<int> consumeHeartForExam({required bool isUnitExam}) =>
      economy.consumeHeartForExam(isUnitExam: isUnitExam);

  Future<void> addXpEvent({
    required int amount,
    required String source,
    String? subjectId,
    int? lessonIndex,
  }) => economy.addXpEvent(
    amount: amount,
    source: source,
    subjectId: subjectId,
    lessonIndex: lessonIndex,
  );

  Future<void> updateStreakOnCompletion() => economy.updateStreakOnCompletion();

  void addXp(int amount) => economy.addXp(amount);

  void updateStreak(int days) => economy.updateStreak(days);

  void addGems(int amount) => economy.addGems(amount);

  void setLeague(String l) => economy.setLeague(l);

  // ── Progress ──────────────────────────────────────────────────────────────
  String get userName => progress.userName;

  set userName(String v) => progress.userName = v;

  int get currentLessonIndex => progress.currentLessonIndex;

  set currentLessonIndex(int v) => progress.currentLessonIndex = v;

  int get completedLessons => progress.completedLessons;

  bool get hasCompletedOnboarding => progress.hasCompletedOnboarding;

  set hasCompletedOnboarding(bool v) => progress.hasCompletedOnboarding = v;

  bool get hasLoggedIn => progress.hasLoggedIn;

  set hasLoggedIn(bool v) => progress.hasLoggedIn = v;

  bool get notificationsEnabled => progress.notificationsEnabled;

  set notificationsEnabled(bool v) => progress.notificationsEnabled = v;

  String? get selectedSubjectId => progress.selectedSubjectId;

  set selectedSubjectId(String? v) => progress.selectedSubjectId = v;

  Set<String> get selectedSubjectIds => progress.selectedSubjectIds;

  void completeSubjectLesson(String subjectId, int lessonIndex) =>
      progress.completeSubjectLesson(subjectId, lessonIndex);

  bool isSubjectLessonCompleted(String subjectId, int lessonIndex) =>
      progress.isSubjectLessonCompleted(subjectId, lessonIndex);

  int subjectCompletedCount(String subjectId) =>
      progress.subjectCompletedCount(subjectId);

  bool isSubjectLessonUnlocked(String subjectId, int lessonIndex) {
    if (isUnitStart(subjectId, lessonIndex)) return true;
    for (var i = 0; i < lessonIndex; i++) {
      if (!isSubjectLessonCompleted(subjectId, i)) return false;
    }
    return true;
  }

  bool isUnitStart(String subjectId, int lessonIndex) {
    final unitLessons = lessonsOf(
      subjectId,
    ).where((l) => l.index == lessonIndex).toList();
    if (unitLessons.isEmpty) return false;
    final unitIndex = unitLessons.first.unitIndex;
    return !lessonsOf(
      subjectId,
    ).any((l) => l.unitIndex == unitIndex && l.index < lessonIndex);
  }

  void completeUnitExercise(String subjectId, int unitIndex) =>
      progress.completeUnitExercise(subjectId, unitIndex);

  bool isUnitExerciseCompleted(String subjectId, int unitIndex) =>
      progress.isUnitExerciseCompleted(subjectId, unitIndex);

  void login(String name) => progress.login(name);

  void completeOnboarding() => progress.completeOnboarding();

  void enableNotifications() => progress.enableNotifications();

  void selectSubject(String id) => progress.selectSubject(id);

  void toggleSelectedSubject(String id) => progress.toggleSelectedSubject(id);

  void resetProgress() {
    progress.resetProgress();
    economy.resetLocal();
  }

  // ── Repos for screens that talk to the DB directly ────────────────────────
  ProgressRepository? get progressRepository =>
      remoteSyncEnabled ? ProgressRepository(Supabase.instance.client) : null;

  HeartsRepository? get heartsRepository =>
      remoteSyncEnabled ? HeartsRepository(Supabase.instance.client) : null;

  XpRepository? get xpRepository =>
      remoteSyncEnabled ? XpRepository(Supabase.instance.client) : null;

  @override
  void dispose() {
    content.removeListener(notifyListeners);
    economy.removeListener(notifyListeners);
    progress.removeListener(notifyListeners);
    session.removeListener(notifyListeners);
    content.dispose();
    economy.dispose();
    progress.dispose();
    session.dispose();
    super.dispose();
  }
}
