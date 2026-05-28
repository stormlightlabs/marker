enum SembleSyncCollection {
  card('network.cosmik.card'),
  collection('network.cosmik.collection'),
  collectionLink('network.cosmik.collectionLink'),
  collectionLinkRemoval('network.cosmik.collectionLinkRemoval');

  const SembleSyncCollection(this.value);

  final String value;

  static Map<String, String> get trackedCollections => {
    SembleSyncCollection.card.value: 'Cards / bookmarks',
    SembleSyncCollection.collection.value: 'Collections / folders',
    SembleSyncCollection.collectionLink.value: 'Collection links',
    SembleSyncCollection.collectionLinkRemoval.value: 'Collection link removals',
  };
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
