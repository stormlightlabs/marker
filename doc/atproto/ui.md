# ATProto sync UI plan

This document covers the UI needed for the current ATProto integration: OAuth connection, bookmark sync, Margin annotation sync, status, privacy copy, and diagnostics.

## Current integration state

Implemented backend pieces:

- OAuth auth repository and secure session store.
- Poptart repo client wrapper.
- Settings row for connect/disconnect.
- Semble/Cosmik bookmark pull for:
  - `network.cosmik.card`
  - `network.cosmik.collection`
  - `network.cosmik.collectionLink`
- Local import into bookmarks, folders, and folder memberships.
- Duplicate, malformed-record, and dirty-row conflict counts.

Current UI gap:

- Login still uses a copy/paste authorization URL and callback URL flow.
- Pull is not exposed as a user action.
- Sync status is not visible beyond connected/disconnected state.

## UX principles

- Treat ATProto sync as opt-in.
- Explain that bookmark sync publishes records to the user's ATProto repo.
- Keep browser history out of sync copy and controls.
- Keep annotation sync separate from bookmark sync.
- Put bookmark and annotation sync under one ATProto Sync umbrella with separate opt-ins, status, and privacy copy.
- Default Margin annotation sync to off until the user opts in.
- Prefer clear recovery actions over raw protocol errors.
- Never show tokens, refresh material, DPoP keys, or OAuth context in UI or diagnostics.

## Login / account connection

### Entry point

Location: Settings → Sync → ATProto Sync.

Disconnected state should show:

- title: `ATProto Sync`
- subtitle: `Connect a Bluesky or Atmosphere account`
- primary action: `Connect`

### Connect sheet

The connect action should open a sheet or page with:

- title: `Connect ATProto`
- body copy:
  - `Use your Bluesky or Atmosphere account to import Semble/Cosmik bookmarks.`
  - `Bookmark sync publishes bookmark records to your ATProto repo. Browser history stays local.`
- optional handle field:
  - placeholder: `alice.bsky.social`
  - helper: `Optional. Leave blank to choose an account in the browser.`
- primary button: `Continue`
- secondary button: `Cancel`

### Browser launch

On `Continue`:

1. Call `AtprotoAuthRepository.startConnect(handle: ...)`.
2. Open the returned authorization URL in the system browser.
3. Move UI to a waiting state.

Use a browser/deep-link helper such as `flutter_web_auth_2` or an equivalent package that can:

- open the system browser or auth session;
- wait for a callback URL;
- return the full callback URL to Dart.

The current manual copy/paste callback flow should remain available only behind a debug flag if it is kept at all.

### Callback handling

Production callback:

```text
https://marker.stormlightlabs.org/oauth/callback
```

Development fallback:

```text
marker-dev://oauth-callback
```

When the app receives the callback URL:

1. Call `AtprotoAuthRepository.completeConnect(callbackUrl)`.
2. Show connected state.
3. Offer an immediate import action.

Post-connect prompt:

- title: `Import bookmarks now?`
- body: `Marker can pull Semble/Cosmik bookmarks and collections from your ATProto repo.`
- primary: `Import bookmarks`
- secondary: `Not now`

### Login states

Represent these states in the UI controller:

- `idle`
- `startingOAuth`
- `waitingForCallback`
- `completingOAuth`
- `connected`
- `failed(message)`

Failures should keep the user in the connect sheet with retry and cancel actions.

Common error messages:

| Cause                         | User message                                                    |
| ----------------------------- | --------------------------------------------------------------- |
| OAuth start failed            | `Could not start sign in. Check your connection and try again.` |
| Browser/auth session canceled | `Sign in was canceled.`                                         |
| Missing pending context       | `Sign in expired. Start again.`                                 |
| State mismatch                | `Sign in could not be verified. Start again.`                   |
| Token exchange failed         | `Could not finish sign in. Try again.`                          |
| Secure storage unavailable    | `Marker could not save the session securely on this device.`    |

## Connected settings UI

Connected state should show:

- title: `ATProto Sync`
- subtitle: `Connected as @handle` or `Connected as did:...`
- detail rows:
  - account DID
  - handle, if known
  - PDS endpoint, if known
  - last bookmark import time
  - last error, if any
- actions:
  - `Import bookmarks`
  - `Disconnect`

Disconnect behavior:

- Clear OAuth session material from secure storage.
- Leave local bookmarks and imported data intact.
- Leave sync metadata available for diagnostics unless a later data-removal flow explicitly clears it.

Disconnect confirmation copy:

