const invalidHandleSentinel = '__marker_invalid_atproto_handle__';

String? normalizeHandle(String? handle) {
  final trimmed = handle?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  if (withoutAt.isEmpty || withoutAt.contains(RegExp(r'\s')) || withoutAt.contains('://')) {
    return invalidHandleSentinel;
  }
  return withoutAt;
}

String rkeyFromUri(String uri) {
  final segments = Uri.tryParse(uri)?.pathSegments;
  if (segments != null && segments.isNotEmpty) return segments.last;
  return uri.substring(uri.lastIndexOf('/') + 1);
}
