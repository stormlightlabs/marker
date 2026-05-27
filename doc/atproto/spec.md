# ATProto and Semble sync spec

Marker is a bookmarking and highlighting browser. The ATProto integration should make Marker data usable in the Semble/Cosmik data model while keeping local browsing fast, private by default, and available offline.

UI requirements for OAuth connection, bookmark import, sync status, and diagnostics live in [ui.md](./ui.md).

## Goals

- Sync bookmarks as Semble cards.
- Sync bookmark folders as Semble collections.
- Sync folder membership as Semble collection links.
- Sync highlights and notes using `at.margin.note` from the `margin_poptart` package.
- Generate local Dart types for Semble/Cosmik lexicons instead of hand-building every record shape.
- Treat ATProto deletion sync as a first-class design issue, not an afterthought.
- Keep browsing history local unless a later feature explicitly publishes it.

## Source lexicons

Marker needs Semble/Cosmik lexicons for bookmark sync and Margin lexicons for annotation sync.

### Semble/Cosmik records

| NSID | Marker use |
| --- | --- |
| `network.cosmik.card` | Bookmark cards and note cards. URL cards are the main bookmark representation. |
| `network.cosmik.collection` | Bookmark folders and user-visible saved collections. |
| `network.cosmik.collectionLink` | Membership from card to collection. |
| `network.cosmik.collectionLinkRemoval` | Tombstone for collection-link removal when the remover cannot delete the original link. |
| `network.cosmik.connection` | Later page/card graph feature. Not needed for initial sync. |
| `network.cosmik.follow` | Later feed/social feature for followed users or collections. |
| `network.cosmik.defs#provenance` | Optional reference back to source cards. Useful when importing shared cards. |

### Margin records

| NSID | Marker use |
| --- | --- |
| `at.margin.note` | Main representation for Marker annotations, highlights, underlines, and notes. |
| `at.margin.collection` | Simpler collection format. Marker should prefer `network.cosmik.collection`. |
| `at.margin.collectionItem` | Collection membership with position. Useful reference if sort order becomes important. |
| `at.margin.reply` | Later annotation discussion. |
| `at.margin.like` | Later social action on notes or replies. |
| `at.margin.profile` | Later Margin profile support. |
| `at.margin.preferences` | Later Margin preference import/export if Marker needs it. |
| `at.margin.apikey` | Not used by Marker sync. |

## Current Marker local model

Current Drift tables:

| Table | Current role |
| --- | --- |
| `Pages` | Page metadata for visited or annotated URLs. |
| `Bookmarks` | URL bookmark with one nullable `folderId`. |
| `BookmarkFolders` | Nested folders through `parentId`. |
| `Annotations` | W3C-style annotation shell with `motivation`, created/modified/deleted timestamps. |
| `AnnotationTargets` | Source URL and selector JSON. |
| `AnnotationBodies` | Textual note body and style hints. |
| `BrowserHistoryEntries` | Local browser history. |
| `AppSettings` | Local settings. |

The main model changes needed for Semble are bookmark membership and sync metadata. Marker currently stores one folder on the bookmark row. Semble stores collection membership as separate link records, so Marker should adopt a join table locally.

## Local model changes

All Drift changes require migrations.

### Bookmark cards

Keep `Bookmarks` as the local bookmark/card row, but remove the long-term assumption that a bookmark belongs to one folder.

Recommended end state:

```text
Bookmarks
- id TEXT PRIMARY KEY
- url TEXT UNIQUE NOT NULL
- title TEXT NULL
- description TEXT NULL
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
- deletedAt DATETIME NULL
```

Migration path:

1. Add `updatedAt` and `deletedAt` to `Bookmarks`.
2. Add `description` if page metadata should be denormalized into bookmarks.
3. Keep `folderId` during a transition release.
4. Backfill folder links from existing `folderId` values.
5. Stop writing `folderId` from repository code.
6. Drop or ignore `folderId` only when the app no longer reads it.

### Bookmark collection links

Add a local membership table that mirrors `network.cosmik.collectionLink`.

```text
BookmarkCollectionLinks
- id TEXT PRIMARY KEY
- bookmarkId TEXT NOT NULL REFERENCES Bookmarks(id)
- folderId TEXT NOT NULL REFERENCES BookmarkFolders(id)
- sortOrder INTEGER NOT NULL DEFAULT 0
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
- deletedAt DATETIME NULL
- UNIQUE(bookmarkId, folderId)
```

`sortOrder` can remain local. Semble's `network.cosmik.collectionLink` does not currently include position. That is acceptable because order is a UI preference, not identity. Marker should not block sync on sort order. If ordering later matters across clients, there are two reasonable options:

- propose a position field for `network.cosmik.collectionLink`, or
- add a Marker-specific private preference record keyed by collection/card URI.

