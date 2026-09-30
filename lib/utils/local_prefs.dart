import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// App-level flags that must survive restarts (onboarding, identity).
/// Auth sessions are persisted separately by supabase_flutter.
class LocalPrefs {
  LocalPrefs._();

  static const _kOnboarded = 'hasCompletedOnboarding';
  static const _kLoggedIn = 'hasLoggedIn';
  static const _kSelectedSubjectId = 'selectedSubjectId';
  static const _kSelectedSubjectIds = 'selectedSubjectIds';
  static const _kUserName = 'userName';
  static const _kGender = 'gender';
  static const _kSchoolName = 'schoolName';
  static const _kFromState = 'fromState';
  static const _kReferralSource = 'referralSource';
  static const _kTargetScore = 'targetScore';
  static const _kPlanChoice = 'planChoice';
  static const _kNotifications = 'notificationsEnabled';
  static const _kPendingLessonKeys = 'pendingLessonKeys';
  static const _kPendingUnitKeys = 'pendingUnitKeys';
  static const _kPendingXpEvents = 'pendingXpEvents';
  static const _kPendingStreak = 'pendingStreakBump';

  static Future<bool> getBool(String key, {bool fallback = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? fallback;
    } catch (e, st) {
      AppLog.error('LocalPrefs.getBool($key)', e, st);
      return fallback;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e, st) {
      AppLog.error('LocalPrefs.setBool($key)', e, st);
    }
  }

  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e, st) {
      AppLog.error('LocalPrefs.getString($key)', e, st);
      return null;
    }
  }

  static Future<void> setString(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    } catch (e, st) {
      AppLog.error('LocalPrefs.setString($key)', e, st);
    }
  }

  static Future<void> setStringList(String key, List<String> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, value);
    } catch (e, st) {
      AppLog.error('LocalPrefs.setStringList($key)', e, st);
    }
  }

  static Future<List<String>> getStringList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key) ?? const [];
    } catch (e, st) {
      AppLog.error('LocalPrefs.getStringList($key)', e, st);
      return const [];
    }
  }

  // Named accessors used by ProgressProvider — keep keys in one place.
  static Future<bool> readOnboarded() => getBool(_kOnboarded);
  static Future<void> writeOnboarded(bool v) => setBool(_kOnboarded, v);
  static Future<bool> readLoggedIn() => getBool(_kLoggedIn);
  static Future<void> writeLoggedIn(bool v) => setBool(_kLoggedIn, v);
  static Future<String?> readSelectedSubjectId() =>
      getString(_kSelectedSubjectId);
  static Future<void> writeSelectedSubjectId(String? v) =>
      setString(_kSelectedSubjectId, v);
  static Future<List<String>> readSelectedSubjectIds() =>
      getStringList(_kSelectedSubjectIds);
  static Future<void> writeSelectedSubjectIds(List<String> v) =>
      setStringList(_kSelectedSubjectIds, v);
  static Future<String?> readUserName() => getString(_kUserName);
  static Future<void> writeUserName(String? v) => setString(_kUserName, v);
  static Future<String?> readGender() => getString(_kGender);
  static Future<void> writeGender(String? v) => setString(_kGender, v);
  static Future<String?> readSchoolName() => getString(_kSchoolName);
  static Future<void> writeSchoolName(String? v) => setString(_kSchoolName, v);
  static Future<String?> readFromState() => getString(_kFromState);
  static Future<void> writeFromState(String? v) => setString(_kFromState, v);
  static Future<String?> readReferralSource() => getString(_kReferralSource);
  static Future<void> writeReferralSource(String? v) =>
      setString(_kReferralSource, v);
  static Future<int?> readTargetScore() async {
    final v = await getString(_kTargetScore);
    return v == null ? null : int.tryParse(v);
  }

  static Future<void> writeTargetScore(int? v) =>
      setString(_kTargetScore, v?.toString());
  static Future<String?> readPlanChoice() => getString(_kPlanChoice);
  static Future<void> writePlanChoice(String? v) => setString(_kPlanChoice, v);
  static Future<bool> readNotifications() => getBool(_kNotifications);
  static Future<void> writeNotifications(bool v) => setBool(_kNotifications, v);

  // Outbox keys — retried on next successful session restore.
  static Future<List<String>> readPendingLessonKeys() =>
      getStringList(_kPendingLessonKeys);
  static Future<void> writePendingLessonKeys(List<String> v) =>
      setStringList(_kPendingLessonKeys, v);
  static Future<List<String>> readPendingUnitKeys() =>
      getStringList(_kPendingUnitKeys);
  static Future<void> writePendingUnitKeys(List<String> v) =>
      setStringList(_kPendingUnitKeys, v);
  static Future<List<String>> readPendingXpEvents() =>
      getStringList(_kPendingXpEvents);
  static Future<void> writePendingXpEvents(List<String> v) =>
      setStringList(_kPendingXpEvents, v);
  static Future<bool> readPendingStreak() => getBool(_kPendingStreak);
  static Future<void> writePendingStreak(bool v) => setBool(_kPendingStreak, v);
}
