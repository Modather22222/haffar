import '../design_system/colors.dart';
import '../widgets/profile_view.dart';
import '../providers/economy_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/session_provider.dart';
import '../services/banner_repository.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import '../utils/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Banner assets available per achievement tier.
class _Banner {
  final String key;
  final String asset;
  final String title;
  final String desc;
  final bool unlocked;
  const _Banner({
    required this.key,
    required this.asset,
    required this.title,
    required this.desc,
    required this.unlocked,
  });
}

class ProfileScreen extends StatelessWidget {
  final VoidCallback onBack;
  const ProfileScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: const SafeArea(child: _ProfileBody()),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
        onPressed: onBack,
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: HaffarColors.textPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 24),
          onPressed: () => context.push(Routes.settings),
        ),
      ],
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  /// Server-computed unlock flags (get_my_banners RPC). Empty until the
  /// fetch lands — and stays empty on failure — in which case the local
  /// threshold fallback in _bannerGrid applies.
  Map<String, bool> _bannerUnlocks = {};

  @override
  void initState() {
    super.initState();
    _loadBannerUnlocks();
  }

  Future<void> _loadBannerUnlocks() async {
    try {
      final unlocks = await BannerRepository(
        Supabase.instance.client,
      ).getUnlocks();
      if (mounted && unlocks.isNotEmpty) {
        setState(() => _bannerUnlocks = unlocks);
      }
    } catch (e, st) {
      AppLog.warn('get_my_banners failed: $e');
      AppLog.error('get_my_banners', e, st);
    }
  }

  /// Select banner asset based on user progress thresholds.
  String _selectedBannerAsset(int streak, int lessons) {
    if (streak >= 30 && lessons >= 40) {
      // User qualifies for banner 3 — default to v1, picker in achievements
      return 'assets/banners/third_banner_v1.jpg';
    }
    if (streak >= 10 && lessons >= 20) {
      return 'assets/banners/second_banner.jpg';
    }
    return 'assets/banners/first_banner.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final progress = context.watch<ProgressProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: ProfileView(
        displayName: progress.userName,
        subtitle: 'الصف الثالث متوسط',
        xp: economy.xp,
        streak: economy.streak,
        completedLessons: progress.completedLessons,
        bannerAsset:
            BannerRepository.assets[economy.selectedBanner] ??
            _selectedBannerAsset(economy.streak, progress.completedLessons),
        trailing: (ctx) => _trailingSection(ctx),
      ),
    );
  }

  /// Admin-only dashboard entry first, then achievements/badges for everyone.
  Widget _trailingSection(BuildContext context) {
    final isAdmin = context.watch<SessionProvider>().isAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin) _adminTile(context),
        _achievementsSection(context),
      ],
    );
  }

  /// "لوحة التحكم" tile — visible only when SessionProvider.isAdmin is true
  /// (the server re-checks on every admin RPC regardless of this flag).
  Widget _adminTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Material(
        color: HaffarColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(Routes.admin),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HaffarColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.dashboard_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: HaffarColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'إحصائيات التطبيق وإدارة المستخدمين',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          color: HaffarColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: HaffarColors.grey3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _achievementsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإنجازات',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _bannerGrid(context),
          const SizedBox(height: 20),
          const Text(
            'الشارات',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _achievementBadge(Icons.military_tech, 'المبتدئ', '1/3'),
              _achievementBadge(Icons.workspace_premium, 'المثابر', '2/5'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerGrid(BuildContext context) {
    final streak = context.watch<EconomyProvider>().streak;
    final lessons = context.watch<ProgressProvider>().completedLessons;

    final banners = [
      _Banner(
        key: 'first',
        asset: 'assets/banners/first_banner.jpg',
        title: 'حفّار',
        desc: 'احفر طريقك نحو النجاح',
        unlocked: _bannerUnlocks['first'] ?? true,
      ),
      _Banner(
        key: 'second',
        asset: 'assets/banners/second_banner.jpg',
        title: 'ارضنا الطيبة',
        desc: '١٠ أيام + ٢٠ درس',
        unlocked: _bannerUnlocks['second'] ?? (streak >= 10 && lessons >= 20),
      ),
      _Banner(
        key: 'third',
        asset: 'assets/banners/third_banner_v1.jpg',
        title: 'أنا التوب والباقي فوتوشب',
        desc: '٣٠ يوم + ٤٠ درس',
        unlocked: _bannerUnlocks['third'] ?? (streak >= 30 && lessons >= 40),
      ),
      _Banner(
        key: 'fourth',
        asset: 'assets/banners/third_banner_v2.jpg',
        title: 'أنا التوب والباقي فوتوشب',
        desc: '٣٠ يوم + ٤٠ درس',
        unlocked: _bannerUnlocks['fourth'] ?? (streak >= 30 && lessons >= 40),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: banners.length,
      itemBuilder: (ctx, i) => _bannerCard(ctx, banners[i]),
    );
  }

  Widget _bannerCard(BuildContext context, _Banner b) {
    return InkWell(
      onTap: b.unlocked ? () => _showBannerDialog(b) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: b.unlocked
                ? HaffarColors.outline.withValues(alpha: 0.2)
                : HaffarColors.grey5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              // Banner art always shows; locked cards dim it and overlay
              // the lock on top instead of hiding the image.
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // fitWidth: whole banner visible; the leftover vertical
                    // slack blends into the white card (and the lock scrim).
                    Image.asset(b.asset, fit: BoxFit.fitWidth),
                    if (!b.unlocked) ...[
                      Container(color: Colors.black38),
                      const Center(
                        child: Icon(Icons.lock, size: 32, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    b.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    b.desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 10,
                      color: HaffarColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mid-screen dialog: full banner preview + a flat primary "اختيار"
  /// button that persists the choice server-side and updates the header.
  void _showBannerDialog(_Banner b) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 64)
                      .clamp(240.0, 360.0)
                      .toDouble(),
                  child: AspectRatio(
                    aspectRatio: BannerRepository.aspectRatio,
                    child: Image.asset(b.asset, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HaffarColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await BannerRepository(
                        Supabase.instance.client,
                      ).setSelected(b.key);
                    } catch (e, st) {
                      AppToast.error(
                        e,
                        fallback: 'تعذر حفظ البانر — حاول مرة أخرى',
                        logContext: 'setSelectedBanner',
                        st: st,
                      );
                      return; // keep the dialog open for a retry
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      context.read<EconomyProvider>().applySelectedBanner(
                        b.key,
                      );
                    }
                  },
                  child: const Text(
                    'اختيار',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _achievementBadge(IconData icon, String label, String progress) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: HaffarColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: HaffarColors.primary),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HaffarColors.textPrimary,
            ),
          ),
          Text(
            progress,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10,
              color: HaffarColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