### Bookmark folders / collections

Keep folders as local collections:

```text
BookmarkFolders
- id TEXT PRIMARY KEY
- parentId TEXT NULL REFERENCES BookmarkFolders(id)
- title TEXT NOT NULL
- description TEXT NULL
- accessType TEXT NOT NULL DEFAULT 'CLOSED'
- sortOrder INTEGER NOT NULL DEFAULT 0
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
- deletedAt DATETIME NULL
```

Semble collections are flat. Marker can still keep `parentId` locally. Remote clients will see separate collections. This avoids forcing folder hierarchy into a lexicon that does not model it.

If public/shared folders are added later, map them to `accessType: "OPEN"`. Private synced folders should use `accessType: "CLOSED"`.

### Sync metadata

Add account, mirror, cursor, and outbox tables.

```text
AtprotoAccounts
- did TEXT PRIMARY KEY
- handle TEXT NULL
- pdsEndpoint TEXT NULL
- authMethod TEXT NOT NULL
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
```

Tokens, refresh material, DPoP key material, and pending OAuth context must go in `flutter_secure_storage`, not Drift.

```text
AtprotoRecordMirrors
- id TEXT PRIMARY KEY
- accountDid TEXT NOT NULL REFERENCES AtprotoAccounts(did)
- localTable TEXT NOT NULL
- localId TEXT NOT NULL
- collection TEXT NOT NULL
- rkey TEXT NOT NULL
- uri TEXT NOT NULL
- cid TEXT NULL
- lastSyncedRecordJson TEXT NULL
- lastSyncedHash TEXT NULL
- lastSyncedAt DATETIME NULL
- dirtyAt DATETIME NULL
- deletedAt DATETIME NULL
- UNIQUE(accountDid, localTable, localId, collection)
- UNIQUE(accountDid, uri)
```

```text
AtprotoSyncState
- id TEXT PRIMARY KEY
- accountDid TEXT NOT NULL REFERENCES AtprotoAccounts(did)
- collection TEXT NOT NULL
- cursor TEXT NULL
- lastSuccessfulSyncAt DATETIME NULL
- lastError TEXT NULL
- UNIQUE(accountDid, collection)
```

```text
AtprotoSyncOutbox
- id TEXT PRIMARY KEY
- accountDid TEXT NOT NULL REFERENCES AtprotoAccounts(did)
- operation TEXT NOT NULL -- create, update, delete
- localTable TEXT NOT NULL
- localId TEXT NOT NULL
- collection TEXT NOT NULL
- payloadJson TEXT NULL
- attemptCount INTEGER NOT NULL DEFAULT 0
- lastError TEXT NULL
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
```

## Record mapping

### Bookmark to `network.cosmik.card`

Marker bookmark/card:

```text
Bookmarks.url
Bookmarks.title
Bookmarks.description
Bookmarks.createdAt
```

Semble record:

```json
{
  "type": "URL",
  "content": {
    "url": "https://example.com/article",
    "metadata": {
      "title": "Article title",
      "description": "Article description",
      "retrievedAt": "2026-05-26T00:00:00.000Z"
    }
  },
  "url": "https://example.com/article",
  "createdAt": "2026-05-26T00:00:00.000Z"
}
```

Mapping:

| Marker | Semble |
| --- | --- |
| `Bookmarks.url` | `content.url`, `url` |
| `Bookmarks.title` | `content.metadata.title` |
| `Bookmarks.description` or `Pages.description` | `content.metadata.description` |
| `Bookmarks.createdAt` | `createdAt` |
| local mirror URI/CID | AT URI/CID returned by repo write |

Use normalized URL as the semantic dedupe key. ATProto record identity still comes from URI/rkey.

### Folder to `network.cosmik.collection`

```json
{
  "name": "Research",
  "description": "Papers and reference material",
  "accessType": "CLOSED",
  "createdAt": "2026-05-26T00:00:00.000Z",
  "updatedAt": "2026-05-26T00:00:00.000Z"
}
```

Mapping:

| Marker | Semble |
| --- | --- |
| `BookmarkFolders.title` | `name` |
| `BookmarkFolders.description` | `description` |
| `BookmarkFolders.accessType` | `accessType` |
| `createdAt` | `createdAt` |
| `updatedAt` | `updatedAt` |

Keep `parentId` local. Do not encode hierarchy into `name` unless the user exports a flat view.

### Folder membership to `network.cosmik.collectionLink`

```json
{
  "collection": { "uri": "at://did:example/network.cosmik.collection/abc", "cid": "..." },
  "card": { "uri": "at://did:example/network.cosmik.card/def", "cid": "..." },
  "addedBy": "did:example:user",
  "addedAt": "2026-05-26T00:00:00.000Z",
  "createdAt": "2026-05-26T00:00:00.000Z"
}
```

