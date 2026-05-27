# RSS integration spec

## Goal

Add RSS/Atom/JSON Feed support to Marker as a calm reading inbox for the open web.
Feeds help users discover new pages from sources they trust, then open, save, and
annotate those pages in the existing Marker browser and library.

RSS is an intake layer, not a replacement for Marker bookmarks, annotations, or the
browser. Marker should never sync every feed item as a blanket operation. Sync applies
to the feed subscriptions themselves, if the user opts in, and to links from feeds only
after the user saves them.

## Product fit

Marker is a local-first browser for intentional reading and annotation. RSS fits when it
is treated as:

- a user-controlled source list;
- an unread queue for articles from those sources;
- a path into the existing WebView reader;
- provenance for pages that later become bookmarks or annotations.

RSS does not fit if it becomes an algorithmic feed, public activity stream, engagement
loop, or remote archive of every item a feed publishes.

## Principles

- **Subscriptions are durable.** Feed sources are user intent and may be imported,
  exported, and optionally synced.
- **Feed items are ephemeral until acted on.** Items discovered from feeds remain local
  cache/inbox data unless the user saves or annotates the linked page.
- **Saved links use the existing bookmark model.** A saved feed item becomes a Marker
  bookmark/card, not a special RSS record.
- **Annotations target the page URL.** Notes and highlights attach to the article
  URL/canonical URL, not the feed item ID.
- **No blanket feed-item sync.** Marker must not publish or sync every fetched item just
  because a feed is followed.
- **Local-first reading state.** Read/unread/archive state is local by default.
- **Portable baseline.** OPML import/export should work even if account sync is never
  enabled.

## Supported feed formats

Initial support should include:

- RSS 2.0;
- Atom;
- JSON Feed 1.x;
- OPML import/export for subscriptions.

Feed parsing must be defensive. Invalid entries, partial metadata, malformed dates,
relative URLs, and bad HTML summaries should not break the refresh for the whole feed.

## Information architecture

RSS adds a feed inbox to the Library.

```text
Library
├── Inbox / Feeds
│   ├── Unread
│   ├── Saved from feeds
│   ├── All feed items
│   └── Sources
├── Bookmarks
├── Annotations
├── History
└── Settings
```

The main browser remains the reading surface. Tapping a feed item opens the item URL in
`BrowserScreen` using the same WebView, ad blocker, selection bridge, annotation
toolbar, and sidebar as ordinary browsing.

## Primary user flows

### Add a feed

1. User enters a feed URL or site URL.
2. Marker fetches the URL.
3. If it is a feed, Marker adds it directly.
4. If it is an HTML page, Marker discovers feed links from `<link rel="alternate">`.
5. If multiple feeds are found, Marker asks the user which feed to follow.
6. Marker stores the feed source locally and refreshes recent items.

### Import subscriptions

1. User chooses an OPML file.
2. Marker parses feed outlines.
3. Marker previews new, duplicate, and invalid feeds.
4. User imports selected feeds.
5. Marker stores sources and starts a refresh.

### Read from the inbox

1. User opens Library → Inbox.
2. User sees unread feed items grouped by date or source.
3. User taps an item.
4. Marker opens the item URL in the WebView.
5. User can read, highlight, underline, note, bookmark, or share as usual.

### Save a feed item

1. User taps Save on a feed item or bookmarks it from the opened page.
2. Marker creates or updates a normal `Bookmarks` row for the item URL/canonical URL.
3. Marker records feed provenance locally.
4. If bookmark sync is enabled, the bookmark syncs as a Semble/Cosmik card.
5. The original feed item remains local cache/inbox data.

### Annotate a feed article

1. User opens a feed item in the WebView.
2. User creates a highlight, underline, or note.
3. Marker persists the annotation against the page URL/canonical URL.
4. If annotation sync is enabled, the annotation may sync as `at.margin.note`.
5. Marker does not sync the feed item record merely because the page was opened.

