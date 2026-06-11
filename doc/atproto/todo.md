# ATProto and Semble sync todo

See [spec.md](./spec.md) for the data, sync, and UI design.

## Phase 1: local model alignment

- [x] Add Drift table for `BookmarkCollectionLinks`.
- [x] Add `updatedAt` and `deletedAt` fields to bookmarks.
- [x] Add `description`, `accessType`, and `deletedAt` fields to bookmark folders if needed by the Semble mapper.
- [x] Backfill `BookmarkCollectionLinks` from existing `Bookmarks.folderId`.
- [x] Update bookmark repositories to read/write membership through `BookmarkCollectionLinks`.
- [x] Keep `Bookmarks.folderId` as a transition column until all reads are migrated.
- [x] Add repository tests for multi-collection bookmark membership.

## Phase 2: sync metadata

- [x] Add `AtprotoAccounts` table.
- [x] Add `AtprotoRecordMirrors` table.
- [x] Add `AtprotoSyncState` table.
- [x] Add `AtprotoSyncOutbox` table.
- [x] Add repository APIs for mirrors, cursors, and outbox operations.
- [x] Add tests for mirror uniqueness by local row and remote URI.
- [x] Add tests for outbox enqueue in the same transaction as local writes.

## Phase 3: lexicon packages

- [x] Use `cosmik_poptart` for `network.cosmik.*` lexicons instead of vendoring Semble/Cosmik JSON.
- [x] Use `margin_poptart` for `at.margin.*` lexicons instead of vendoring Margin JSON.
- [x] Remove local Semble/Cosmik code generation and vendored lexicon JSON.
- [x] Add mapper/type tests that use `cosmik_poptart` and `margin_poptart` types where possible.

## Phase 4: auth and repo client

- [x] Add ATProto auth repository behind Marker-owned interfaces.
- [x] Add a Marker-owned secure session store backed by `flutter_secure_storage`.
- [x] Store sensitive OAuth/session material in `flutter_secure_storage`, not Drift.
- [x] Replace placeholder app identifiers with stable Marker identifiers before OAuth wiring.
- [x] Host static OAuth client metadata from the Marker website and use its HTTPS URL as `client_id`.
- [x] Configure iOS and Android OAuth callbacks with HTTPS app/universal links, with custom scheme only as a dev fallback.
- [x] Add account connect/disconnect flows.
- [x] Add repo client wrapper for `createRecord`, `putRecord`, `deleteRecord`, `getRecord`, and `listRecords`.
- [x] Add fake repo client for tests.
- [x] Add settings UI for account connection and sync status.
- [x] Add auth/session restore tests.

## Phase 5: Semble bookmark pull

- [x] Pull `network.cosmik.card` records with `listRecords`.
- [x] Pull `network.cosmik.collection` records.
- [x] Pull `network.cosmik.collectionLink` records.
- [x] Import remote cards as local bookmarks.
- [x] Import remote collections as local folders with local `parentId` unset.
- [x] Import links as `BookmarkCollectionLinks`.
- [x] Deduplicate cards by normalized URL.
- [x] Deduplicate links by collection URI plus card URI.
- [x] Add conflict handling for local dirty rows.
- [x] Add importer tests for new, duplicate, updated, malformed, and conflicting records.

## Phase 6: deletion sync

- [x] Use local soft deletes for synced bookmarks, folders, memberships, and annotations.
- [x] Push local deletes through `com.atproto.repo.deleteRecord`.
- [x] Keep mirror tombstones after successful remote delete.
- [x] Consume `network.cosmik.collectionLinkRemoval` records.
- [x] Publish `network.cosmik.collectionLinkRemoval` when removing a link owned by another repo.
- [x] Add periodic `getRecord` verification for mirrored records that disappear from active pulls.
- [x] Mark local rows deleted when remote `getRecord` returns not found and no local dirty edit exists.
- [x] Add deletion tests for local deletes, remote not found, and link removal records.

## Phase 7: Semble bookmark push

