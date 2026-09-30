import 'dart:async';

import 'package:flutter/material.dart';

import '../services/progress_repository.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import '../utils/local_prefs.dart';

/// Lesson/unit completions, unlock gates, onboarding flags, display name.
/// Owns the client-writable profile fields (all pushed through
/// update_own_profile — profiles UPDATE is revoked).
class ProgressProvider extends ChangeNotifier {
  ProgressRepository? _progressRepo;
  Timer? _profileSaveTimer;
  bool remoteSyncEnabled = false;

  // ── Identity / flags ─────────────────────────────────────────────────────
  String userName = 'الحفار';

  /// 'male' | 'female' — set during onboarding gender step.
  String? gender;

  /// Collected during onboarding before the account exists — kept locally,
  /// pushed to profiles via update_own_profile (screens 4-12).
  String schoolName = '';
  String fromState = '';
  String referralSource = '';
  int? targetScore;
  String planChoice = '';
  bool hasCompletedOnboarding = false;
  bool hasLoggedIn = false;
  bool notificationsEnabled = false;
  String? selectedSubjectId;
  final Set<String> selectedSubjectIds = {};

  // ── Lesson progress ──────────────────────────────────────────────────────
  int currentLessonIndex = 0;

  /// Total completed lessons across all subjects — derived from the
  /// per-subject set so Home/Profile always match path/units UI.
  int get completedLessons => _completedSubjectLessons.length;

  final Set<String> _completedSubjectLessons = {};
  final Set<String> _completedUnitExercises = {};

  /// Keys whose remote upsert failed — retried on next hydrate/attach.
  final Set<String> _pendingLessonKeys = {};
  final Set<String> _pendingUnitKeys = {};

  static String _lessonKey(String subjectId, int lessonIndex) =>
      '$subjectId:$lessonIndex';

  bool _localPrefsLoaded = false;

  /// Loads persisted onboarding/identity flags + outbox. Call once on splash before routing.
  Future<void> loadLocalPrefs() async {
    if (_localPrefsLoaded) return;
    try {
      hasCompletedOnboarding = await LocalPrefs.readOnboarded();
      hasLoggedIn = await LocalPrefs.readLoggedIn();
      selectedSubjectId = await LocalPrefs.readSelectedSubjectId();
      final ids = await LocalPrefs.readSelectedSubjectIds();
      selectedSubjectIds
        ..clear()
        ..addAll(ids);
      final name = await LocalPrefs.readUserName();
      if (name != null && name.isNotEmpty) userName = name;
      gender = await LocalPrefs.readGender();
      schoolName = await LocalPrefs.readSchoolName() ?? '';
      fromState = await LocalPrefs.readFromState() ?? '';
      referralSource = await LocalPrefs.readReferralSource() ?? '';
      targetScore = await LocalPrefs.readTargetScore();
      planChoice = await LocalPrefs.readPlanChoice() ?? '';
      notificationsEnabled = await LocalPrefs.readNotifications();
      _pendingLessonKeys
        ..clear()
        ..addAll(await LocalPrefs.readPendingLessonKeys());
      _pendingUnitKeys
        ..clear()
        ..addAll(await LocalPrefs.readPendingUnitKeys());
      _localPrefsLoaded = true;
      AppLog.info(
        'progress loadLocalPrefs done onboarded=$hasCompletedOnboarding '
        'subject=$selectedSubjectId name=$userName '
        'pendingLessons=${_pendingLessonKeys.length} '
        'pendingUnits=${_pendingUnitKeys.length}',
      );
      notifyListeners();
    } catch (e, st) {
      AppLog.error('progress loadLocalPrefs FAILED', e, st);
    }
  }

  void attachRepo(ProgressRepository repo, {required bool signedIn}) {
    _progressRepo = repo;
    remoteSyncEnabled = signedIn;
    if (signedIn) unawaited(_flushPendingSaves());
  }

  /// Public entry so SessionProvider can await outbox flush before hydrate.
  Future<void> flushPending() => _flushPendingSaves();