Mapping:

| Marker | Semble |
| --- | --- |
| folder mirror URI/CID | `collection` |
| bookmark/card mirror URI/CID | `card` |
| account DID | `addedBy` |
| link `createdAt` | `addedAt`, `createdAt` |

A card can belong to more than one collection after the local join table exists.

### Annotation to `at.margin.note`

Marker's annotation target JSON already resembles Margin's W3C target model. Use the generated `margin_poptart` `NoteRecord`, `Target`, `Selector`, and `Body` types for highlights, underlines, and notes.

```json
{
  "$type": "at.margin.note",
  "target": {
    "$type": "at.margin.note#target",
    "source": "https://example.com/article",
    "title": "Article title",
    "selector": {
      "$type": "at.margin.note#selector",
      "type": "TextQuoteSelector",
      "exact": "selected text",
      "prefix": "before ",
      "suffix": " after"
    }
  },
  "body": {
    "$type": "at.margin.note#body",
    "format": "text/markdown",
    "value": "reader note"
  },
  "motivation": "commenting",
  "color": "yellow",
  "createdAt": "2026-05-26T00:00:00.000Z"
}
```

Mapping:

| Marker | Margin |
| --- | --- |
| `AnnotationTargets.sourceUrl` | `target.source` |
| page title | `target.title` |
| TextQuote selector | `target.selector` with `type: "TextQuoteSelector"` |
| TextPosition selector | `target.selector` with `type: "TextPositionSelector"` |
| CSS selector | `target.selector` with `type: "CssSelector"` |
| `Annotations.motivation` | `motivation` |
| `AnnotationBodies.TextualBody` | `body.value`, `body.format` |
| highlight color style hint | `color` when available |
| `Annotations.createdAt` | `createdAt` |
| `Annotations.modifiedAt` | `modifiedAt` |

Margin's `target.selector` stores one selector. Marker currently stores multiple selectors. The mapper should choose the strongest selector shape for the remote record:

1. Prefer `TextQuoteSelector` because it survives page layout changes better than offsets.
2. Use `TextPositionSelector` when quote data is unavailable and offsets are present.
3. Use CSS, XPath, or fragment selectors only when quote/position data is unavailable.

Keep the full selector array locally so Marker can re-anchor highlights using all available evidence.

### Style hints

Marker stores highlight/underline style in an `AnnotationBodies` row with type `StyleHint`. `at.margin.note` has a `color` field, so the first implementation should map highlight color when the stored value is compatible. Keep underline and unsupported style hints local. Do not drop style data during remote import/export.

## Published lexicon packages

Marker should use published Poptart lexicon packages instead of vendoring Semble/Cosmik JSON or committing generated lexicon output:

- `cosmik_poptart` for `network.cosmik.*` records used by Semble/Cosmik bookmark sync;
- `margin_poptart` for `at.margin.*` records used by annotation sync;
- `poptart_lex` for `com.atproto.*` repo methods and common ATProto types.

This keeps Marker out of the lexicon-codegen business. Public sync code should still depend on Marker-owned domain models and mappers, but the mapper implementations should build and parse `cosmik_poptart` / `margin_poptart` record types where possible. Raw JSON maps are acceptable only at repository boundaries such as generic `createRecord`, `putRecord`, `getRecord`, and `listRecords` wrappers.

## ATProto client layer

Use Poptart for auth/session/XRPC behavior and `margin_poptart` for Margin record types:

- `poptart`
- `poptart_core`
- `poptart_oauth`
- `poptart_lex`
- `margin_poptart`
- `cosmik_poptart`
- `flutter_secure_storage`

Marker should hide Poptart behind app interfaces:

```text
lib/features/atproto/
  application/
    atproto_auth_controller.dart
    atproto_sync_service.dart
    atproto_outbox_worker.dart
  data/
    atproto_auth_repository.dart
    atproto_repo_repository.dart
    atproto_sync_repository.dart
    semble_record_mappers.dart
  domain/
    atproto_account.dart
    sync_record_ref.dart
    sync_conflict.dart
```

### Session storage and OAuth client metadata

Use `flutter_secure_storage` behind a Marker-owned session-store interface. The secure store should hold OAuth sessions, refresh tokens, DPoP key material, nonce state, and pending OAuth context. Drift should hold only account metadata such as DID, handle, PDS endpoint, and timestamps.

Before shipping OAuth, replace the placeholder app identifiers with a stable ID such as `org.stormlightlabs.marker`. Host static OAuth client metadata from the Marker website and use that URL as the OAuth `client_id`, for example:

```text
https://<marker-domain>/client-metadata.json
```

