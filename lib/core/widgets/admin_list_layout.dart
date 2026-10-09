import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/auth_exception.dart';
import '../../data/models/paginated_response.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';
import 'choice_group.dart';
import 'loading.dart';
import 'page_title.dart';
import 'pagination.dart';
import 'status_message.dart';

/// The API's default page size for admin lists.
const int defaultPageSize = 25;

/// The API's largest page: a picker takes one big page rather than growing paging inside a form.
const int pickerPageSize = 100;

/// One filtered, paged admin list: its query state, the page on screen, and loading and error.
/// A response that arrives after a newer request is dropped, so fast filter changes never show stale rows.
class PagedList<T, F> extends ChangeNotifier {
  PagedList({required this._filter, required this.fetch});

  final Future<PaginatedResponse<T>> Function(F filter, int page) fetch;

  F _filter;
  int _page = 1;
  int _request = 0;
  PaginatedResponse<T>? data;
  bool loading = false;
  String? error;

  F get filter => _filter;

  Future<void> load() async {
    final request = ++_request;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await fetch(_filter, _page);
      if (request != _request) return;
      data = result;
      // A page can empty under the reader (its last row revoked); step back to the last real page.
      final lastPage = Pagination.lastPageOf(result.total, result.pageSize);
      if (result.data.isEmpty && _page > lastPage) {
        _page = lastPage;
        load();
        return;
      }
    } catch (e) {
      if (request != _request) return;
      error = messageOf(e, 'Could not load this list.');
    }
    loading = false;
    notifyListeners();
  }

  void setFilter(F filter) {
    _filter = filter;
    // Page 3 of "all" is rarely a page at all once a status is applied.
    _page = 1;
    load();
  }

  void setPage(int page) {
    _page = page;
    load();
  }
}

/// The shell every admin list shares: heading, status chips, rows and paging, plus the four states a
/// list has — loading, error, empty and filled — which is the part that gets half-built when written five times.
class AdminListLayout<T, F> extends StatelessWidget {
  const AdminListLayout({
    super.key,
    required this.list,
    required this.title,
    required this.description,
    required this.filters,
    required this.emptyMessage,
    required this.rowBuilder,
    this.icon,
    this.action,
    this.secondaryFilter,
    this.notice,
  });

  final PagedList<T, F> list;
  final String title;
  final String description;
  final List<Choice<F>> filters;
  final String emptyMessage;
  final Widget Function(T item) rowBuilder;
  final IconData? icon;

  /// Opposite the heading; usually the primary action.
  final Widget? action;

  /// A second control under the status chips, e.g. scoping rooms to a property.
  final Widget? secondaryFilter;

  /// Shown above the rows in every state, e.g. a failed row action.
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final page = list.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(
          icon: icon,
          title: title,
          subtitle: description,
          action: action,
        ),
        const SizedBox(height: 1.75 * rem),
        ChoiceGroup<F>(
          value: list.filter,
          options: filters,
          onChanged: list.setFilter,
          layout: ChoiceLayout.chips,
          // With no primary action to land on, first focus goes to the filter.
          autofocus: action == null,
        ),
        if (secondaryFilter != null) ...[
          const SizedBox(height: 1.25 * rem),
          secondaryFilter!,
        ],
        if (list.error != null) ...[
          const SizedBox(height: 1.5 * rem),
          StatusMessage(tone: StatusTone.error, message: list.error!),
        ],
        // Outside the filled branch: whether an action failed has nothing to do with whether rows are showing.
        if (notice != null) ...[const SizedBox(height: 1.5 * rem), notice!],
        if (list.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5 * rem),
            child: Center(child: LoadingDots(color: TvColors.primary)),
          )
        else if (page != null && page.data.isNotEmpty) ...[
          const SizedBox(height: 1.5 * rem),
          for (final (index, item) in page.data.indexed) ...[
            if (index > 0) const SizedBox(height: 0.75 * rem),
            rowBuilder(item),
          ],
        ] else if (list.error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5 * rem),
            child: Column(
              spacing: rem,
              children: [
                const Icon(
                  LucideIcons.inbox,
                  size: 3 * rem,
                  color: TvColors.mutedForeground,
                ),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TvText.base.copyWith(color: TvColors.mutedForeground),
                ),
              ],
            ),
          ),
        if (!list.loading && page != null)
          Pagination(
            page: page.page,
            pageSize: page.pageSize,
            total: page.total,
            onChanged: list.setPage,
          ),
      ],
    );
  }
}
