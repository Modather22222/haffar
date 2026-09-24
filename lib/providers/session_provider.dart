import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/hearts_repository.dart';
import '../services/progress_repository.dart';
import '../services/xp_repository.dart';
import '../utils/app_logger.dart';
import 'content_provider.dart';
import 'economy_provider.dart';
import 'progress_provider.dart';

/// Coordinates sign-in and one-shot hydration of the other providers.
/// Not a state holder itself — delegates to Content/Economy/Progress.
class SessionProvider extends ChangeNotifier {
  final ContentProvider content;
  final EconomyProvider economy;
  final ProgressProvider progress;

  SessionProvider({
    required this.content,
    required this.economy,
    required this.progress,
  });

  bool remoteSyncEnabled = false;

  /// Sign in (anonymous by default), hydrate economy + progress, load content.
  Future<void> initUserData() async {
    try {
      final client = Supabase.instance.client;
      final authService = AuthService(client);
      final progressRepo = ProgressRepository(client);
      final heartsRepo = HeartsRepository(client);
      final xpRepo = XpRepository(client);

      final signedIn = await authService.ensureSignedIn();
      remoteSyncEnabled = signedIn;
      economy.attachRepos(
        heartsRepo: heartsRepo,
        xpRepo: xpRepo,
        signedIn: signedIn,
      );
      progress.attachRepo(progressRepo, signedIn: signedIn);
      if (!signedIn) return;

      final results = await Future.wait([
        progressRepo.fetchProfile(),
        progressRepo.fetchCompletedLessons(),
        progressRepo.fetchCompletedUnitExercises(),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      if (profile != null) economy.hydrateFromProfile(profile);
      progress.hydrate(
        profile: profile,
        completedLessonKeys: results[1] as List<String>,
        completedUnitKeys: results[2] as List<String>,
      );
      await economy.syncHeartsFromServer();
      AppLog.info('initUserData OK hearts=${economy.hearts} xp=${economy.xp}');
    } catch (e, st) {
      AppLog.error('initUserData FAILED', e, st);
      remoteSyncEnabled = false;
    }
    notifyListeners();
  }
}
