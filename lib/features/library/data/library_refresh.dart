import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/library/data/library_repository.dart';
import 'package:marker/features/library/data/library_search_repository.dart';

void invalidateLibraryData(Ref ref, {String? pageId}) {
  ref.invalidate(librarySnapshotProvider);
  ref.invalidate(allAnnotationGroupsProvider);
  ref.invalidate(librarySearchProvider);
  if (pageId == null) {
    ref.invalidate(libraryPageDetailProvider);
  } else {
    ref.invalidate(libraryPageDetailProvider(pageId));
  }
}

void invalidateLibraryWidgetData(WidgetRef ref, {String? pageId}) {
  ref.invalidate(librarySnapshotProvider);
  ref.invalidate(allAnnotationGroupsProvider);
  ref.invalidate(librarySearchProvider);
  if (pageId == null) {
    ref.invalidate(libraryPageDetailProvider);
  } else {
    ref.invalidate(libraryPageDetailProvider(pageId));
  }
}
