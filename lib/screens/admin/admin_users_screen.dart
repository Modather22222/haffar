import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
import '../../utils/routes.dart';
import 'admin_widgets.dart';

/// Tab 2 — searchable, paged list of all users (admin_users RPC).
/// Tapping a row opens the detail/actions screen (/admin/user?id=…).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 50;

  late final AdminRepository _repo;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<AdminUserRow> _users = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  String _search = '';

  /// 'all' | 'active_7d' | 'dormant_7d' (audience segment filter).
  String _segment = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _repo = AdminRepository(Supabase.instance.client);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // keeps the clear (x) icon in sync while typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search = value.trim();
      _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await _repo.fetchUsers(
        search: _search,
        segment: _segment == 'all' ? null : _segment,
        limit: _pageSize,
        offset: reset ? 0 : _users.length,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _users.clear();
        _users.addAll(page.users);
        _total = page.total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _users.isEmpty) return const AdminLoadingView();
    if (_error != null && _users.isEmpty) {
      return AdminErrorView(
        message: adminMessage(_error),
        onRetry: () => _load(reset: true),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد…',
                hintStyle: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                filled: true,
                fillColor: HaffarColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: HaffarColors.outline.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: HaffarColors.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final opt in const [
                  ('all', 'الكل'),
                  ('active_7d', 'نشطون (7 أيام)'),
                  ('dormant_7d', 'خاملون (7 أيام)'),
                ])
                  ChoiceChip(
                    label: Text(
                      opt.$2,
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 12,
                        fontWeight: _segment == opt.$1
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    selected: _segment == opt.$1,
                    onSelected: (_) {
                      setState(() => _segment = opt.$1);
                      _load(reset: true);
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${fmtInt(_total)} مستخدم',
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _users.isEmpty
                ? const AdminEmptyText('لا توجد نتائج')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _users.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _users.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Center(
                            child: _loadingMore
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: () => _load(reset: false),
                                    child: const Text(
                                      'عرض المزيد',
                                      style: TextStyle(fontFamily: kAdminFont),
                                    ),
                                  ),
                          ),
                        );
                      }
                      return _UserTile(
                        user: _users[i],
                        onTap: () => context.push(
                          '${Routes.adminUser}?id=${_users[i].id}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool get _hasMore => _users.length < _total;
}

class _UserTile extends StatelessWidget {
  final AdminUserRow user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  String get _initial {
    final name = user.displayName.trim();
    if (name.isEmpty) {
      return user.email.isNotEmpty ? user.email[0].toUpperCase() : '؟';
    }
    return name[0];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HaffarColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: HaffarColors.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: HaffarColors.primary.withValues(alpha: 0.15),
              child: Text(
                _initial,
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontWeight: FontWeight.w800,
                  color: HaffarColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName.isEmpty
                              ? user.email
                              : user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kAdminFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HaffarColors.textPrimary,
                          ),
                        ),
                      ),
                      if (user.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: HaffarColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'أدمن',
                            style: TextStyle(
                              fontFamily: kAdminFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HaffarColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (user.displayName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 12,
                        color: HaffarColors.grey2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _miniChip('XP ${fmtInt(user.xp)}'),
                      _miniChip('سلسلة ${fmtInt(user.streak)}'),
                      _miniChip('دروس ${fmtInt(user.lessonsDone)}'),
                      if (user.league.isNotEmpty) _miniChip(user.league),
                      if (user.lastActiveAt != null)
                        _miniChip(
                          'آخر نشاط ${DateFormat('MM/dd').format(user.lastActiveAt!)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: HaffarColors.grey3),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: HaffarColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 10,
          color: HaffarColors.textSecondary,
        ),
      ),
    );
  }
}
