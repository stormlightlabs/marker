enum SembleSyncCollection {
  card('network.cosmik.card'),
  collection('network.cosmik.collection'),
  collectionLink('network.cosmik.collectionLink'),
  collectionLinkRemoval('network.cosmik.collectionLinkRemoval');

  const SembleSyncCollection(this.value);

  final String value;
}

enum SembleSyncLocalTable {
  bookmarks('bookmarks'),
  bookmarkFolders('bookmark_folders'),
  bookmarkCollectionLinks('bookmark_collection_links'),
  annotations('annotations');

  const SembleSyncLocalTable(this.value);

  factory SembleSyncLocalTable.fromValue(String value) => SembleSyncLocalTable.values.firstWhere(
    (table) => table.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Unknown Semble sync local table.'),
  );

  final String value;
}