- [x] Map `Bookmarks` to `network.cosmik.card` URL records.
- [x] Map `BookmarkFolders` to `network.cosmik.collection` records.
- [x] Map `BookmarkCollectionLinks` to `network.cosmik.collectionLink` records.
- [x] Enqueue outbox records when bookmarks, folders, or memberships change.
- [x] Implement outbox worker for create/update writes.
- [x] Store URI, rkey, CID, JSON hash, and sync time in mirrors.
- [x] Add retry/backoff and useful error messages.
- [x] Add idempotency tests for partially completed writes.

## Phase 8: Margin note sync

- [x] Pull remote `at.margin.note` records.
- [x] Import remote notes without aggressive dedupe.
- [x] Map Marker annotations, highlights, underlines, and notes to `at.margin.note`.
- [x] Use `margin_poptart` `NoteRecord`, `Target`, `Selector`, and `Body` types in the mapper.
- [x] Choose remote selector shape from Marker's local selector array.
- [x] Preserve full local selector arrays even when the remote record stores one selector.
- [x] Map highlight color to `NoteRecord.color` when available and keep unsupported style hints local.
- [x] Push notes through the outbox worker.
- [x] Add tests for highlight, underline, note, malformed selector, and duplicate note cases.

## Phase 9: product polish

- [x] Add first-class annotation tag editor and tag filters in annotation UI.
- [x] Add annotation sync opt-in and automatic outbox enqueue for local annotation
  creates, updates, tag edits, body edits, style edits, and deletes.
- [x] Add combined ATProto `Sync now` action that runs enabled sync domains while
  preserving separate bookmark and annotation result summaries.
- [x] Add manual sync button and last-sync timestamp in Library (for all), and each of
  the Bookmarks & Annotations list screens.
- [x] Show per-account sync errors in settings.
- [x] Add account disconnect behavior that leaves local data intact.
- [x] Add privacy copy for what sync publishes.
- [x] Add separate opt-in controls for annotation sync.
- [x] Add lightweight diagnostics export for sync state without secrets.

## Phase 10: explicit sync selection

- [x] Add `AtprotoSyncSelections` Drift table with per-account, per-local-row selection
  state and migration.
- [x] Add repository APIs to select, deselect, list, and watch sync-selected local
  records.
- [x] Change bookmark, folder, membership, annotation, tag, body, style, and collection
  mutations so they enqueue outbox rows only for active selections.
- [x] Add "select for sync" actions for individual bookmarks, bookmark folders,
  annotations, and annotation collections.
- [x] Add bulk controls for "sync all bookmarks" and "sync all annotations", with
  separate choices for future new items.
- [x] Add dependency handling in UI: collection links require selected/mirrored folders
  and bookmarks; annotation collection items require selected/mirrored collections and
  annotations.
- [x] Update `Sync now` to push only selected outbound records while preserving separate
  bookmark and annotation result summaries.
- [x] Add remote import choices for each domain: keep linked to the source account, or
  import as local-only.
- [x] Define and implement deselect behavior: stop future sync by default, with a
  separate destructive option to delete already-published remote records.
- [x] Update privacy copy to state that connected accounts do not publish local data
  until items are selected.
- [x] Add diagnostics for selected counts, unselected local counts, and
  dependency-blocked selected records without exposing secrets.
- [x] Add tests for unselected local creates/updates/deletes, selecting existing rows,
  deselecting rows, bulk selection, dependency blocking, and linked vs local-only
  imports.

## Later work

- [x] Add curated annotation collections backed by `at.margin.collection` and `at.margin.collectionItem`.
- [x] Add confirmation before enabling annotation sync; enabling must not immediately publish existing annotations without an explicit confirmation.
- [ ] Add record-level conflict resolution UI now that pull, push, and deletion paths report aggregate conflicts.
- [ ] Add UI for imported/preserved Margin facets, rights, labels, and generator metadata only if users need to inspect or edit them.
- [ ] Expand Markdown-to-facet generation beyond basic Markdown links if Margin clients need richer interop.
- [ ] Add feeds from followed collections/users using `network.cosmik.follow`.
- [ ] Add support for public/open collections.
- [ ] Use `com.atproto.repo.applyWrites` for batched writes.
