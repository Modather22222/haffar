import '../design_system/colors.dart';
import '../providers/app_provider.dart';
import '../utils/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Banner assets available per achievement tier.
class _Banner {
  final String asset;
  final String title;
  final String desc;
  final bool unlocked;
  const _Banner({required this.asset, required this.title, required this.desc, required this.unlocked});
}

class ProfileScreen extends StatelessWidget {
  final VoidCallback onBack;
  const ProfileScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (_, app, _) => _ProfileBody(app: app),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: HaffarColors.textPrimary,
      elevation: 0,
      actions: [
        IconButton(icon: const Icon(Icons.settings_outlined, size: 24), onPressed: () => context.push(Routes.settings)),
      ],
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final AppProvider app;
  const _ProfileBody({required this.app});

  /// Select banner asset based on user progress thresholds.
  String _selectedBannerAsset() {
    final streak = app.streak;
    final lessons = app.completedLessons;
    if (streak >= 30 && lessons >= 40) {
      // User qualifies for banner 3 — default to v1, picker in achievements
      return 'assets/banners/third_banner_v1.jpg';
    }
    if (streak >= 10 && lessons >= 20) return 'assets/banners/second_banner.jpg';
    return 'assets/banners/first_banner.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          // ── Banner ────────────────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                _selectedBannerAsset(),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 0, right: 0, top: 116,
                child: Center(
                  child: Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: HaffarColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        app.userName.isNotEmpty ? app.userName[0] : 'ح',
                        style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 44),

          // ── Name & grade ──────────────────────────────────────────────────
          Text(app.userName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 20, fontWeight: FontWeight.w800, color: HaffarColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('الصف الثالث متوسط',
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF6f7b64))),
          const SizedBox(height: 24),

          // ── Stats row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _statCard(context, Icons.school, app.completedLessons.toString(), 'دروس مكتملة', HaffarColors.primary),
                const SizedBox(width: 10),
                _statCard(context, Icons.bolt, app.xp.toString(), 'مجموع XP', HaffarColors.primary),
                const SizedBox(width: 10),
                _statCard(context, Icons.local_fire_department, app.streak.toString(), 'أيام الحماسة', HaffarColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Share button (placeholder) ───────────────────────────────────
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20),
          //   child: SizedBox(
          //     width: double.infinity, height: 48,
          //     child: OutlinedButton.icon(
          //       style: OutlinedButton.styleFrom(foregroundColor: HaffarColors.primaryDark, side: const BorderSide(color: HaffarColors.primary, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          //       onPressed: () {},
          //       icon: const Icon(Icons.share, size: 18),
          //       label: const Text('شارك تقدمي', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 15, fontWeight: FontWeight.w700)),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 24),

          // ── Banners / Achievements section ────────────────────────────────
          _achievementsSection(context),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: accent),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 20, fontWeight: FontWeight.w800, color: HaffarColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: Color(0xFF6f7b64))),
          ],
        ),
      ),
    );
  }

  Widget _achievementsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإنجازات', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 17, fontWeight: FontWeight.w800, color: HaffarColors.textPrimary)),
          const SizedBox(height: 12),
          _bannerGrid(context),
          const SizedBox(height: 20),
          const Text('الشارات', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 17, fontWeight: FontWeight.w800, color: HaffarColors.textPrimary)),
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
    final streak = context.watch<AppProvider>().streak;
    final lessons = context.watch<AppProvider>().completedLessons;

    final banners = [
      _Banner(
        asset: 'assets/banners/first_banner.jpg',
        title: 'حفّار',
        desc: 'حفر طريقك نحو النجاح',
        unlocked: true,
      ),
      _Banner(
        asset: 'assets/banners/second_banner.jpg',
        title: 'المثابر',
        desc: '١٠ أيام + ٢٠ درس',
        unlocked: streak >= 10 && lessons >= 20,
      ),
      _Banner(
        asset: 'assets/banners/third_banner_v1.jpg',
        title: 'أنا التوب والباقي فوتوشب',
        desc: '٣٠ يوم + ٤٠ درس',
        unlocked: streak >= 30 && lessons >= 40,
      ),
      _Banner(
        asset: 'assets/banners/third_banner_v2.jpg',
        title: 'أنا التوب والباقي فوتوشب',
        desc: 'البنات كمان!',
        unlocked: streak >= 30 && lessons >= 40,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5),
      itemCount: banners.length,
      itemBuilder: (ctx, i) => _bannerCard(ctx, banners[i]),
    );
  }

  Widget _bannerCard(BuildContext context, _Banner b) {
    return InkWell(
      onTap: b.unlocked ? () => _showBannerPicker(context, b) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: b.unlocked ? Colors.white : HaffarColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: b.unlocked ? HaffarColors.outline.withValues(alpha: 0.2) : HaffarColors.grey5),
        ),
        child: Column(children: [
          Expanded(
            child: b.unlocked
                ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: Image.asset(b.asset, fit: BoxFit.cover))
                : Center(child: Icon(Icons.lock, size: 32, color: HaffarColors.grey3)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              Text(b.title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w700)),
              Text(b.desc, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, color: Color(0xFF6f7b64))),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showBannerPicker(BuildContext context, _Banner selected) {
    final banners = [
      _Banner(asset: 'assets/banners/third_banner_v1.jpg', title: 'الرجل', desc: '', unlocked: true),
      _Banner(asset: 'assets/banners/third_banner_v2.jpg', title: 'الأنثى', desc: '', unlocked: true),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر بانرك', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: banners.map((b) {
          return InkWell(
            onTap: () {
              // Save selection (persist via SharedPreferences or DB in future)
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم اختيار: ${b.title}')));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(b.asset, width: 80, height: 53, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Text(b.title, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }).toList()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ],
      ),
    );
  }

  Widget _achievementBadge(IconData icon, String label, String progress) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: HaffarColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 32, color: HaffarColors.primary),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 11, fontWeight: FontWeight.w700, color: HaffarColors.textPrimary)),
          Text(progress, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, color: Color(0xFF6f7b64))),
        ],
      ),
    );
  }
}
