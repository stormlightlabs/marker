# ATProto and Semble sync spec

Marker is a bookmarking and highlighting browser. The ATProto integration should make Marker data usable in the Semble/Cosmik data model while keeping local browsing fast, private by default, and available offline.

## Goals

- Sync bookmarks as Semble cards.
- Sync bookmark folders as Semble collections.
- Sync folder membership as Semble collection links.
- Sync highlights and notes using `at.margin.note` from the `margin_poptart` package.
- Keep local bookmarks, folders, annotations, and annotation collections off ATProto unless the user explicitly selects them for sync.
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
| `at.margin.collection` | Annotation collections. Use for curated annotation groups, not for every tag. |
| `at.margin.collectionItem` | Annotation-to-collection membership with position. Use when Marker adds curated annotation collections. |
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
| `Annotations` | W3C-style annotation shell with `motivation`, Margin metadata JSON, created/modified/deleted timestamps. |
| `AnnotationTargets` | Source URL, optional source hash, selector JSON, and optional Margin target state JSON. |
| `AnnotationBodies` | Textual note body, optional body URI, and style hints. |
| `AnnotationTags` | First-class tags for grouping and filtering annotations. |
| `AnnotationCollections` | Curated annotation groups that map to `at.margin.collection`. |
| `AnnotationCollectionItems` | Annotation-to-collection memberships that map to `at.margin.collectionItem`. |
| `BrowserHistoryEntries` | Local browser history. |
| `AppSettings` | Local settings. |

The main model changes needed for Semble are bookmark membership, sync metadata, and per-account sync selection. Marker currently stores one folder on the bookmark row. Semble stores collection membership as separate link records, so Marker should adopt a join table locally.

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

