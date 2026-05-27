# RSS integration todo

This todo implements `doc/rss/spec.md`. RSS should remain a local-first intake layer.
Do not sync fetched feed items as a blanket operation; sync only feed subscriptions when
explicitly enabled and links the user saves as normal bookmarks.

## Milestone 1: product and model baseline

Deliverables:

- Add Drift tables for `FeedSources` and `FeedItems`.
- Add feed settings keys for refresh enabled, refresh interval, retention, and notifications.
- Add migrations for all new tables/settings.
- Add domain models for feed source, feed item, and feed refresh result.
- Add repository APIs for source CRUD, item upsert, read/unread, archive, and save linkage.

Acceptance:

- Feed sources are deduplicated by normalized feed URL.
- Feed items are deduplicated by source plus GUID when available, with source plus
  normalized URL fallback.
- Feed items can link to an opened page and saved bookmark without becoming bookmarks
  themselves.
- Migration tests pass.

## Milestone 2: feed parsing

Deliverables:

- RSS 2.0 parser.
- Atom parser.
- JSON Feed 1.x parser.
- Shared normalized parsed-feed model.
- Defensive handling for malformed dates, missing titles, relative URLs, invalid
  summaries, and partial items.
- Tests for valid and malformed examples of each format.

Acceptance:

- A bad item does not fail the whole feed refresh when the rest of the feed is usable.
- Relative item URLs resolve against feed/site URLs.
- Summaries are sanitized or stored as safe plain text/Markdown-compatible text.

## Milestone 3: OPML import/export

Deliverables:

- OPML import parser.
- OPML export writer.
- Import preview model for new, duplicate, and invalid feeds.
- UI entry points from feed sources/settings.
- Tests for nested outlines, duplicate feeds, missing XML URLs, and round-trip export.

Acceptance:

- Users can import subscriptions without enabling account sync.
- Users can export all current feed subscriptions as OPML.
- OPML import does not create feed items until refresh runs.

## Milestone 4: feed discovery and add flow

Deliverables:

- Fetch-by-URL service that distinguishes feed documents from HTML pages.
- HTML feed discovery from `<link rel="alternate">` tags.
- Multiple-feed chooser model.
- Browser overflow action: Follow Site when feeds are discovered.
- Add-feed UI in Library/Sources.
- Tests for RSS, Atom, JSON Feed, HTML discovery, relative feed URLs, and no-feed pages.

Acceptance:

- User can add a direct feed URL.
- User can add a website URL and choose from discovered feeds.
- Duplicate feed attempts show the existing subscription instead of creating a second source.

## Milestone 5: refresh engine

Deliverables:

- Manual refresh for one feed.
- Manual refresh for all feeds.
- Conservative scheduled/background refresh where platform support allows.
- Refresh status and last error storage.
- Retention cleanup for old unsaved, unannotated, archived items.
- Tests for refresh success, partial failure, network failure, duplicate item updates,
  and retention behavior.

Acceptance:

- Failed refreshes keep existing feed items.
- Items disappearing from the latest feed response are not immediately deleted.
- Retention cleanup never deletes saved or annotated pages.

## Milestone 6: inbox UI

Deliverables:

- Library → Inbox section.
- Unread, saved-from-feeds, all-items, and source filters.
- Source/date grouping.
- Feed item cards with Open, Save, Mark read/unread, and Archive actions.
- Pull/manual refresh affordance.
- Empty, loading, and error states.
- Widget/controller tests for filters and actions.

Acceptance:

- Opening a feed item loads its URL in the existing `BrowserScreen` WebView.
- Opened items can be marked read.
- Archived items leave the default unread inbox but remain searchable until retention cleanup.

## Milestone 7: save and annotation integration

Deliverables:

- Save action that creates/updates a normal Marker bookmark.
- Link feed items to saved bookmark IDs.
- Preserve source/item provenance for saved-from-feeds views.
- Ensure annotations created after opening a feed item target the page URL/canonical URL.
- Tests for save dedupe, canonical URL handling, opened page linkage, and annotation
  target source.

Acceptance:

- Saving a feed item uses the same bookmark repository behavior as saving any webpage.
- A saved feed link can be placed in normal bookmark folders/collections.
- Annotating a feed article creates normal Marker annotations and does not create
  RSS-specific annotation records.

## Milestone 8: sync boundaries

Deliverables:

- Guardrails so feed refresh never enqueues outbox writes for every fetched item.
- Tests proving fetched feed items do not create `network.cosmik.card` records automatically.
- Tests proving saved feed links enqueue the same bookmark sync work as ordinary saved
  links when bookmark sync is enabled.
- Optional feed subscription sync setting, separate from bookmark and annotation sync.
- If subscription sync is implemented, add mapper/repository tests for subscription records only.

Acceptance:

- No blanket feed item sync exists.
- Saved links from feeds sync as normal bookmarks/cards.
- Annotation sync behavior is unchanged for pages opened from feeds.
- Feed subscription sync is opt-in and syncs only sources/subscriptions, not items.

## Milestone 9: polish and privacy

Deliverables:

- Feed privacy copy explaining refresh requests, local cache, and sync boundaries.
- Settings for refresh interval, retention, and notifications.
- Per-source refresh disable toggle.
- Diagnostics export that includes source status but no secrets.
- Manual QA checklist.

Acceptance:

- Users can understand what does and does not sync.
- Notifications remain off by default.
- Disabling a feed stops refresh without deleting saved bookmarks or annotations.

## Later work

- Private feed subscription sync if a suitable lexicon or Marker-owned record is chosen.
- Cross-device read/unread sync, only with explicit opt-in.
- Reader-mode extraction if it can preserve reliable WebView annotation anchoring.
- Feed folders or source collections.
- Full-text search over locally cached summaries/content when available.
