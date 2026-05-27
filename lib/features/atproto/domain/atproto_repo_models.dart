class AtprotoRepoWriteResult {
  const AtprotoRepoWriteResult({required this.uri, required this.cid});

  final String uri;
  final String cid;
}

class AtprotoRepoRecord {
  const AtprotoRepoRecord({required this.uri, required this.cid, required this.value});

  final String uri;
  final String? cid;
  final Map<String, dynamic> value;
}

class AtprotoRepoListPage {
  const AtprotoRepoListPage({required this.records, this.cursor});

  final List<AtprotoRepoRecord> records;
  final String? cursor;
}
