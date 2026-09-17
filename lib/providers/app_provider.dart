import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../services/auth_service.dart';
import '../services/content_repository.dart';
import '../services/progress_repository.dart';
import '../services/hearts_repository.dart';
import '../services/xp_repository.dart';
import '../utils/game_constants.dart';

import 'dart:developer' as developer;

enum ContentStatus { loading, loaded, error }

/// Main app state — content from Supabase + user progress, XP, streak, league, hearts
class AppProvider extends ChangeNotifier {
  // ── Content (from Supabase) ───────────────────────────────────────────────
  ContentStatus contentStatus = ContentStatus.loading;
  List<Subject> _subjects = const [];
  Map<String, List<Lesson>> _lessonsBySubject = {};
  Map<String, List<Question>> _questionsBySubject = {};

  // ── Remote sync ───────────────────────────────────────────────────────────
  bool remoteSyncEnabled = false;
  AuthService? _authService;
  ProgressRepository? _progressRepo;
  HeartsRepository? _heartsRepo;
  XpRepository? _xpRepo;
  Timer? _profileSaveTimer;
  Timer? _heartsRefreshTimer;

  Future<void> loadContent() async {
    contentStatus = ContentStatus.loading;
    notifyListeners();
    try {
      final repo = ContentRepository(Supabase.instance.client);
      final results = await Future.wait([
        repo.fetchSubjects(),
        repo.fetchLessons(),
        repo.fetchQuestions(),
      ]);
      final subjects = results[0] as List<Subject>;
      final lessons = results[1] as List<Lesson>;
      final questions = results[2] as List<Question>;
      _subjects = subjects;
      _lessonsBySubject = {};
      for (final lesson in lessons) {
        _lessonsBySubject.putIfAbsent(lesson.subjectId, () => []).add(lesson);
      }
      _questionsBySubject = {};
      for (final question in questions) {
        _questionsBySubject
            .putIfAbsent(question.subjectId, () => [])
            .add(question);
      }
      contentStatus = ContentStatus.loaded;
    } catch (e, st) {
      developer.log('loadContent FAILED: $e\n$st', name: 'haffar.app');
      contentStatus = ContentStatus.error;
    }
    notifyListeners();
  }

  /// Sign in (anonymous by default) and hydrate progress from the database.
  Future<void> initUserData() async {
    try {
      final client = Supabase.instance.client;
      _authService = AuthService(client);
      _progressRepo = ProgressRepository(client);
      _heartsRepo = HeartsRepository(client);
      _xpRepo = XpRepository(client);
      final signedIn = await _authService!.ensureSignedIn();
      remoteSyncEnabled = signedIn;
      if (!signedIn) return;
      final results = await Future.wait([
        _progressRepo!.fetchProfile(),
        _progressRepo!.fetchCompletedLessons(),
        _progressRepo!.fetchCompletedUnitExercises(),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      if (profile != null) {
        xp = (profile['xp'] as int?) ?? xp;
        streak = (profile['streak'] as int?) ?? streak;
        gems = (profile['gems'] as int?) ?? gems;
        league = (profile['league'] as String?) ?? league;
        isSubscribed = (profile['is_subscribed'] as bool?) ?? false;
        hearts = (profile['hearts'] as int?) ?? hearts;
        final name = profile['display_name'] as String?;
        if (name != null && name.isNotEmpty && name != 'البطل') userName = name;
      }
      _completedSubjectLessons.addAll(
        (results[1] as List<String>).where((k) => !k.contains('null')),
      );
      _completedUnitExercises.addAll(
        (results[2] as List<String>).where((k) => !k.contains('null')),
      );
      await syncHeartsFromServer();
      _startHeartsRefreshTimer();
    } catch (_) {
      remoteSyncEnabled = false;
    }
    notifyListeners();
  }

  void _startHeartsRefreshTimer() {
    _heartsRefreshTimer?.cancel();
    _heartsRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _sync(() async => await refreshHearts());
    });
  }

  Future<void> refreshHearts() async {
    final refreshed = await _heartsRepo!.getHearts();
    if (hearts != refreshed) {
      hearts = refreshed;
      notifyListeners();
    }
  }

  /// Server-authoritative heart refresh — re-reads from DB and applies regeneration.
  Future<void> syncHeartsFromServer() async {
    if (!remoteSyncEnabled || _heartsRepo == null) return;
    try {
      hearts = await _heartsRepo!.getHearts();
      notifyListeners();
    } catch (_) {}
  }

