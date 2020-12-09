part of 'pagination_bloc.dart';

@immutable
abstract class PaginationEvent<T> {}

class PageFetch<T> implements PaginationEvent<T> {
  PageFetch({
    @required this.callback,
  });

  final Future<List<T>> Function(int currentListSize) callback;

  PageFetch<T> copyWith({
    Future<List<T>> Function(int currentListSize) callback,
  }) {
    return PageFetch<T>(
      callback: callback ?? this.callback,
    );
  }
}

class PageRefreshed<T> implements PaginationEvent<T> {
  PageRefreshed({
    @required this.callback,
    @required this.scrollController,
  });

  final Future<List<T>> Function(int currentListSize) callback;
  final ScrollController scrollController;

  PageRefreshed<T> copyWith(
      {Future<List<T>> Function(int currentListSize) callback,
      ScrollController scrollController}) {
    return PageRefreshed<T>(
      callback: callback ?? this.callback,
      scrollController: scrollController ?? this.scrollController,
    );
  }
}

class PageItemChange<T> implements PaginationEvent<T> {
  PageItemChange({@required this.changeItem});

  final Function changeItem;

  PageItemChange<T> copyWith({Function changeItem}) {
    return PageItemChange<T>(changeItem: changeItem ?? this.changeItem);
  }
}
