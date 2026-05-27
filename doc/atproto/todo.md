# ATProto and Semble sync todo

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

- [ ] Add ATProto auth repository behind Marker-owned interfaces.
- [ ] Add a Marker-owned secure session store backed by `flutter_secure_storage`.
- [ ] Store sensitive OAuth/session material in `flutter_secure_storage`, not Drift.
- [ ] Replace placeholder app identifiers with stable Marker identifiers before OAuth wiring.
- [ ] Host static OAuth client metadata from the Marker website and use its HTTPS URL as `client_id`.
- [ ] Configure iOS and Android OAuth callbacks with HTTPS app/universal links, with custom scheme only as a dev fallback.
- [ ] Add account connect/disconnect flows.
- [ ] Add repo client wrapper for `createRecord`, `putRecord`, `deleteRecord`, `getRecord`, and `listRecords`.
- [ ] Add fake repo client for tests.
- [ ] Add settings UI for account connection and sync status.
- [ ] Add auth/session restore tests.

## Phase 5: Semble bookmark push

- [ ] Map `Bookmarks` to `network.cosmik.card` URL records.
- [ ] Map `BookmarkFolders` to `network.cosmik.collection` records.
- [ ] Map `BookmarkCollectionLinks` to `network.cosmik.collectionLink` records.
- [ ] Enqueue outbox records when bookmarks, folders, or memberships change.
- [ ] Implement outbox worker for create/update writes.
- [ ] Store URI, rkey, CID, JSON hash, and sync time in mirrors.
- [ ] Add retry/backoff and useful error messages.
- [ ] Add idempotency tests for partially completed writes.

## Phase 6: Semble bookmark pull

- [ ] Pull `network.cosmik.card` records with `listRecords`.
- [ ] Pull `network.cosmik.collection` records.
- [ ] Pull `network.cosmik.collectionLink` records.
- [ ] Import remote cards as local bookmarks.
- [ ] Import remote collections as local folders with local `parentId` unset.
- [ ] Import links as `BookmarkCollectionLinks`.
- [ ] Deduplicate cards by normalized URL.
- [ ] Deduplicate links by collection URI plus card URI.
- [ ] Add conflict handling for local dirty rows.
- [ ] Add importer tests for new, duplicate, updated, malformed, and conflicting records.

## Phase 7: deletion sync

- [ ] Use local soft deletes for synced bookmarks, folders, memberships, and annotations.
- [ ] Push local deletes through `com.atproto.repo.deleteRecord`.
- [ ] Keep mirror tombstones after successful remote delete.
- [ ] Consume `network.cosmik.collectionLinkRemoval` records.
- [ ] Publish `network.cosmik.collectionLinkRemoval` when removing a link owned by another repo.
- [ ] Add periodic `getRecord` verification for mirrored records that disappear from active pulls.
- [ ] Mark local rows deleted when remote `getRecord` returns not found and no local dirty edit exists.
- [ ] Add deletion tests for local deletes, remote not found, and link removal records.

## Phase 8: Margin note sync

- [ ] Map Marker annotations, highlights, underlines, and notes to `at.margin.note`.
- [ ] Use `margin_poptart` `NoteRecord`, `Target`, `Selector`, and `Body` types in the mapper.
- [ ] Choose remote selector shape from Marker's local selector array.
- [ ] Preserve full local selector arrays even when the remote record stores one selector.
- [ ] Map highlight color to `NoteRecord.color` when available and keep unsupported style hints local.
- [ ] Push notes through the outbox worker.
- [ ] Pull remote `at.margin.note` records.
- [ ] Import remote notes without aggressive dedupe.
- [ ] Add tests for highlight, underline, note, malformed selector, and duplicate note cases.

## Phase 9: product polish

- [ ] Add manual sync button and last-sync timestamp.
- [ ] Show per-account sync errors in settings.
- [ ] Add account disconnect behavior that leaves local data intact.
- [ ] Add privacy copy for what sync publishes.
- [ ] Add separate opt-in controls for annotation sync.
- [ ] Add lightweight diagnostics export for sync state without secrets.

## Later work

- [ ] Add feeds from followed collections/users using `network.cosmik.follow`.
- [ ] Add support for public/open collections.
- [ ] Use `com.atproto.repo.applyWrites` for batched writes.