  /// Consumes a heart for a wrong answer. Returns false if no hearts remain.
  /// [isUnitExam] controls which max (7 free lesson vs 5 unit).
  /// Subscribers never lose hearts on lesson exams.
  /// Returns remaining hearts (0 if none left).
  Future<int> consumeHeartForExam({required bool isUnitExam}) async {
    if (!remoteSyncEnabled || _heartsRepo == null) return hearts;
    // Subscribers have infinite hearts on lessons; unit exams always cost a heart
    if (isSubscribed && !isUnitExam) return hearts;
    final remaining = await _heartsRepo!.consumeHeart(
      reason: isUnitExam ? 'unit_wrong' : 'lesson_wrong',
    );
    hearts = remaining;
    notifyListeners();
    return remaining;
  }

  /// Inserts an XP event and updates the local XP aggregate.
  Future<void> addXpEvent({
    required int amount,
    required String source,
    String? subjectId,
    int? lessonIndex,
  }) async {
    if (!remoteSyncEnabled || _xpRepo == null) {
      xp += amount;
      notifyListeners();
      return;
    }
    try {
      await _xpRepo!.insertEvent(
        amount: amount,
        source: source,
        subjectId: subjectId,
        lessonIndex: lessonIndex,
      );
      xp += amount;
      _scheduleProfileSave();
      notifyListeners();
    } catch (_) {
      xp += amount;
      notifyListeners();
    }
  }

  /// Fire-and-forget remote write; failures never break local UX.
  void _sync(Future<void> Function() task) {
    if (!remoteSyncEnabled) return;
    task().catchError((_) {});
  }