- title: `Disconnect ATProto?`
- body: `Marker will remove the saved sign-in session. Imported bookmarks stay on this device.`
- destructive action: `Disconnect`
- cancel: `Cancel`

## Bookmark import UI

### Manual import action

Location options:

- Settings → ATProto Sync → `Import bookmarks`
- Optional secondary entry in Bookmarks screen after account connection exists.

Initial scope: manual pull only.

Import action flow:

1. Disable the button.
2. Show spinner with `Importing bookmarks...`.
3. Call `SembleBookmarkPullService.pull(accountDid)`.
4. Show a result summary.

### Result summary

Show counts from `SembleBookmarkPullResult`:

- imported bookmarks/cards
- imported folders/collections
- imported collection links
- duplicates found
- conflicts skipped
- malformed records skipped

Suggested copy:

```text
Imported 12 bookmarks, 3 folders, and 18 folder links.
Skipped 4 duplicates, 1 conflict, and 2 malformed records.
```

For zero changes:

```text
No new bookmarks found.
```

### Conflict handling

Current backend behavior skips dirty mirrored local rows and counts them as conflicts.

UI for this phase:

- Show conflict count in result summary.
- Add link/button: `View sync issues` if conflicts or malformed records exist.

Do not build record-by-record conflict resolution yet. That belongs after push and deletion sync exist.

## Sync issues / diagnostics UI

Add a simple diagnostics screen or expandable section under ATProto Sync.

Show:

- collection name
- last successful sync time
- last error
- latest import summary, if stored later

For Phase 5, `AtprotoSyncState` only stores cursor, last success time, and last error. If import summaries should persist across app restarts, add a small diagnostics table or encode a non-secret summary in `lastError` only when there is an actual error. Prefer a dedicated diagnostics model later.

Do not show:

- access token
- refresh token
- DPoP nonce
- public/private keys
- OAuth pending context

## Privacy copy

Use this in the connect sheet or connected detail panel:

```text
Bookmark sync writes Semble/Cosmik bookmark records to your ATProto repo. Browser history stays local. Annotation sync is separate and off by default.
```

For collections:

```text
Imported collections become Marker folders. Synced private collections use CLOSED access unless you choose otherwise later.
```

## Implementation tasks

### Login UX

- [x] Add a proper ATProto connect sheet/page.
- [x] Add optional handle input with validation and trimming.
- [x] Add browser launch + callback capture using `flutter_web_auth_2` or equivalent.
- [x] Wire callback URL to `AtprotoAuthRepository.completeConnect`.
- [x] Keep manual copy/paste callback only behind a debug flag, or remove it.
- [x] Add login state controller tests for success, cancel, interrupted state, and token failure.

### Connected settings

- [x] Replace the current minimal Settings row with connected/disconnected detail states.
- [x] Show DID, handle, PDS endpoint, last import time, and last error.
- [x] Add disconnect confirmation.
- [x] Verify disconnect clears secure session material and leaves local data intact.

### Bookmark import

- [x] Add `Import bookmarks` action for connected accounts.
- [x] Wire action to `SembleBookmarkPullService.pull(accountDid)`.
- [x] Show loading, success, empty, partial-error, and failure states.
- [x] Display import counts for cards, collections, links, duplicates, conflicts, and malformed records.
- [x] Add widget/controller tests for result summaries.

### Diagnostics

- [x] Add sync status section listing tracked collections.
- [x] Show `AtprotoSyncState.lastSuccessfulSyncAt` and `lastError`.

## Bookmark push UI

Push starts after account connection and stays opt-in with bookmark sync. Do not add a separate "publish everything" button unless push is disabled by default; the safer default is to show status and let the sync worker run from explicit sync actions until background sync exists.

### Status in connected settings

Add a compact push status block under ATProto Sync:

- `Local changes pending: N`
- `Last push: <timestamp or Never>`
- `Last push error: <message or None>`
- `Retrying after: <timestamp>` when backoff is active

Use plain-language operation labels:

| Operation | Label                         |
| --------- | ----------------------------- |
| create    | `New remote record`           |
| update    | `Update remote record`        |
| delete    | `Delete remote record`        |

Avoid raw JSON payloads in the normal settings UI.

### Manual sync action

Rename `Import bookmarks` to `Sync bookmarks` when push exists. The action should:

1. Push pending local bookmark, folder, and folder-link changes.
2. Pull remote Semble/Cosmik records.
3. Run remote deletion verification.
4. Show one combined result summary.

Button states:

- idle: `Sync bookmarks`
- running: `Syncing bookmarks...`
- disabled when disconnected or when another sync is running

