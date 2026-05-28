import 'dart:convert';

String canonicalJson(Object? value) => jsonEncode(sortJson(value));

Object? sortJson(Object? value) {
  if (value is Map) {
    return {for (final key in value.keys.map((key) => key.toString()).toList()..sort()) key: sortJson(value[key])};
  }
  if (value is Iterable) return value.map(sortJson).toList(growable: false);
  return value;
}
