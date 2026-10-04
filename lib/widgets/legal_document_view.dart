import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/colors.dart';

/// One rendered node inside a [LegalDocumentView] — mirrors the structure of
/// the plain-text legal documents (privacy.txt / terms.txt).
enum LegalNodeType { heading, subheading, paragraph, bullet, gap }

class LegalNode {
  const LegalNode._(this.type, this.text);

  const LegalNode.heading(String text) : this._(LegalNodeType.heading, text);
  const LegalNode.subheading(String text)
    : this._(LegalNodeType.subheading, text);
  const LegalNode.paragraph(String text)
    : this._(LegalNodeType.paragraph, text);
  const LegalNode.bullet(String text) : this._(LegalNodeType.bullet, text);
  const LegalNode.gap() : this._(LegalNodeType.gap, '');

  final LegalNodeType type;
  final String text;
}

/// Full-screen scrollable viewer for a legal document (privacy policy /
/// terms of service) with the app's standard AppBar + back navigation.
class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({
    super.key,
    required this.title,
    required this.nodes,
  });

  final String title;
  final List<LegalNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [for (final node in nodes) _buildNode(node)],
        ),
      ),
    );
  }

  Widget _buildNode(LegalNode node) {
    switch (node.type) {
      case LegalNodeType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            node.text,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
        );
      case LegalNodeType.subheading:
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            node.text,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: HaffarColors.primaryDark,
            ),
          ),
        );
      case LegalNodeType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            node.text,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              height: 1.7,
              color: HaffarColors.textSecondary,
            ),
          ),
        );
      case LegalNodeType.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    height: 1.7,
                    color: HaffarColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.text,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    height: 1.7,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      case LegalNodeType.gap:
        return const SizedBox(height: 8);
    }
  }
}
