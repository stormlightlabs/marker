import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poptart/poptart.dart';
import 'package:bluesky_poptart/app/bsky/actor/search_actors_typeahead.dart' as actor_typeahead;

const markerAtprotoActorSearchService = String.fromEnvironment(
  'MARKER_ATPROTO_ACTOR_SEARCH_SERVICE',
  defaultValue: 'public.api.bsky.app',
);

final atprotoActorSearchRepositoryProvider = Provider<AtprotoActorSearchRepository>((ref) {
  return PoptartAtprotoActorSearchRepository(PoptartClient.anonymous(service: markerAtprotoActorSearchService));
});

abstract interface class AtprotoActorSearchRepository {
  Future<List<AtprotoActorSuggestion>> searchTypeahead(String query, {int limit = 8});
}

class PoptartAtprotoActorSearchRepository implements AtprotoActorSearchRepository {
  const PoptartAtprotoActorSearchRepository(this._client);

  final PoptartClient _client;

  @override
  Future<List<AtprotoActorSuggestion>> searchTypeahead(String query, {int limit = 8}) async {
    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery == null) return const <AtprotoActorSuggestion>[];

    final response = await _client.call(
      actor_typeahead.appBskyActorSearchActorsTypeahead,
      parameters: actor_typeahead.ActorSearchActorsTypeaheadInput(q: normalizedQuery, limit: limit),
      service: markerAtprotoActorSearchService,
    );

    return response.data.actors
        .map(
          (actor) => AtprotoActorSuggestion(
            did: actor.did,
            handle: actor.handle,
            displayName: actor.displayName,
            avatar: actor.avatar,
          ),
        )
        .toList(growable: false);
  }

  static String? _normalizeQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.startsWith('@') ? trimmed.substring(1).trim() : trimmed;
  }
}

class AtprotoActorSuggestion {
  const AtprotoActorSuggestion({required this.did, required this.handle, this.displayName, this.avatar});

  final String did;
  final String handle;
  final String? displayName;
  final String? avatar;
}
