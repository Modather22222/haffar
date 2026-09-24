import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import '../services/xp_repository.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../widgets/profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String? fallbackName;
  final VoidCallback? onBack;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.fallbackName,
    this.onBack,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = XpRepository(Supabase.instance.client);
      final profile = await repo.fetchPublicProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e, st) {
      AppLog.error('public profile load failed', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppError.userMessage(
          e,
          fallback: 'تعذر تحميل الملف الشخصي — حاول مرة أخرى',
        );
      });
    }
  }

  String get _name =>
      (_profile?['display_name'] as String?) ?? widget.fallbackName ?? 'البطل';

  String _bannerAsset() {
    final streak = (_profile?['streak'] as num?)?.toInt() ?? 0;
    final lessons = (_profile?['completed_lessons'] as num?)?.toInt() ?? 0;
    if (streak >= 30 && lessons >= 40) {
      return 'assets/banners/third_banner_v1.jpg';
    }
    if (streak >= 10 && lessons >= 20) {
      return 'assets/banners/second_banner.jpg';
    }
    return 'assets/banners/first_banner.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HaffarColors.bgPage,
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: HaffarColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: HaffarColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة التحميل'),
            ),
          ],
        ),
      );
    }
    if (_profile == null) {
      return const Center(
        child: Text(
          'لا يوجد ملف شخصي',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            color: HaffarColors.outline,
          ),
        ),
      );
    }

    final xp = (_profile!['xp'] as num?)?.toInt() ?? 0;
    final streak = (_profile!['streak'] as num?)?.toInt() ?? 0;
    final lessons = (_profile!['completed_lessons'] as num?)?.toInt() ?? 0;
    final weekXp = (_profile!['week_xp'] as num?)?.toInt() ?? 0;
    final league = (_profile!['league'] as String?) ?? 'bronze';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: ProfileView(
        displayName: _name,
        subtitle: _leagueLabel(league),
        xp: xp,
        streak: streak,
        completedLessons: lessons,
        weekXp: weekXp,
        bannerAsset: _bannerAsset(),
      ),
    );
  }

  String _leagueLabel(String league) {
    return switch (league) {
      'gold' => 'دوري الذهبي',
      'silver' => 'دوري الفضي',
      'bronze' => 'دوري البرونزي',
      _ => league,
    };
  }
}