Add account, mirror, cursor, selection, and outbox tables.

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
AtprotoSyncSelections
- id TEXT PRIMARY KEY
- accountDid TEXT NOT NULL REFERENCES AtprotoAccounts(did)
- localTable TEXT NOT NULL
- localId TEXT NOT NULL
- collection TEXT NOT NULL
- selectedAt DATETIME NOT NULL
- deselectedAt DATETIME NULL
- deleteRemoteOnLocalDelete BOOLEAN NOT NULL DEFAULT TRUE
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
- UNIQUE(accountDid, localTable, localId, collection)
```

`AtprotoSyncSelections` is the publish allow-list. A local row is eligible for outbound ATProto writes only when it has an active selection row for the target account and collection. This keeps account connection, remote import, and local publishing as separate choices.

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
| `AnnotationTargets.sourceHash` | `target.sourceHash` |
| `AnnotationTargets.stateJson` | `target.state` |
| page title | `target.title` |
| TextQuote selector | `target.selector` with `type: "TextQuoteSelector"` |
| TextPosition selector | `target.selector` with `type: "TextPositionSelector"` |
| CSS selector | `target.selector` with `type: "CssSelector"` |
| `Annotations.motivation` | `motivation` |
| `AnnotationBodies.TextualBody` | `body.value`, `body.format`, `body.uri` |
| `AnnotationTags.name` | `tags` |
| markdown links in `TextualBody` | generated link `facets` when no remote facets are preserved |
| highlight color style hint | `color` when available |
| `Annotations.createdAt` | `createdAt` |
| `Annotations.modifiedAt` | `modifiedAt` |
| preserved Margin metadata JSON | `facets`, `rights`, `labels`, and unknown top-level fields |
| Marker client | `generator` on outbound records |

Margin's `target.selector` stores one selector. Marker currently stores multiple selectors. The mapper should choose the strongest selector shape for the remote record:

1. Prefer `TextQuoteSelector` because it survives page layout changes better than offsets.
2. Use `TextPositionSelector` when quote data is unavailable and offsets are present.
3. Use CSS, XPath, or fragment selectors only when quote/position data is unavailable.

Keep the full selector array locally so Marker can re-anchor highlights using all available evidence.

### Style hints

Marker stores highlight/underline style in an `AnnotationBodies` row with type `StyleHint`. `at.margin.note` has a `color` field, so Marker maps highlight color when available. Margin does not have a first-class underline field; Marker syncs underlines as Margin highlights with color and adds the Marker extension field `markerStyle: "underline"` so Marker can round-trip the visual style without exposing it as a user tag.

### Annotation tags and Margin collections

Use Margin `NoteRecord.tags` for lightweight annotation grouping. Tags are first-class local rows and should be searchable/filterable in Marker.

Do not automatically turn every tag into `at.margin.collection`. Margin collections represent curated annotation sets with explicit membership and ordering. Marker maps curated annotation collections to `at.margin.collection` and memberships to `at.margin.collectionItem`; tag sync remains independent.

### Curated annotation collection to `at.margin.collection`

Mapping:

| Marker | Margin |
| --- | --- |
| `AnnotationCollections.name` | `name` |
| `AnnotationCollections.description` | `description` |
| `AnnotationCollections.icon` | `icon` |
| `AnnotationCollections.createdAt` | `createdAt` |

### Annotation collection item to `at.margin.collectionItem`

Mapping:

| Marker | Margin |
| --- | --- |
| collection mirror URI | `collection` |
| annotation note mirror URI | `annotation` |
| `AnnotationCollectionItems.position` | `position` |
| `AnnotationCollectionItems.createdAt` | `createdAt` |

## Explicit sync selection

Connecting an ATProto account does not publish existing local data. Sync selection is explicit and per account. Marker should let the user select exactly which local records are allowed to create or update Semble/Cosmik and Margin records.

Selection levels:

| User selection | Outbound records allowed |
| --- | --- |
| Individual bookmark | `network.cosmik.card` only. Folder membership is not published unless a selected folder also includes the bookmark. |
| Bookmark folder | `network.cosmik.collection` for the folder, plus `network.cosmik.collectionLink` only for bookmarks in that folder that are also selected or selected through the same folder action. |
| All bookmarks | Existing and future bookmarks, folders, and memberships, subject to the user's folder/member choices in the sync UI. |
| Individual annotation | `at.margin.note` for that annotation. |
| Annotation collection | `at.margin.collection` plus `at.margin.collectionItem` for selected member annotations. |
| All annotations | Existing and future annotations and annotation collections. This remains separate from bookmark sync. |

Selection rules:

- Local creates, edits, tag changes, style changes, folder moves, collection edits, and deletes enqueue ATProto outbox rows only when the affected local row has an active `AtprotoSyncSelections` row.
- Selecting an item for the first time should enqueue a create/update for the current local state. It should not require the user to edit the item.
- Deselecting an item stops future outbound writes. It does not delete remote records by default. Offer a separate destructive action for removing already-published remote records.
- If a selected local item has dependencies, the UI must show what else needs to be selected. For example, a collection link cannot be pushed until its folder and bookmark/card mirrors exist.
- A remote import creates mirrors. If the user imports remote records, those local rows are treated as selected for that source account because the records already exist remotely. The import UI should offer a "keep future edits local" option that imports the data and immediately deselects it.
- Multiple ATProto accounts can have different selections for the same local row.
- Selection state is local. It is not published to ATProto.

Default behavior:

- New local bookmarks and annotations remain local.
- New local folders, annotation collections, and membership links remain local.
- Existing local data remains local after account connection.
- A `Sync now` action only runs enabled sync domains and selected outbound records. It may still pull/import remote records when the user has enabled remote import for that domain.

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

Local writes should create outbox rows in the same transaction as the local data mutation only for active sync selections. Bookmark sync and annotation sync share the same outbox/mirror infrastructure, but no local row is published just because an account is connected or a domain-level sync setting is on.

Example selected bookmark create/update:

1. Insert or update `Bookmarks`.
2. Check active `AtprotoSyncSelections` rows for the bookmark/account/collection.
3. Add an outbox row for `network.cosmik.card` create/update only for matching selections.
4. If the bookmark is in selected folders, add outbox rows for missing `network.cosmik.collectionLink` records whose folder and bookmark/card can both be mirrored.
5. The worker writes records to the PDS.
6. The worker updates `AtprotoRecordMirrors` with URI, rkey, CID, JSON hash, and sync timestamp.
7. The worker removes or marks the outbox row complete.

The worker must be idempotent. If a create succeeds but the app dies before mirror update, retry should detect the duplicate by local mirror, URL, or stored rkey strategy.

## Pull sync

For each signed-in account, pull these collections when the user has enabled import for the corresponding domain:

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
5. If not mirrored, import the record and create a mirror plus an active selection for the source account, unless the user chose to import that domain as local-only.

`listRecords` does not provide durable deletion history. Deletion handling needs extra checks.

## Deletion sync

Use soft deletes locally for synced entities. Hard delete only after the remote delete has been confirmed and enough time has passed for recovery.

Local delete flow for selected records:

1. Set local `deletedAt`.
2. If the row has an active selection and `deleteRemoteOnLocalDelete` is true, add outbox delete for the mirrored ATProto record.
3. If the row is not selected, do not add a remote delete.
4. For selected folder membership, delete the `network.cosmik.collectionLink` record if Marker owns it.
5. If Marker needs to remove a selected link created by another repo, publish `network.cosmik.collectionLinkRemoval`.
6. After successful remote delete, keep the mirror as a tombstone with `deletedAt`.

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

## UI requirements

ATProto sync lives under Settings → Sync. The surface covers account connection, explicit sync selection, manual sync, status, diagnostics, and privacy copy.

### UX principles

- Treat ATProto sync as opt-in.
- Account connection alone must not publish local bookmarks, folders, annotations, tags, notes, or collections.
- Explain that selected bookmark sync writes Semble/Cosmik records to the user's ATProto repo.
- Explain that selected annotation sync writes Margin records that can include page URLs, selected text, notes, tags, colors, and collection membership.
- Keep browser history out of sync copy and controls.
- Keep annotation sync separate from bookmark sync, with its own opt-in, status, and result copy under the ATProto Sync umbrella.
- Default annotation sync to off until the user opts in.
- Prefer recovery actions over raw protocol errors.
- Never show tokens, refresh material, DPoP keys, OAuth pending context, raw session state, full selector JSON, note body text, or raw record JSON in standard UI or diagnostics.

### Account connection

Disconnected state shows `Sync` / `ATProto Sync`, the subtitle `Connect a Bluesky or Atmosphere account`, and a `Connect` action. The connect action opens a sheet with:

- title: `Connect ATProto`;
- copy stating that Bluesky or Atmosphere accounts can import Semble/Cosmik bookmarks;
- privacy copy stating that connecting does not publish local data and browser history stays local;
- optional handle input with placeholder `alice.bsky.social`;
- helper text explaining that the user may leave the field blank and choose an account in the browser;
- `Continue` and `Cancel` actions.

On `Continue`, the app calls `AtprotoAuthRepository.startConnect(handle: ...)`, launches the OAuth authorization URL through `flutter_web_auth_2`, waits for the HTTPS callback, and passes the full callback URL to `AtprotoAuthRepository.completeConnect`. The production callback is:

```text
https://marker.stormlightlabs.org/oauth/callback
```

A development fallback may use:

```text
marker-dev://oauth-callback
```

Manual copy/paste OAuth callbacks should not be exposed in normal builds.

The login controller represents `idle`, `startingOAuth`, `waitingForCallback`, `completingOAuth`, `connected`, and `failed(message)`. Failures stay in the connect sheet with retry/cancel available. User-facing messages should be plain language, for example:

| Cause | User message |
| --- | --- |
| OAuth start failed | `Could not start sign in. Check your connection and try again.` |
| Browser/auth session canceled | `Sign in was canceled.` |
| Missing pending context | `Sign in expired. Start again.` |
| State mismatch | `Sign in could not be verified. Start again.` |
| Token exchange failed | `Could not finish sign in. Try again.` |
| Secure storage unavailable | `Marker could not save the session securely on this device.` |

After connection, offer an immediate import prompt: `Import bookmarks now?` with body copy explaining that Marker can pull Semble/Cosmik bookmarks and collections from the user's ATProto repo. Actions are `Import bookmarks` and `Not now`.

### Connected settings

Connected state shows:

- title: `ATProto Sync` or `Sync`;
- subtitle: `Connected as @handle` or `Connected as did:...`;
- account DID;
- handle, if known;
- PDS endpoint, if known;
- last bookmark import/sync time;
- last error, if any;
- `Sync now`;
- `Disconnect`.

Disconnect clears OAuth session material from secure storage, leaves local imported data intact, and may leave non-secret sync metadata for diagnostics. Confirmation copy:

- title: `Disconnect ATProto?`;
- body: `Marker will remove the saved sign-in session. Imported bookmarks stay on this device.`;
- destructive action: `Disconnect`;
- cancel: `Cancel`.

### Sync controls and selection

Settings should show what sync is allowed to manage. Existing local items stay private until explicitly selected. Controls include:

- annotation sync opt-in;
- automatic selection for new bookmarks/folders/memberships;
- automatic selection for new annotations and curated annotation collections;
- individual and bulk selection controls elsewhere in the app for bookmarks, bookmark folders, annotations, and annotation collections;
- dependency feedback when selected memberships cannot sync until their parent bookmark/folder or annotation/collection is selected or mirrored.

When importing remote records, ask whether to keep them linked to the source account for future sync or import as local-only so future edits stay private.

### Manual sync

When push exists, the main action is `Sync now` / `Sync bookmarks`, not `Import bookmarks`. It should push pending selected local changes, pull remote Semble/Cosmik records, verify remote deletes, and run enabled annotation sync domains while preserving separate bookmark and annotation summaries. Button states are:

- idle: `Sync now` or `Sync bookmarks`;
- running: `Syncing...` or `Syncing bookmarks...`;
- disabled when disconnected or another sync is running.

Bookmark result summaries separate push, pull, remote deletes, conflicts, malformed records, and no-op state. Example:

```text
Published 3 bookmark changes and 1 delete.
Imported 2 bookmarks, 1 folder, and 3 folder links.
Applied 2 remote deletes.
Skipped 1 conflict and 0 malformed records.
```

For no changes:

```text
Bookmarks are up to date.
```

If a push fails, keep local data unchanged, leave outbox items queued, and offer `Retry sync` and `View sync issues` where appropriate. Record-level conflict resolution is later work.

### Annotation sync UI

Annotation sync is a separate card/section below bookmark sync. When connected, show:

- title: `Annotations` or `Annotation sync`;
- disabled subtitle: `Off. Sync highlights and notes with Margin.`;
- enabled subtitle: `Syncing highlights and notes as Margin records.`;
- toggle: `Sync annotations`;
- when enabled: `Sync annotations now` and `View annotation sync issues` if conflicts, malformed records, or failed outbox items exist.

Turning annotation sync on requires confirmation before publishing existing annotations. Copy:

- title: `Sync annotations?`;
- body: `Marker will import and publish Margin note records in your ATProto repo. Synced records can include page URLs, selected text, notes, and highlight colors.`;
- primary action: `Enable annotation sync`;
- secondary action: `Cancel`.

After enabling, offer `Sync annotations now` and `Not now`. Annotation sync pushes pending local `at.margin.note`, `at.margin.collection`, and `at.margin.collectionItem` changes, then pulls remote records. Summary example:

```text
Published 3 annotation changes.
Imported 2 Margin notes.
Skipped 1 malformed record.
```

For no changes:

```text
Annotations are up to date.
```

Reader screens should avoid protocol labels beside every highlight. Add sync status only where users manage annotations: optional `Synced with Margin` / `Pending sync` in annotation detail, no per-row status unless there is an error, and delete confirmation copy stating that the synced Margin note will be deleted on the next sync when annotation sync is enabled.

### Status and diagnostics

Diagnostics live under ATProto Sync as an expandable section or screen. Show aggregate, non-secret state:

- tracked collection name;
- last successful sync time;
- last error;
- local changes pending;
- last push timestamp;
- last push error;
- retry timestamp when backoff is active;
- pending creates, updates, deletes;
- failed attempts;
- oldest pending change time;
- selected counts, unselected local counts, and dependency-blocked counts;
- delete sync status;
- synced and deleted record counts.

Tracked diagnostics include `network.cosmik.card`, `network.cosmik.collection`, `network.cosmik.collectionLink`, `network.cosmik.collectionLinkRemoval`, `at.margin.note`, `at.margin.collection`, and `at.margin.collectionItem`. Diagnostics export may include non-secret aggregate fields and short errors, but not OAuth/session material, DPoP material, raw records, selector JSON, note body text, or payload JSON.

Use plain-language operation labels in normal UI:

| Operation | Label |
| --- | --- |
| create | `New remote record` |
| update | `Update remote record` |
| delete | `Delete remote record` |

Initial issue UI can stay aggregate-only:

- `Malformed remote notes: N`;
- `Local conflicts skipped: N`;
- `Failed pushes: N`.

### Privacy copy

Use this copy in the connect sheet or connected detail panel, adjusted for explicit selection:

```text
Connecting an account does not publish local data. Marker only syncs items you choose to keep synced. Browser history stays local.
```

For bookmark publishing details:

```text
Selected bookmark sync writes Semble/Cosmik bookmark records to your ATProto repo. Browser history stays local. Annotation sync is separate and off by default.
```

For collections:

```text
Imported collections become Marker folders. Synced private collections use CLOSED access unless you choose otherwise later.
```

Deferred UI work includes rich-text facet editing, rights/license editing, content-warning/label editing, and generator metadata display unless users need those controls.

## Privacy defaults

- Browser history is local only.
- Connecting an ATProto account does not publish existing bookmarks, folders, annotations, tags, notes, or collections.
- A bookmark/card is synced only after the user explicitly selects that bookmark, a containing folder sync action that includes it, or "all bookmarks" for the account.
- A bookmark folder/collection and membership links sync only after the user explicitly selects the folder or an all-bookmarks sync action that includes folders.
- An annotation syncs only after the user explicitly selects that annotation, a containing annotation collection sync action that includes it, or "all annotations" for the account.
- Imported remote records may remain linked to their source account, but the import UI must allow importing them as local-only.
- Default collection `accessType` is `CLOSED`.
- Public/open collections need an explicit UI action.
- Selection state is local-only and should not be encoded into Semble/Cosmik or Margin records.

## Test requirements

Add tests with each implementation step:

- mapper tests for every record shape Marker writes;
- migration tests for bookmark join table backfill;
- outbox idempotency tests;
- selection tests proving unselected local writes do not enqueue or publish records;
- tests for selecting an existing item, deselecting an item, and importing remote records as linked versus local-only;
- push worker tests with fake repo client;
- pull importer tests for new, updated, duplicate, and malformed records;
- deletion tests for local soft delete, remote delete confirmation, and collection-link removal;
- conflict tests for URL dedupe, folder rename, multi-collection membership, and Margin note import.
