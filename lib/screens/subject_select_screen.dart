import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/colors.dart';
import '../providers/content_provider.dart';
import '../utils/routes.dart';

class SubjectSelectScreen extends StatelessWidget {
  const SubjectSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final subjects = content.subjects;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر مادتك'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content.status == ContentStatus.error
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        content.errorMessage ??
                            'تعذر تحميل المواد — تحقق من الإنترنت',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15,
                          color: HaffarColors.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => content.loadContent(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : content.status == ContentStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: HaffarColors.primary),
                )
              : subjects.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مواد متاحة حالياً',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16,
                      color: HaffarColors.textSecondary,
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: subjects.map((subject) {
                    return InkWell(
                      onTap: () => context.push(
                        '${Routes.lessonPath}?subject=${subject.id}',
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: HaffarColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (subject.imageAsset != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  subject.imageAsset!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Text(
                                subject.icon,
                                style: const TextStyle(fontSize: 40),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              subject.name,
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }
}
