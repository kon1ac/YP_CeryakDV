class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  int get totalPages => total == 0 ? 1 : (total / size).ceil();

  bool get hasPrevious => page > 1;

  bool get hasNext => page < totalPages;

  int get firstIndex => total == 0 ? 0 : (page - 1) * size + 1;

  int get lastIndex => total == 0 ? 0 : (page - 1) * size + items.length;

  PageResult.empty()
      : items = <T>[],
        page = 1,
        size = 10,
        total = 0;
}
