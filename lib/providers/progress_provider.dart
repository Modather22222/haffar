import 'dart:async';

import 'package:flutter/material.dart';

import '../services/progress_repository.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';

/// Lesson/unit completions, unlock gates, onboarding flags, display name.
/// Owns the only client-writable profile field (display_name via RPC).
class ProgressProvider extends ChangeNotifier {
  ProgressRepository? _progressRepo;
  Timer? _nameSaveTimer;
  bool remoteSyncEnabled = false;

  // ── Identity / flags ─────────────────────────────────────────────────────
  String userName = 'الحفار';

  /// 'male' | 'female' — set during onboarding gender step.
  String? gender;
  bool hasCompletedOnboarding = false;
  bool hasLoggedIn = false;
  bool notificationsEnabled = false;
  String? selectedSubjectId;
  final Set<String> selectedSubjectIds = {};

  // ── Lesson progress ──────────────────────────────────────────────────────
  int currentLessonIndex = 0;
  int completedLessons = 0;

  final Set<String> _completedSubjectLessons = {};
  final Set<String> _completedUnitExercises = {};

  static String _lessonKey(String subjectId, int lessonIndex) =>
      '$subjectId:$lessonIndex';

  void attachRepo(ProgressRepository repo, {required bool signedIn}) {
    _progressRepo = repo;
    remoteSyncEnabled = signedIn;
  }

  /// Hydrates name + completions from fetched profile/keys.
  void hydrate({
    Map<String, dynamic>? profile,
    required List<String> completedLessonKeys,
    required List<String> completedUnitKeys,
  }) {
    final name = profile?['display_name'] as String?;
    if (name != null && name.isNotEmpty && name != 'البطل') userName = name;
    _completedSubjectLessons
      ..clear()
      ..addAll(completedLessonKeys.where((k) => !k.contains('null')));
    _completedUnitExercises
      ..clear()
      ..addAll(completedUnitKeys.where((k) => !k.contains('null')));
    notifyListeners();
  }

  void completeSubjectLesson(String subjectId, int lessonIndex) {
    if (_completedSubjectLessons.add(_lessonKey(subjectId, lessonIndex))) {
      _sync(
        () => _progressRepo!.saveCompletedLesson(subjectId, lessonIndex),
        userVisible: true,
        failMessage: 'تعذر حفظ تقدم الدرس على الخادم — سيُحاول لاحقاً',
      );
      notifyListeners();
    }
  }

  bool isSubjectLessonCompleted(String subjectId, int lessonIndex) =>
      _completedSubjectLessons.contains(_lessonKey(subjectId, lessonIndex));

  /// Number of leading consecutive completed lessons.
  int subjectCompletedCount(String subjectId) {
    var count = 0;
    while (isSubjectLessonCompleted(subjectId, count)) {
      count++;
    }
    return count;
  }

  void completeUnitExercise(String subjectId, int unitIndex) {
    if (_completedUnitExercises.add('$subjectId:$unitIndex')) {
      _sync(
        () => _progressRepo!.saveCompletedUnitExercise(subjectId, unitIndex),
        userVisible: true,
        failMessage: 'تعذر حفظ تقدم التمرين على الخادم — سيُحاول لاحقاً',
      );
      notifyListeners();
    }
  }

  bool isUnitExerciseCompleted(String subjectId, int unitIndex) =>
      _completedUnitExercises.contains('$subjectId:$unitIndex');

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void login(String name) {
    userName = name;
    hasLoggedIn = true;
    _scheduleNameSave();
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

  void advanceLesson() {
    currentLessonIndex++;
    completedLessons++;
    notifyListeners();
  }

  void resetProgress() {
    currentLessonIndex = 0;
    completedLessons = 0;
    _completedSubjectLessons.clear();
    _completedUnitExercises.clear();
    selectedSubjectIds.clear();
    _sync(
      () => _progressRepo!.clearAllProgress(),
      userVisible: true,
      failMessage: 'تعذر تصفير التقدم على الخادم — حاول مرة أخرى',
    );
    notifyListeners();
  }

  /// Fire-and-forget remote write; failures never break local UX.
  /// Logs always; shows a snackbar when [userVisible].
  void _sync(
    Future<void> Function() task, {
    bool userVisible = false,
    String? failMessage,
  }) {
    if (!remoteSyncEnabled || _progressRepo == null) return;
    task().catchError((Object e, StackTrace st) {
      AppLog.error('progress sync failed', e, st);
      if (userVisible) {
        AppToast.error(e, fallback: failMessage, logContext: 'progress sync');
      }
      return null;
    });
  }

  void _scheduleNameSave() {
    if (!remoteSyncEnabled || _progressRepo == null) return;
    _nameSaveTimer?.cancel();
    _nameSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _sync(
        () => _progressRepo!.saveProfile(displayName: userName),
        userVisible: true,
        failMessage: 'تعذر حفظ اسمك على الخادم',
      );
    });
  }

  @override
  void dispose() {
    _nameSaveTimer?.cancel();
    super.dispose();
  }
}