The initial metadata should describe a native public client with DPoP-bound access tokens, `authorization_code` and `refresh_token` grants, `token_endpoint_auth_method: "none"`, and scope `atproto transition:generic`. Prefer HTTPS app/universal links for the callback on iOS and Android. A custom scheme is acceptable only as a development fallback.

Minimum repo operations:

- `com.atproto.repo.createRecord`
- `com.atproto.repo.putRecord`
- `com.atproto.repo.deleteRecord`
- `com.atproto.repo.getRecord`
- `com.atproto.repo.listRecords`
- `com.atproto.repo.applyWrites` for batching after the single-record path is proven.

## Push sync

Local writes should create outbox rows in the same transaction as the local data mutation.

Example bookmark create:

1. Insert or update `Bookmarks`.
2. Add an outbox row for `network.cosmik.card` create/update.
3. If the bookmark is in folders, add outbox rows for missing `network.cosmik.collectionLink` records.
4. The worker writes records to the PDS.
5. The worker updates `AtprotoRecordMirrors` with URI, rkey, CID, JSON hash, and sync timestamp.
6. The worker removes or marks the outbox row complete.

The worker must be idempotent. If a create succeeds but the app dies before mirror update, retry should detect the duplicate by local mirror, URL, or stored rkey strategy.

## Pull sync

For each signed-in account, pull these collections:

- `network.cosmik.card`
- `network.cosmik.collection`
- `network.cosmik.collectionLink`
- `network.cosmik.collectionLinkRemoval`
- `at.margin.note`

For each listed record:

1. Check `AtprotoRecordMirrors` by URI.
2. If mirrored and CID is unchanged, skip.
3. If mirrored and local row is not dirty, apply remote changes.
4. If mirrored and local row is dirty, create a conflict record or defer to the conflict policy below.
5. If not mirrored, import the record and create a mirror.

`listRecords` does not provide durable deletion history. Deletion handling needs extra checks.

## Deletion sync

Use soft deletes locally for synced entities. Hard delete only after the remote delete has been confirmed and enough time has passed for recovery.

Local delete flow:

1. Set local `deletedAt`.
2. Add outbox delete for the mirrored ATProto record.
3. For folder membership, delete the `network.cosmik.collectionLink` record if Marker owns it.
4. If Marker needs to remove a link created by another repo, publish `network.cosmik.collectionLinkRemoval`.
5. After successful remote delete, keep the mirror as a tombstone with `deletedAt`.

Remote delete detection:

- On regular pulls, missing records are not visible.
- Periodically verify mirrored records with `getRecord` if they have not appeared in recent pulls.
- If `getRecord` returns not found, mark the local row deleted unless it has unsynced local edits.
- Later, add repo commit subscription/firehose handling for timely deletes.

This means phase 1 deletion sync is correct for local deletes and eventually consistent for remote deletes.

## Conflict policy

### Cards/bookmarks

Primary semantic key: normalized URL.

Rules:

- If remote and local cards have the same normalized URL, merge them.
- Prefer non-empty title/description.
- If both sides changed the same text field, prefer the newer `updatedAt` when available. Otherwise prefer local and record a conflict note for diagnostics.
- Preserve all collection links; the join table allows multi-collection membership.

### Collections/folders

Primary identity: mirror URI. Secondary import key: normalized collection name for records without a mirror.

Rules:

- Remote rename applies when the local folder is not dirty.
- Local dirty rename wins during push unless the remote CID changed since last sync. In that case, fetch and compare before `putRecord`.
- `parentId` remains local. Remote changes should not flatten or re-parent local folders.

### Collection links

Primary identity: mirror URI. Semantic key: collection URI plus card URI.

Rules:

- Duplicate links with the same collection/card pair should collapse into one local link.
- Link delete should only remove that membership, not the card.
- `sortOrder` stays local.

### Annotations / Margin notes

Primary identity: mirror URI. Secondary import key should be conservative:

```text
normalized source URL + exact quote + start/end + createdAt bucket
```

Do not dedupe annotations aggressively. Duplicates are safer than accidentally merging two different reader notes.

## Privacy defaults

- Browser history is local only.
- A bookmark/card is synced only after ATProto sync is enabled for the account.
- Default collection `accessType` is `CLOSED`.
- Public/open collections need an explicit UI action.
- Annotation sync is a separate opt-in setting and defaults off.

## Test requirements

Add tests with each implementation step:

- mapper tests for every record shape Marker writes;
- migration tests for bookmark join table backfill;
- outbox idempotency tests;
- push worker tests with fake repo client;
- pull importer tests for new, updated, duplicate, and malformed records;
- deletion tests for local soft delete, remote delete confirmation, and collection-link removal;
- conflict tests for URL dedupe, folder rename, multi-collection membership, and Margin note import.
