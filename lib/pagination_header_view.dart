part of pagination_view;

enum PaginationHeaderViewType { listView, gridView }

class PaginationHeaderView<T> extends StatefulWidget {
  const PaginationHeaderView({
    Key key,
    @required this.itemBuilder,
    @required this.headerChild,
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
    this.paginationViewType = PaginationHeaderViewType.listView,
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
  final Widget headerChild;
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
  final PaginationHeaderViewType paginationViewType;
  final bool shrinkWrap;
  final ScrollController scrollController;

  @override
  PaginationHeaderViewState<T> createState() => PaginationHeaderViewState<T>();

  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget Function(BuildContext, int) separatorBuilder;
  final Widget Function(dynamic) onError;
}

class PaginationHeaderViewState<T> extends State<PaginationHeaderView<T>> {
  ScrollController _scrollController;
  PaginationBloc<T> _bloc;

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
          if (widget.paginationViewType == PaginationHeaderViewType.gridView) {
            if (widget.pullToRefresh) {
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: _buildNewHeaderGridView(loadedState),
              );
            }
            return _buildNewHeaderGridView(loadedState);
          }

          if (widget.pullToRefresh) {
            return RefreshIndicator(
              onRefresh: () async => refresh(),
              child: _buildNewHeaderListView(loadedState),
            );
          }
          return _buildNewHeaderListView(loadedState);
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

  Widget _buildNewHeaderListView(PaginationLoaded<T> loadedState) {
    return CustomScrollView(
      controller: _scrollController,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      slivers: [
        SliverToBoxAdapter(child: widget.headerChild),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= loadedState.items.length) {
                _bloc.add(PageFetch(callback: widget.pageFetch));
                return widget.bottomLoader;
              }
              return widget.itemBuilder(
                  context, loadedState.items[index], index);
            },
            childCount: loadedState.hasReachedEnd
                ? loadedState.items.length
                : loadedState.items.length + 1,
          ),
        )
      ],
    );
  }

  Widget _buildNewHeaderGridView(PaginationLoaded<T> loadedState) {
    return CustomScrollView(
      controller: _scrollController,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      slivers: [
        SliverToBoxAdapter(child: widget.headerChild),
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= loadedState.items.length) {
                _bloc.add(PageFetch(callback: widget.pageFetch));
                return widget.bottomLoader;
              }
              return widget.itemBuilder(
                  context, loadedState.items[index], index);
            },
            childCount: loadedState.hasReachedEnd
                ? loadedState.items.length
                : loadedState.items.length + 1,
          ),
          gridDelegate: widget.gridDelegate,
        )
      ],
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
    _bloc.add(PageItemChange( item: item,index: index));
  }
}