### Result summary

Show separate pull and push counts:

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

### Outbox diagnostics

In diagnostics, show aggregate outbox health:

- pending creates
- pending updates
- pending deletes
- failed attempts
- oldest pending change time
- next retry time, when available

For failed items, show local type, operation, attempt count, and a short error. Do not show record JSON, OAuth material, DPoP material, or raw session state.

### Error recovery

If a push fails, keep local data unchanged and leave the outbox item queued. Show:

- primary action: `Retry sync`
- secondary action: `View sync issues`

Record-level conflict resolution should wait until push, pull, and deletion paths all report enough information to explain the conflict.

## Margin annotation sync UI

Margin integration syncs Marker annotations with `at.margin.note` records. Treat this as a separate product surface from bookmark sync because annotations can include highlighted text, underlines, comments, colors, and the page URL.

### Settings entry

Location: Settings → Sync → ATProto Sync → `Annotations`.

When connected, show an annotation sync card below bookmark sync. A global `Sync now` action may run all enabled sync domains, but the UI should still show separate bookmark and annotation results.

- title: `Annotations`
- subtitle when disabled: `Off. Sync highlights and notes with Margin.`
- subtitle when enabled: `Syncing highlights and notes as Margin records.`
- toggle: `Sync annotations`
- actions when enabled:
  - `Sync annotations now`
  - `View annotation sync issues` when conflicts, malformed records, or failed outbox items exist

The toggle should be independent from bookmark sync. Turning it on should not immediately publish annotations without a confirmation step.

### Opt-in confirmation

Before enabling annotation sync, show:

- title: `Sync annotations?`
- body: `Marker will import and publish Margin note records in your ATProto repo. Synced records can include page URLs, selected text, notes, and highlight colors.`
- primary action: `Enable annotation sync`
- secondary action: `Cancel`

After enabling, offer:

- primary action: `Sync annotations now`
- secondary action: `Not now`

### Manual sync action

`Sync annotations now` should:

1. Push pending local `at.margin.note` changes.
2. Pull remote `at.margin.note` records.
3. Show a short result summary.

Button states:

- idle: `Sync annotations now`
- running: `Syncing annotations...`
- disabled when disconnected, annotation sync is off, or another annotation sync is running

Suggested summary copy:

```text
Published 3 annotation changes.
Imported 2 Margin notes.
Skipped 1 malformed record.
```

For no changes:

```text
Annotations are up to date.
```

### Status and diagnostics

In the ATProto diagnostics section, include `at.margin.note`, `at.margin.collection`, and `at.margin.collectionItem` with:

- last successful annotation sync time
- last annotation sync error
- pending annotation and annotation-collection changes
- failed annotation pushes
- malformed remote notes skipped by the last run, if retained by a future diagnostics model

For failed annotation items, show local annotation ID, operation, attempt count, and a short error. Do not show full selector JSON, note body text, OAuth material, DPoP material, or raw record JSON in the standard UI. A later explicit diagnostics export may include non-secret record metadata after a separate privacy review.

### Annotation sync issues

Initial issue UI can stay aggregate-only:

- `Malformed remote notes: N`
- `Local conflicts skipped: N`
- `Failed pushes: N`

Record-by-record conflict resolution should wait until the app can explain both sides safely. If a local annotation is dirty and a remote note also changed, keep the local row unchanged and show the conflict count.

### Reader and annotation UI hooks

Reader screens should not add protocol labels beside every highlight. Add a small sync indicator only where users already manage annotations:

- annotation detail screen: optional `Synced with Margin` / `Pending sync` line
- annotation list/sidebar: no per-row status unless there is an error
- delete confirmation: if annotation sync is enabled, say `This also deletes the synced Margin note on the next sync.`
- tag editor: allow adding/removing annotation tags; tags sync through `at.margin.note.tags`.
- tag filters: support filtering/searching annotations by tag.
- collection editor: allow users to create curated annotation collections and add/remove annotations; these sync through `at.margin.collection` and `at.margin.collectionItem`.

### Deferred Margin UI

Keep these out of the first annotation sync UI:

- editing rich-text facets directly;
- editing rights/license metadata;
- editing labels/content warnings;
- showing generator metadata.

### Later UI, after push/deletion phases

- [x] Add local-change push status.
- [x] Add retry queue/outbox status.
- [x] Add delete sync status.
- [x] Add annotation sync opt-in and Margin note import/export status.
- [ ] Add conflict resolution UI only after both pull and push exist.
- [ ] Add non-secret diagnostics export
