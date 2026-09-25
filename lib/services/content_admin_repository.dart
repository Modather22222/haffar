import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson.dart';
import '../models/question.dart';
import '../utils/content_validators.dart';

/// Admin-side CRUD for curriculum content.
///
/// Simple row edits go through PostgREST under the `fn_is_admin()` RLS
/// policies; structural changes (unit create/delete, lesson swap, question
/// reorder) go through SECURITY DEFINER RPCs that enforce the curriculum
/// invariants (unit i owns lessons 3i..3i+2). Images upload to the public
/// `content` bucket, which only accepts writes from admins.
class ContentAdminRepository {
  ContentAdminRepository(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------- subjects

  Future<void> insertSubject({
    required String id,
    required String name,
    required String icon,
    required String colorHex,
    required int sortOrder,
  }) async {
    await _client.from('subjects').insert({
      'id': id,
      'name': name,
      'icon': icon,
      'color_hex': colorHex,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateSubject(
    String id, {
    String? name,
    String? icon,
    String? colorHex,
    int? sortOrder,
  }) async {
    final patch = <String, dynamic>{
      'name': ?name,
      'icon': ?icon,
      'color_hex': ?colorHex,
      'sort_order': ?sortOrder,
    };
    if (patch.isEmpty) return;
    await _client.from('subjects').update(patch).eq('id', id);
  }

  Future<void> deleteSubject(String id) async {
    await _client.from('subjects').delete().eq('id', id);
  }

  // ------------------------------------------------------------------- units

  Future<void> renameUnit(String unitId, String title) async {
    await _client.from('units').update({'title': title}).eq('id', unitId);
  }

  /// Appends the next unit with three lesson shells (admin_create_unit RPC).
  /// Returns the created `{id, unit_index}` object.
  Future<Map<String, dynamic>> createUnit(
    String subjectId,
    String title,
  ) async {
    final result = await _client.rpc(
      'admin_create_unit',
      params: {'p_subject_id': subjectId, 'p_title': title},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Deletes the LAST unit with its lessons and questions (admin_delete_unit).
  Future<void> deleteUnit(String subjectId, int unitIndex) async {
    await _client.rpc(
      'admin_delete_unit',
      params: {'p_subject_id': subjectId, 'p_unit_index': unitIndex},
    );
  }

  // ----------------------------------------------------------------- lessons

  Future<void> updateLesson({
    required String lessonId,
    required String title,
    required String summary,
    required List<String> keyPoints,
  }) async {
    await _client
        .from('lessons')
        .update({'title': title, 'summary': summary, 'key_points': keyPoints})
        .eq('id', lessonId);
  }

  /// Exchanges two lesson positions together with their questions
  /// (admin_swap_lessons RPC).
  Future<void> swapLessons(String subjectId, int from, int to) async {
    await _client.rpc(
      'admin_swap_lessons',
      params: {'p_subject_id': subjectId, 'p_from': from, 'p_to': to},
    );
  }

  // --------------------------------------------------------------- questions

  Future<Lesson> fetchLesson(String lessonId) async {
    final row = await _client
        .from('lessons')
        .select()
        .eq('id', lessonId)
        .single();
    return Lesson.fromMap(row);
  }

  Future<List<Question>> fetchLessonQuestions(
    String subjectId,
    int lessonIndex,
  ) async {
    final rows = await _client
        .from('questions')
        .select()
        .eq('subject_id', subjectId)
        .eq('lesson_index', lessonIndex)
        .order('sort_order');
    return rows.map(Question.fromMap).toList();
  }

  Future<Question> fetchQuestion(String id) async {
    final row = await _client.from('questions').select().eq('id', id).single();
    return Question.fromMap(row);
  }

  Future<void> insertQuestion(Map<String, dynamic> row) async {
    await _client.from('questions').insert(row);
  }

  Future<void> updateQuestion(String id, Map<String, dynamic> patch) async {
    if (patch.isEmpty) return;
    await _client.from('questions').update(patch).eq('id', id);
  }

  Future<void> deleteQuestion(String id) async {
    await _client.from('questions').delete().eq('id', id);
  }

  /// Sets sort_order = position for a lesson's questions
  /// (admin_reorder_questions RPC; p_ids must be exactly that lesson's ids).
  Future<void> reorderQuestions(
    String subjectId,
    int lessonIndex,
    List<String> ids,
  ) async {
    await _client.rpc(
      'admin_reorder_questions',
      params: {
        'p_subject_id': subjectId,
        'p_lesson_index': lessonIndex,
        'p_ids': ids,
      },
    );
  }

  // ----------------------------------------------------------------- images

  /// Uploads image bytes to the public `content` bucket and returns the
  /// public URL to store in markdown/`image_url`.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String mimeType,
    String folder = 'editor',
  }) async {
    final bytesError = validateImageBytes(bytes.length);
    if (bytesError != null) throw ArgumentError(bytesError);
    final path = contentImagePath(
      mimeType: mimeType,
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
      randomHex: _randomHex(6),
      folder: folder,
    );
    await _client.storage
        .from('content')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return _client.storage.from('content').getPublicUrl(path);
  }

  static final Random _secureRandom = Random.secure();

  static String _randomHex(int length) {
    const hex = '0123456789abcdef';
    return List.generate(length, (_) => hex[_secureRandom.nextInt(16)]).join();
  }

  /// Deterministic TEXT id for a new question inside a lesson:
  /// `<subject>_l<lesson>_q<n>` with the lowest free n (matching the
  /// existing seed convention), falling back to a random suffix.
  static String nextQuestionId({
    required String subjectId,
    required int lessonIndex,
    required Set<String> existingIds,
  }) {
    final prefix = '${subjectId}_l${lessonIndex}_q';
    for (var n = 1; n <= 9999; n++) {
      final candidate = '$prefix$n';
      if (!existingIds.contains(candidate)) return candidate;
    }
    return '$prefix${_randomHex(6)}';
  }
}
