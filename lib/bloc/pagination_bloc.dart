import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'pagination_event.dart';

part 'pagination_state.dart';

class PaginationBloc<T> extends Bloc<PaginationEvent<T>, PaginationState<T>> {
  PaginationBloc(this.preloadedItems)
      : super(preloadedItems.isNotEmpty
            ? PaginationLoaded(items: preloadedItems, hasReachedEnd: false)
            : PaginationInitial<T>());

  final List<T> preloadedItems;

  @override
  Stream<PaginationState<T>> mapEventToState(PaginationEvent<T> event) async* {
    if (event is PageFetch) {
      final currentState = state;
      final fetchEvent = event as PageFetch;
      if (!_hasReachedEnd(currentState)) {
        try {
          if (currentState is PaginationInitial) {
            final firstItems = await fetchEvent.callback(0);
            yield PaginationLoaded(
              items: firstItems,
              hasReachedEnd: firstItems.isEmpty,
            );
            return;
          }
          if (currentState is PaginationLoaded<T>) {
            final newItems = await fetchEvent.callback(
              _getAbsoluteOffset(currentState.items.length),
            );
            yield currentState.copyWith(
              items: currentState.items + newItems,
              hasReachedEnd: newItems.isEmpty,
            );
          }
        } on Exception catch (error) {
          yield PaginationError(error: error);
        }
      }
    }
    if (event is PageRefreshed) {
      final currentState = state;
      final refreshEvent = event as PageRefreshed;
      try {
        if (currentState is PaginationInitial) {
          return;
        }
        yield PaginationInitial();
        if (currentState is PaginationLoaded<T>) {
          final refreshedItems = await refreshEvent.callback(0);
          yield PaginationLoaded(
            items: refreshedItems,
            hasReachedEnd: refreshedItems.isEmpty,
          );
          if (refreshEvent.scrollController.hasClients) {
            refreshEvent.scrollController.jumpTo(0);
          }
        }
      } on Exception catch (error) {
        yield PaginationError(error: error);
      }
    }

    if (event is PageItemChange) {
      final currentState = state;
      final pageItemChange = event as PageItemChange;
      print("item change");
      try {
        if (currentState is PaginationInitial) {
          return;
        }
        print("${currentState is PaginationLoaded}");

        if (currentState is PaginationLoaded<T>) {
          List<T> list = List.from(currentState.items);
          list.removeAt(pageItemChange.index);
          list.insert(pageItemChange.index, pageItemChange.item);
          yield PaginationLoaded(
            items: list,
            hasReachedEnd: list.isEmpty,
          );
        }
      } on Exception catch (error) {
        yield PaginationError(error: error);
      }
    }
  }

  bool _hasReachedEnd(PaginationState state) =>
      state is PaginationLoaded && state.hasReachedEnd;

  int _getAbsoluteOffset(int offset) => offset - preloadedItems.length;
}