## Local data model

All Drift changes require migrations.

### Feed sources

```text
FeedSources
- id TEXT PRIMARY KEY
- feedUrl TEXT UNIQUE NOT NULL
- siteUrl TEXT NULL
- title TEXT NOT NULL
- description TEXT NULL
- faviconUrl TEXT NULL
- format TEXT NOT NULL -- rss, atom, jsonFeed, unknown
- createdAt DATETIME NOT NULL
- updatedAt DATETIME NOT NULL
- lastFetchedAt DATETIME NULL
- lastSuccessfulFetchAt DATETIME NULL
- lastFetchError TEXT NULL
- deletedAt DATETIME NULL
```

`feedUrl` is the subscription identity. Normalize for duplicate detection, but preserve
the original URL for display and export.

### Feed items

```text
FeedItems
- id TEXT PRIMARY KEY
- feedSourceId TEXT NOT NULL REFERENCES FeedSources(id)
- url TEXT NOT NULL
- canonicalUrl TEXT NULL
- guid TEXT NULL
- title TEXT NOT NULL
- author TEXT NULL
- summary TEXT NULL
- imageUrl TEXT NULL
- publishedAt DATETIME NULL
- updatedAt DATETIME NULL
- discoveredAt DATETIME NOT NULL
- readAt DATETIME NULL
- archivedAt DATETIME NULL
- savedBookmarkId TEXT NULL REFERENCES Bookmarks(id)
- openedPageId TEXT NULL REFERENCES Pages(id)
- deletedAt DATETIME NULL
- UNIQUE(feedSourceId, guid)
```

When `guid` is unavailable or unstable, repositories should deduplicate by normalized
URL within the same feed source. Do not deduplicate aggressively across different feeds
because the same URL appearing in multiple feeds can be useful provenance.

### Feed item sources / provenance

If the same URL appears in multiple feeds, Marker should be able to show that provenance
without duplicating the saved bookmark. If the simple `FeedItems.savedBookmarkId`
relationship becomes insufficient, add a join table:

```text
FeedItemBookmarks
- id TEXT PRIMARY KEY
- feedItemId TEXT NOT NULL REFERENCES FeedItems(id)
- bookmarkId TEXT NOT NULL REFERENCES Bookmarks(id)
- createdAt DATETIME NOT NULL
- UNIQUE(feedItemId, bookmarkId)
```

### Feed settings

```text
FeedSettings
- key TEXT PRIMARY KEY
- value TEXT NOT NULL
- updatedAt DATETIME NOT NULL
```

Initial keys:

| Key                             | Default | Meaning                                                       |
| ------------------------------- | ------- | ------------------------------------------------------------- |
| `feed_refresh_enabled`          | `true`  | Allows manual and scheduled refreshes.                        |
| `feed_refresh_interval_minutes` | `360`   | Target refresh interval when background refresh is available. |
| `feed_item_retention_days`      | `90`    | Local cache retention for unsaved, archived items.            |
| `feed_notify_new_items`         | `false` | Notifications are off by default.                             |

## Relationship to existing models

```text
FeedSource
  └── FeedItem
        ├── opens as Page
        ├── may be saved as Bookmark
        └── may lead to Annotation through Page/WebView
```

A feed item is not a bookmark. A bookmark is a deliberate save.

A feed item is not an annotation target. An annotation target is the page source URL
plus selectors.

A feed item is not browsing history. Opening a feed item can create a normal browser
history entry, but feed refreshes themselves must not.

## Sync model

### What may sync

Only these RSS-related records should be candidates for account sync:

- feed subscriptions/sources, if the user enables feed subscription sync;
- saved links from feeds, as normal bookmark/card records;
- annotations created on feed-linked pages, as normal Margin note records.

### What must not sync as a blanket

Marker must not sync all fetched feed items. Specifically, it should not automatically
publish or mirror:

