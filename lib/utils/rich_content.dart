import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

/// Rich content (lesson summaries, question text) is stored as
/// GitHub-Flavored Markdown — the DB columns predate the editor and stay
/// human-readable and markdown-renderable for students. The admin editor
/// works on Quill Delta; these helpers convert between the two.
final md.Document _markdownDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
  blockSyntaxes: [const EmbeddableTableSyntax()],
);

/// Parses GFM markdown into a Quill [Delta] (images become embeds).
/// Soft line breaks are honored: a single newline starts a new line.
Delta markdownToDelta(String markdown) {
  if (markdown.trim().isEmpty) return Delta();
  return MarkdownToDelta(
    markdownDocument: _markdownDocument,
    softLineBreak: true,
    customElementToBlockAttribute: {
      'h4': (_) => [HeaderAttribute(level: 4)],
      'h5': (_) => [HeaderAttribute(level: 5)],
      'h6': (_) => [HeaderAttribute(level: 6)],
    },
    customElementToEmbeddable: {
      EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax,
    },
  ).convert(markdown);
}

/// Serializes a Quill [Delta] back to markdown. Relaxed escaping keeps stored
/// content clean (no `\.` litter); a line that literally starts with markdown
/// syntax may re-parse as markup, which the WYSIWYG editor shows immediately.
String deltaToMarkdown(Delta delta) {
  if (delta.isEmpty) return '';
  return DeltaToMarkdown(
    customContentHandler: DeltaToMarkdown.escapeSpecialCharactersRelaxed,
    customEmbedHandlers: {
      EmbeddableTable.tableType: EmbeddableTable.toMdSyntax,
    },
  ).convert(delta).trim();
}

/// Editor bootstrap: markdown from the DB → editable [Document].
Document documentFromMarkdown(String markdown) {
  final delta = markdownToDelta(markdown);
  // Document.fromDelta rejects an empty delta; Document() starts with '\n'.
  return delta.isEmpty ? Document() : Document.fromDelta(delta);
}

/// Save path: editor [Document] → markdown for the DB.
String markdownFromDocument(Document document) =>
    deltaToMarkdown(document.toDelta());
