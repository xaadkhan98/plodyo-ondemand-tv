import 'package:equatable/equatable.dart';

/// Generic wrapper for paginated API responses.
class PaginatedResponse<T> extends Equatable {
  const PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> data;
  final int total;
  final int page;
  final int pageSize;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final rawList = (json['data'] as List<dynamic>?) ?? [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => itemFromJson(item))
        .toList();

    return PaginatedResponse<T>(
      data: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? items.length,
    );
  }

  /// The same page with every row converted, e.g. series into story cards.
  PaginatedResponse<R> map<R>(R Function(T item) convert) => PaginatedResponse(
    data: [for (final item in data) convert(item)],
    total: total,
    page: page,
    pageSize: pageSize,
  );

  @override
  List<Object?> get props => [data, total, page, pageSize];
}