- every item returned by a feed refresh;
- unread/read state for every item;
- archived/hidden state;
- refresh timestamps;
- fetch errors;
- local feed ranking or grouping state.

These are local inbox/cache concerns unless a future feature explicitly adds private
feed-state sync with clear user consent.

### ATProto/Semble interaction

Saved feed links reuse the existing bookmark sync mapping:

```text
Bookmarks → network.cosmik.card
BookmarkFolders / Collections → network.cosmik.collection
BookmarkCollectionLinks → network.cosmik.collectionLink
```

Annotations reuse the existing Margin mapping:

```text
Annotations + Targets + Bodies → at.margin.note
```

Feed subscription sync should be treated as a separate opt-in from bookmark sync and
annotation sync. If no shared Semble/Cosmik feed subscription lexicon exists when
implemented, Marker should either:

1. keep feed subscriptions local with OPML import/export only; or
2. define a small Marker-owned private sync record for subscriptions after the rest of
   ATProto sync is stable.

Do not encode every feed item as `network.cosmik.card`. A card should represent a saved link.

## Feed subscription record shape for future sync

If Marker adds subscription sync, the remote shape should represent feeds, not feed contents.

Example conceptual record:

```json
{
  "$type": "app.marker.feed.subscription",
  "feedUrl": "https://example.com/feed.xml",
  "siteUrl": "https://example.com",
  "title": "Example",
  "createdAt": "2026-05-27T00:00:00.000Z",
  "updatedAt": "2026-05-27T00:00:00.000Z"
}
```

This record is intentionally small. It should not include fetched items.

## UI requirements

### Inbox

The inbox should support:

- unread count;
- grouping by source or date;
- title, source, timestamp, and summary preview;
- Open;
- Save;
- Mark read/unread;
- Archive/hide;
- Refresh.

### Sources

The sources screen should support:

- add feed or site URL;
- import OPML;
- export OPML;
- edit title;
- delete/unfollow feed;
- show last refresh status;
- manual refresh per feed;
- disable refresh for a feed.

### Browser integration

Add page-level actions where appropriate:

- Follow Site, when feeds are discovered on the current page;
- View Feed Source, when the current page was opened from a feed item;
- Save Article, using existing bookmark behavior.

The browser chrome should not become feed-centric. Feed actions belong in the Library,
source management, or the browser overflow menu.

## Feed discovery

When the user asks to follow a site, Marker should inspect the current page for:

```html
<link rel="alternate" type="application/rss+xml" href="..." />
<link rel="alternate" type="application/atom+xml" href="..." />
<link rel="alternate" type="application/feed+json" href="..." />
```

Resolve relative URLs against the page URL. If multiple candidates exist, present a
chooser with titles and URLs.

## Refresh behavior

- Manual refresh should always be available.
- Background refresh should be conservative and respect platform constraints.
- Failed feeds should store an error and keep existing items.
- Refresh should not delete old items immediately just because they disappear from the
  latest feed response.
- Retention cleanup should only remove unsaved, unannotated, archived items older than
  the configured retention window.

## Privacy

- Feed refreshes contact the feed host and reveal the user's IP address to that host, as
  any RSS reader does.
- Marker should not proxy feeds through a Marker service in the initial design.
- Feed subscriptions are local unless subscription sync is explicitly enabled.
- Fetched feed items are local cache and should not be synced wholesale.
- Read/unread/archive state stays local by default.

## Test requirements

Add tests with each implementation step:

- RSS, Atom, and JSON Feed parser tests;
- malformed feed and partial item tests;
- relative URL resolution tests;
- feed discovery tests from HTML;
- OPML import/export tests;
- repository tests for source/item dedupe;
- migration tests for new Drift tables;
- inbox filtering tests for unread, archived, saved, and source filters;
- save flow tests proving saved feed items become normal bookmarks;
- sync tests proving feed refresh does not enqueue outbox records for every item;
- sync tests proving saved links and opted-in subscriptions are the only RSS-related
  sync candidates.