  /// Re-sends outbox keys that failed to upsert on a previous session.
  Future<void> _flushPendingSaves() async {
    if (!remoteSyncEnabled || _progressRepo == null) return;
    if (_pendingLessonKeys.isEmpty && _pendingUnitKeys.isEmpty) return;
    AppLog.info(
      'progress flush pending lessons=${_pendingLessonKeys.length} '
      'units=${_pendingUnitKeys.length}',
    );
    for (final key in List.of(_pendingLessonKeys)) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final subjectId = parts[0];
      final lessonIndex = int.tryParse(parts[1]);
      if (lessonIndex == null) continue;
      try {
        await _progressRepo!.saveCompletedLesson(subjectId, lessonIndex);
        _pendingLessonKeys.remove(key);
      } catch (e, st) {
        AppLog.error('flush pending lesson $key failed', e, st);
      }
    }
    for (final key in List.of(_pendingUnitKeys)) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final subjectId = parts[0];
      final unitIndex = int.tryParse(parts[1]);
      if (unitIndex == null) continue;
      try {
        await _progressRepo!.saveCompletedUnitExercise(subjectId, unitIndex);
        _pendingUnitKeys.remove(key);
      } catch (e, st) {
        AppLog.error('flush pending unit $key failed', e, st);
      }
    }
    await LocalPrefs.writePendingLessonKeys(_pendingLessonKeys.toList());
    await LocalPrefs.writePendingUnitKeys(_pendingUnitKeys.toList());
    notifyListeners();
  }

  /// Hydrates name + completions from fetched profile/keys.
  /// Merges server rows with any local-only keys still in the outbox so a
  /// failed upsert is never wiped by the next hydrate.
  void hydrate({
    Map<String, dynamic>? profile,
    required List<String> completedLessonKeys,
    required List<String> completedUnitKeys,
  }) {
    final name = profile?['display_name'] as String?;
    if (name != null && name.isNotEmpty && name != 'البطل') {
      userName = name;
      unawaited(LocalPrefs.writeUserName(name));
    }
    // Server wins only when it actually has a value — otherwise keep the
    // local onboarding answers collected before login.
    final school = profile?['school_name'] as String?;
    if (school != null && school.isNotEmpty) {
      schoolName = school;
      unawaited(LocalPrefs.writeSchoolName(school));
    }
    final state = profile?['from_state'] as String?;
    if (state != null && state.isNotEmpty) {
      fromState = state;
      unawaited(LocalPrefs.writeFromState(state));
    }
    final referral = profile?['referral_source'] as String?;
    if (referral != null && referral.isNotEmpty) {
      referralSource = referral;
      unawaited(LocalPrefs.writeReferralSource(referral));
    }
    final score = (profile?['target_score'] as num?)?.toInt();
    if (score != null) {
      targetScore = score;
      unawaited(LocalPrefs.writeTargetScore(score));
    }
    final plan = profile?['plan_choice'] as String?;
    if (plan != null && plan.isNotEmpty) {
      planChoice = plan;
      unawaited(LocalPrefs.writePlanChoice(plan));
    }
    final serverGender = profile?['gender'] as String?;
    if (serverGender != null && serverGender.isNotEmpty) {
      gender = serverGender;
      unawaited(LocalPrefs.writeGender(serverGender));
    }
    final subjects = (profile?['weak_subject_ids'] as List<dynamic>?)
        ?.cast<String>();
    if (subjects != null && subjects.isNotEmpty) {
      selectedSubjectIds
        ..clear()
        ..addAll(subjects);
      unawaited(LocalPrefs.writeSelectedSubjectIds(subjects));
    }
    if (profile?['notifications_enabled'] == true && !notificationsEnabled) {
      notificationsEnabled = true;
      unawaited(LocalPrefs.writeNotifications(true));
    }
    if (profile?['has_completed_onboarding'] == true &&
        !hasCompletedOnboarding) {
      hasCompletedOnboarding = true;
      unawaited(LocalPrefs.writeOnboarded(true));
    }
    _completedSubjectLessons
      ..clear()
      ..addAll(completedLessonKeys.where((k) => !k.contains('null')))
      ..addAll(_pendingLessonKeys); // keep unsynced local completions
    _completedUnitExercises
      ..clear()
      ..addAll(completedUnitKeys.where((k) => !k.contains('null')))
      ..addAll(_pendingUnitKeys);
    unawaited(_flushPendingSaves());
    notifyListeners();
  }

  void completeSubjectLesson(String subjectId, int lessonIndex) {
    final key = _lessonKey(subjectId, lessonIndex);
    if (_completedSubjectLessons.add(key)) {
      _syncLesson(key, subjectId, lessonIndex);
      notifyListeners();
    }
  }

  void _syncLesson(String key, String subjectId, int lessonIndex) {
    if (!remoteSyncEnabled || _progressRepo == null) return;
    _progressRepo!
        .saveCompletedLesson(subjectId, lessonIndex)
        .then((_) {
          if (_pendingLessonKeys.remove(key)) {
            unawaited(
              LocalPrefs.writePendingLessonKeys(_pendingLessonKeys.toList()),
            );
          }
        })
        .catchError((Object e, StackTrace st) {
          AppLog.error('progress sync lesson failed', e, st);
          _pendingLessonKeys.add(key);
          unawaited(
            LocalPrefs.writePendingLessonKeys(_pendingLessonKeys.toList()),
          );
          AppToast.error(
            e,
            fallback: 'تعذر حفظ تقدم الدرس — سيُحاول لاحقاً',
            logContext: 'progress sync',
          );
        });
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
    final key = '$subjectId:$unitIndex';
    if (_completedUnitExercises.add(key)) {
      _syncUnit(key, subjectId, unitIndex);
      notifyListeners();
    }
  }

  void _syncUnit(String key, String subjectId, int unitIndex) {
    if (!remoteSyncEnabled || _progressRepo == null) return;
    _progressRepo!
        .saveCompletedUnitExercise(subjectId, unitIndex)
        .then((_) {
          if (_pendingUnitKeys.remove(key)) {
            unawaited(
              LocalPrefs.writePendingUnitKeys(_pendingUnitKeys.toList()),
            );
          }
        })
        .catchError((Object e, StackTrace st) {
          AppLog.error('progress sync unit failed', e, st);
          _pendingUnitKeys.add(key);
          unawaited(LocalPrefs.writePendingUnitKeys(_pendingUnitKeys.toList()));
          AppToast.error(
            e,
            fallback: 'تعذر حفظ التمرين — سيُحاول لاحقاً',
            logContext: 'progress sync',
          );
        });
  }

  bool isUnitExerciseCompleted(String subjectId, int unitIndex) =>
      _completedUnitExercises.contains('$subjectId:$unitIndex');

  void setGender(String value) {
    gender = value;
    unawaited(LocalPrefs.writeGender(value));
    _scheduleProfileSave();
    notifyListeners();
  }

  void setSchoolName(String value) {
    schoolName = value.trim();
    unawaited(LocalPrefs.writeSchoolName(schoolName));
    _scheduleProfileSave();
    notifyListeners();
  }

  void setFromState(String value) {
    fromState = value.trim();
    unawaited(LocalPrefs.writeFromState(fromState));
    _scheduleProfileSave();
    notifyListeners();
  }

  void setReferralSource(String value) {
    referralSource = value.trim();
    unawaited(LocalPrefs.writeReferralSource(referralSource));
    _scheduleProfileSave();
    notifyListeners();
  }

  void setTargetScore(int value) {
    targetScore = value;
    unawaited(LocalPrefs.writeTargetScore(value));
    _scheduleProfileSave();
    notifyListeners();
  }

  void setPlanChoice(String value) {
    planChoice = value;
    unawaited(LocalPrefs.writePlanChoice(value));
    _scheduleProfileSave();
    notifyListeners();
  }

  void login(String name) {
    userName = name;
    hasLoggedIn = true;
    unawaited(LocalPrefs.writeUserName(name));
    unawaited(LocalPrefs.writeLoggedIn(true));
    _scheduleProfileSave();
    notifyListeners();
  }

  void completeOnboarding() {
    hasCompletedOnboarding = true;
    unawaited(LocalPrefs.writeOnboarded(true));
    _scheduleProfileSave();
    notifyListeners();
  }

  void enableNotifications() => setNotificationsEnabled(true);

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    unawaited(LocalPrefs.writeNotifications(value));
    _scheduleProfileSave();
    notifyListeners();
  }

  void selectSubject(String id) {
    selectedSubjectId = id;
    unawaited(LocalPrefs.writeSelectedSubjectId(id));
    notifyListeners();
  }

  void toggleSelectedSubject(String id) {
    if (selectedSubjectIds.contains(id)) {
      selectedSubjectIds.remove(id);
    } else if (selectedSubjectIds.length < 2) {
      selectedSubjectIds.add(id);
    }
    unawaited(LocalPrefs.writeSelectedSubjectIds(selectedSubjectIds.toList()));
    _scheduleProfileSave();
    notifyListeners();
  }

  void resetProgress() {
    currentLessonIndex = 0;
    _completedSubjectLessons.clear();
    _completedUnitExercises.clear();
    _pendingLessonKeys.clear();
    _pendingUnitKeys.clear();
    selectedSubjectIds.clear();
    unawaited(LocalPrefs.writeSelectedSubjectIds(const []));
    unawaited(LocalPrefs.writePendingLessonKeys(const []));
    unawaited(LocalPrefs.writePendingUnitKeys(const []));
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

  /// Debounced push of every onboarding field through update_own_profile.
  /// No-ops before login — the values stay local until the first [login].
  void _scheduleProfileSave() {
    if (!remoteSyncEnabled || _progressRepo == null) return;
    _profileSaveTimer?.cancel();
    _profileSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _sync(
        () => _progressRepo!.saveProfile(
          displayName: userName,
          schoolName: schoolName.isEmpty ? null : schoolName,
          fromState: fromState.isEmpty ? null : fromState,
          referralSource: referralSource.isEmpty ? null : referralSource,
          targetScore: targetScore,
          planChoice: planChoice.isEmpty ? null : planChoice,
          gender: gender,
          weakSubjectIds: selectedSubjectIds.isEmpty
              ? null
              : selectedSubjectIds.toList(),
          notificationsEnabled: notificationsEnabled,
          hasCompletedOnboarding: hasCompletedOnboarding,
        ),
        userVisible: true,
        failMessage: 'تعذر حفظ بياناتك على الخادم',
      );
    });
  }

  @override
  void dispose() {
    _profileSaveTimer?.cancel();
    super.dispose();
  }
}
