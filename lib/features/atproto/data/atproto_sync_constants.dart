enum AtprotoSyncOperation {
  create,
  update,
  delete;

  String get value => switch (this) {
    AtprotoSyncOperation.create => 'create',
    AtprotoSyncOperation.update => 'update',
    AtprotoSyncOperation.delete => 'delete',
  };
}

enum SembleSyncCollection {
  card,
  collection,
  collectionLink,
  collectionLinkRemoval;

  String get value => switch (this) {
    SembleSyncCollection.card => 'network.cosmik.card',
    SembleSyncCollection.collection => 'network.cosmik.collection',
    SembleSyncCollection.collectionLink => 'network.cosmik.collectionLink',
    SembleSyncCollection.collectionLinkRemoval => 'network.cosmik.collectionLinkRemoval',
  };

  static Map<String, String> get trackedCollections => {
    SembleSyncCollection.card.value: 'Cards / bookmarks',
    SembleSyncCollection.collection.value: 'Collections / folders',
    SembleSyncCollection.collectionLink.value: 'Collection links',
    SembleSyncCollection.collectionLinkRemoval.value: 'Collection link removals',
  };
}

enum MarginSyncCollection {
  note,
  collection,
  collectionItem;

  String get value => switch (this) {
    MarginSyncCollection.note => 'at.margin.note',
    MarginSyncCollection.collection => 'at.margin.collection',
    MarginSyncCollection.collectionItem => 'at.margin.collectionItem',
  };

  static Map<String, String> get trackedCollections => {
    MarginSyncCollection.note.value: 'Margin notes / annotations',
    MarginSyncCollection.collection.value: 'Margin annotation collections',
    MarginSyncCollection.collectionItem.value: 'Margin annotation collection items',
  };
}

const atprotoAutoSelectBookmarksSettingPrefix = 'atproto.auto_select_bookmarks.';
const atprotoAutoSelectAnnotationsSettingPrefix = 'atproto.auto_select_annotations.';

class AtprotoSyncCollections {
  const AtprotoSyncCollections._();

  static Map<String, String> get trackedCollections => {
    ...SembleSyncCollection.trackedCollections,
    ...MarginSyncCollection.trackedCollections,
  };
}

enum AtprotoSyncLocalTable {
  bookmarks('bookmarks'),
  bookmarkFolders('bookmark_folders'),
  bookmarkCollectionLinks('bookmark_collection_links'),
  annotations('annotations'),
  annotationCollections('annotation_collections'),
  annotationCollectionItems('annotation_collection_items');

  const AtprotoSyncLocalTable(this.value);

  factory AtprotoSyncLocalTable.fromValue(String value) => AtprotoSyncLocalTable.values.firstWhere(
    (table) => table.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Unknown ATProto sync local table.'),
  );

  final String value;
}
