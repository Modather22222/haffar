import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'icon': '🔥', 'name': 'محرض البدء', 'desc': 'أكمل أول درس', 'unlocked': true},
      {'icon': '⚡', 'name': 'سريع البديهة', 'desc': 'أجب على 10 أسئلة', 'unlocked': true},
      {'icon': '🏆', 'name': 'بطل المذاكرة', 'desc': 'أكمل مسار كامل', 'unlocked': false},
      {'icon': '💎', 'name': 'جامع الجواهر', 'desc': 'اجمع 500 جوهرة', 'unlocked': false},
      {'icon': '📚', 'name': 'قارئ نهم', 'desc': 'اقرأ 50 قراءة', 'unlocked': false},
      {'icon': '🌟', 'name': 'نجمة السبع', 'desc': 'احتفظ بسلسلة 7 أيام', 'unlocked': false},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('الإنجازات'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16),
          child: GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9,
            children: achievements.map((a) {
              final unlocked = a['unlocked'] as bool;
              return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                color: unlocked ? Colors.white : HaffarColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: unlocked ? HaffarColors.primary.withValues(alpha: 0.3) : HaffarColors.outline.withValues(alpha: 0.2)),
              ), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(a['icon'] as String, style: TextStyle(fontSize: 36, color: unlocked ? Colors.black : Colors.grey[400]!)),
                const SizedBox(height: 8),
                Text(a['name'] as String, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                Text(a['desc'] as String, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: Color(0xFF3f4a36)), textAlign: TextAlign.center),
                if (!unlocked) const Icon(Icons.lock, size: 16, color: Color(0xFF3f4a36)),
              ]));
            }).toList()),
        ),
      ),
    );
  }
}
