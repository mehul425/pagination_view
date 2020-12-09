part of pagination_view;


typedef PaginationBuilder<T> = Future<List<T>> Function(int currentListSize);

enum PaginationViewType { listView, gridView }

class PaginationView<T> extends StatefulWidget {
  const PaginationView({
    Key key,
    @required this.itemBuilder,
    @required this.pageFetch,
    @required this.onEmpty,
    @required this.onError,
    this.pageRefresh,
    this.pullToRefresh = false,
    this.gridDelegate =
    const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    this.preloadedItems = const [],
    this.initialLoader = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.paginationViewType = PaginationViewType.listView,
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsets.all(0),
    this.physics,
    this.separatorBuilder,
    this.scrollController,
  }) : super(key: key);

  final Widget bottomLoader;
  final Widget initialLoader;
  final Widget onEmpty;
  final EdgeInsets padding;
  final PaginationBuilder<T> pageFetch;
  final PaginationBuilder<T> pageRefresh;
  final ScrollPhysics physics;
  final List<T> preloadedItems;
  final bool pullToRefresh;
  final bool reverse;
  final Axis scrollDirection;
  final SliverGridDelegate gridDelegate;
  final PaginationViewType paginationViewType;
  final bool shrinkWrap;
  final ScrollController scrollController;

  @override
  PaginationViewState<T> createState() => PaginationViewState<T>();

  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget Function(BuildContext, int) separatorBuilder;

  final Widget Function(dynamic) onError;
}

class PaginationViewState<T> extends State<PaginationView<T>> {
  PaginationBloc<T> _bloc;
  ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginationBloc<T>, PaginationState<T>>(
      cubit: _bloc,
      builder: (context, state) {
        if (state is PaginationInitial<T>) {
          return widget.initialLoader;
        } else if (state is PaginationError<T>) {
          return widget.onError(state.error);
        } else {
          final loadedState = state as PaginationLoaded<T>;
          if (loadedState.items.isEmpty) {
            return widget.onEmpty;
          }
          if (widget.paginationViewType == PaginationViewType.gridView) {
            if (widget.pullToRefresh) {
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: _buildNewGridView(loadedState),
              );
            }
            return _buildNewGridView(loadedState);
          }
          if (widget.pullToRefresh) {
            return RefreshIndicator(
              onRefresh: () async => refresh(),
              child: _buildNewListView(loadedState),
            );
          }
          return _buildNewListView(loadedState);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _bloc = PaginationBloc<T>(widget.preloadedItems)
      ..add(PageFetch(callback: widget.pageFetch));
  }

  Widget _buildNewListView(PaginationLoaded<T> loadedState) {
    return ListView.separated(
      controller: _scrollController,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      padding: widget.padding,
      separatorBuilder:
      widget.separatorBuilder ?? ((_, __) => EmptySeparator()),
      itemCount: loadedState.hasReachedEnd
          ? loadedState.items.length
          : loadedState.items.length + 1,
      itemBuilder: (context, index) {
        if (index >= loadedState.items.length) {
          _bloc.add(PageFetch(callback: widget.pageFetch));
          return widget.bottomLoader;
        }
        return widget.itemBuilder(context, loadedState.items[index], index);
      },
    );
  }

  Widget _buildNewGridView(PaginationLoaded<T> loadedState) {
    return GridView.builder(
      gridDelegate: widget.gridDelegate,
      controller: _scrollController,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      padding: widget.padding,
      itemCount: loadedState.hasReachedEnd
          ? loadedState.items.length
          : loadedState.items.length + 1,
      itemBuilder: (context, index) {
        if (index >= loadedState.items.length) {
          _bloc.add(PageFetch(callback: widget.pageFetch));
          return widget.bottomLoader;
        }
        return widget.itemBuilder(context, loadedState.items[index], index);
      },
    );
  }

  void refresh() {
    if (widget.pageRefresh == null) {
      throw Exception('pageRefresh parameter cannot be null');
    }
    _bloc.add(PageRefreshed(
      callback: widget.pageRefresh,
      scrollController: _scrollController,
    ));
  }


  void itemChange(T item, int index) {
    print("item change $item $index");
    _bloc.add(PageItemChange( item: item,index: index));
  }
}