  /// Debounced profile upsert so rapid XP gains collapse into one write.
  void _scheduleProfileSave() {
    if (!remoteSyncEnabled) return;
    _profileSaveTimer?.cancel();
    _profileSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _sync(
        () => _progressRepo!.saveProfile(
          displayName: userName,
          xp: xp,
          streak: streak,
          gems: gems,
          league: league,
          isSubscribed: isSubscribed,
          hearts: hearts,
        ),
      );
    });
  }

  @override
  void dispose() {
    _profileSaveTimer?.cancel();
    _heartsRefreshTimer?.cancel();
    super.dispose();
  }

  List<Subject> get subjects => _subjects;

  Subject? subjectById(String id) => Subject.getById(_subjects, id);

  List<Lesson> lessonsOf(String subjectId) =>
      _lessonsBySubject[subjectId] ?? const [];

  Lesson? lessonOf(String subjectId, int lessonIndex) {
    for (final lesson in lessonsOf(subjectId)) {
      if (lesson.index == lessonIndex) return lesson;
    }
    return null;
  }

  List<Question> questionsOf(String subjectId) =>
      _questionsBySubject[subjectId] ?? const [];

  /// Ordered questions for one lesson.
  List<Question> getQuestions(String subjectId, int lessonIndex) {
    final list =
        questionsOf(
            subjectId,
          ).where((q) => q.lessonIndex == lessonIndex).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// All questions of a unit's lessons.
  List<Question> getUnitQuestions(String subjectId, int unitIndex) {
    final start = unitIndex * 3;
    return questionsOf(subjectId)
        .where((q) => q.lessonIndex >= start && q.lessonIndex < start + 3)
        .toList()
      ..sort(
        (a, b) => a.lessonIndex != b.lessonIndex
            ? a.lessonIndex.compareTo(b.lessonIndex)
            : a.sortOrder.compareTo(b.sortOrder),
      );
  }

  int lessonCountOf(String subjectId) => lessonsOf(subjectId).length;

  int totalQuestionCount() =>
      _questionsBySubject.values.fold(0, (sum, list) => sum + list.length);

  // ── User ─────────────────────────────────────────────────────────────────
  String userName = 'الحفار';
  int xp = 0;
  int streak = 0;
  int gems = 0;
  String league = 'bronze';
  bool isSubscribed = false;

  // ── Hearts ───────────────────────────────────────────────────────────────
  int hearts = GameConstants.maxHearts;

  // ── Progress ─────────────────────────────────────────────────────────────
  int currentLessonIndex = 0;
  int completedLessons = 0;
  bool hasCompletedOnboarding = false;
  bool hasLoggedIn = false;
  bool notificationsEnabled = false;
  String? selectedSubjectId;
  final Set<String> selectedSubjectIds = {};

  /// Completed lessons per subject as "subjectId:lessonIndex" keys.
  /// A lesson unlocks only when every lesson before it is done, so finishing
  /// a unit's last lesson unlocks the next unit's first lesson automatically.
  final Set<String> _completedSubjectLessons = {};

  static String _lessonKey(String subjectId, int lessonIndex) =>
      '$subjectId:$lessonIndex';

  void completeSubjectLesson(String subjectId, int lessonIndex) {
    if (_completedSubjectLessons.add(_lessonKey(subjectId, lessonIndex))) {
      _sync(() => _progressRepo!.saveCompletedLesson(subjectId, lessonIndex));
       _sync(() async {
         await _heartsRepo?.consumeHeart(reason: 'regeneration').catchError((_) => 0);
       });
      notifyListeners();
    }
  }

  bool isSubjectLessonCompleted(String subjectId, int lessonIndex) =>
      _completedSubjectLessons.contains(_lessonKey(subjectId, lessonIndex));

  /// Number of leading consecutive completed lessons (index of the current lesson).
  int subjectCompletedCount(String subjectId) {
    var count = 0;
    while (isSubjectLessonCompleted(subjectId, count)) {
      count++;
    }
    return count;
  }

  /// Returns true if a lesson is the first one (lowest index) of its unit.
  bool _isUnitStart(String subjectId, int lessonIndex) {
    final unitLessons = lessonsOf(
      subjectId,
    ).where((l) => l.index == lessonIndex).toList();
    if (unitLessons.isEmpty) return false;
    final unitIndex = unitLessons.first.unitIndex;
    return !lessonsOf(
      subjectId,
    ).any((l) => l.unitIndex == unitIndex && l.index < lessonIndex);
  }

  /// A lesson is reachable when it is the first lesson of its unit, or when all
  /// preceding lessons are completed.
  bool isSubjectLessonUnlocked(String subjectId, int lessonIndex) {
    if (_isUnitStart(subjectId, lessonIndex)) return true;
    for (var i = 0; i < lessonIndex; i++) {
      if (!isSubjectLessonCompleted(subjectId, i)) return false;
    }
    return true;
  }

  final Set<String> _completedUnitExercises = {};

  void completeUnitExercise(String subjectId, int unitIndex) {
    if (_completedUnitExercises.add('$subjectId:$unitIndex')) {
      _sync(
        () => _progressRepo!.saveCompletedUnitExercise(subjectId, unitIndex),
      );
      notifyListeners();
    }
  }

  bool isUnitExerciseCompleted(String subjectId, int unitIndex) =>
      _completedUnitExercises.contains('$subjectId:$unitIndex');

  // ── Actions ──────────────────────────────────────────────────────────────

  void login(String name) {
    userName = name;
    hasLoggedIn = true;
    _scheduleProfileSave();
    notifyListeners();
  }

  void completeOnboarding() {
    hasCompletedOnboarding = true;
    notifyListeners();
  }

  void enableNotifications() {
    notificationsEnabled = true;
    notifyListeners();
  }

  void selectSubject(String id) {
    selectedSubjectId = id;
    notifyListeners();
  }

  void toggleSelectedSubject(String id) {
    if (selectedSubjectIds.contains(id)) {
      selectedSubjectIds.remove(id);
    } else if (selectedSubjectIds.length < 2) {
      selectedSubjectIds.add(id);
    }
    notifyListeners();
  }

  /// Legacy — use addXpEvent instead. Kept for backwards compat during migration.
  void addXp(int amount) {
    xp += amount;
    _scheduleProfileSave();
    notifyListeners();
  }

  void updateStreak(int days) {
    streak = days;
    _scheduleProfileSave();
    notifyListeners();
  }

  void addGems(int amount) {
    gems += amount;
    _scheduleProfileSave();
    notifyListeners();
  }

  void setLeague(String l) {
    league = l;
    _scheduleProfileSave();
    notifyListeners();
  }

  void advanceLesson() {
    currentLessonIndex++;
    completedLessons++;
    notifyListeners();
  }

  /// Calls the server to update streak after a successful completion.
  Future<void> _updateStreakFromServer() async {
    if (!remoteSyncEnabled || _heartsRepo == null) return;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final newStreak = await client.rpc('update_streak', params: {'p_user_id': uid}) as int;
      streak = newStreak;
      _scheduleProfileSave();
      notifyListeners();
    } catch (_) {}
  }

  /// Public entry point for streak update — used by quiz screens after completion.
  Future<void> updateStreakOnCompletion() => _updateStreakFromServer();

  void resetProgress() {
    currentLessonIndex = 0;
    completedLessons = 0;
    _completedSubjectLessons.clear();
    _completedUnitExercises.clear();
    selectedSubjectIds.clear();
    xp = 0;
    streak = 0;
    gems = 0;
    hearts = GameConstants.maxHearts;
    _sync(() => _progressRepo!.clearAllProgress());
    notifyListeners();
  }
}
