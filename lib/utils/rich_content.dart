import 'package:flutter/widgets.dart';
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

/// Whether [offset] sits at the start of a line: at the document start or
/// right after a newline. Walks the delta ops (embeds count as one position)
/// because `Document.toPlainText` renders embeds through builders which may
/// return an empty string, desyncing offsets.
bool _isLineStart(Delta content, int offset) {
  if (offset <= 0) return true;
  var pos = 0;
  for (final op in content.operations) {
    final length = op.length ?? 0;
    if (pos + length >= offset) {
      final data = op.data;
      if (data is! String) return false; // embed right before the cursor
      final rel = offset - 1 - pos;
      return rel >= 0 && data[rel] == '\n';
    }
    pos += length;
  }
  return true;
}

/// Makes sure the snippet ends with a line terminator so inserting it can
/// never glue the following document text onto its last line.
void _ensureEndsWithNewline(Delta snippet) {
  if (snippet.isEmpty) return;
  final last = snippet.operations.last;
  if (!last.isInsert) return;
  final data = last.data;
  if (data is String && data.endsWith('\n')) return;
  snippet.insert('\n');
}

/// Inserts [markdown] into [controller] at [at] (the current selection when
/// omitted) as a block insert: a newline is prepended when the position is
/// not already at a line start, the snippet is composed in one undoable
/// change, and the caret lands after the inserted content. Clamps [at] into
/// the document so stale offsets (captured before a sheet opened) stay safe.
void insertMarkdownAt(QuillController controller, String markdown, {int? at}) {
  final snippet = markdownToDelta(markdown);
  if (snippet.isEmpty) return;
  _ensureEndsWithNewline(snippet);

  final content = controller.document.toDelta();
  final maxOffset = controller.document.length - 1;
  var offset =
      at ??
      (controller.selection.isValid ? controller.selection.end : maxOffset);
  if (offset < 0) offset = 0;
  if (offset > maxOffset) offset = maxOffset;

  final change = Delta()..retain(offset);
  var inserted = 0;
  if (!_isLineStart(content, offset)) {
    change.insert('\n');
    inserted += 1;
  }
  for (final op in snippet.operations) {
    change.push(op);
    inserted += op.length ?? 0;
  }
  controller.compose(
    change,
    TextSelection.collapsed(offset: offset),
    ChangeSource.local,
  );
  controller.updateSelection(
    TextSelection.collapsed(offset: offset + inserted),
    ChangeSource.local,
  );
}
