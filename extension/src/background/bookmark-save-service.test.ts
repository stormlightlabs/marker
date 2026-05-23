import 'fake-indexeddb/auto';
import { afterEach, describe, expect, it } from 'vitest';
import { BookmarkSaveService } from './bookmark-save-service';
import type { ChromeBookmarksPort } from './chrome-bookmarks';
import { BookmarkRepository } from '@/db/bookmark-repository';
import { createMarkerDb, type MarkerDb } from '@/db/schema';

const databases: MarkerDb[] = [];

function testDb(): MarkerDb {
  const db = createMarkerDb(`marker-save-test-${crypto.randomUUID()}`);
  databases.push(db);
  return db;
}

function chromePort(): ChromeBookmarksPort & { created: Array<{ parentId?: string; title?: string; url?: string }> } {
  const created: Array<{ parentId?: string; title?: string; url?: string }> = [];
  return {
    created,
    async create(details) {
      created.push(details);
      return { id: `chrome-${created.length}`, title: details.title ?? '', url: details.url };
    },
    async getTree() {
      return [];
    },
  };
}

afterEach(async () => {
  await Promise.all(
    databases.splice(0).map(async (db) => {
      await db.delete();
    }),
  );
});

describe('BookmarkSaveService', () => {
  it('saves Marker-only bookmarks without Chrome permission', async () => {
    const db = testDb();
    const port = chromePort();
    const service = new BookmarkSaveService(new BookmarkRepository(db), port);

    const result = await service.saveBookmark({
      destination: 'marker',
      hasChromePermission: false,
      title: 'Example',
      url: 'https://example.com',
    });

    expect(result).toMatchObject({ ok: true, markerBookmark: { title: 'Example', url: 'https://example.com' } });
    expect(port.created).toHaveLength(0);
  });

  it('saves Chrome-only bookmarks when Chrome permission exists', async () => {
    const service = new BookmarkSaveService(new BookmarkRepository(testDb()), chromePort());

    const result = await service.saveBookmark({
      destination: 'chrome',
      hasChromePermission: true,
      title: 'Example',
      url: 'https://example.com',
    });

    expect(result).toEqual({ ok: true, chromeBookmarkId: 'chrome-1' });
  });

  it('links Marker bookmarks to Chrome IDs when saving to both', async () => {
    const service = new BookmarkSaveService(new BookmarkRepository(testDb()), chromePort());

    const result = await service.saveBookmark({
      destination: 'both',
      hasChromePermission: true,
      title: 'Example',
      url: 'https://example.com',
    });

    expect(result).toMatchObject({
      ok: true,
      chromeBookmarkId: 'chrome-1',
      markerBookmark: { chromeBookmarkId: 'chrome-1' },
    });
  });

  it('falls back to Marker-only for both when Chrome permission is denied', async () => {
    const service = new BookmarkSaveService(new BookmarkRepository(testDb()), chromePort());

    const result = await service.saveBookmark({
      destination: 'both',
      hasChromePermission: false,
      title: 'Example',
      url: 'https://example.com',
    });

    expect(result).toMatchObject({
      ok: true,
      chromeSkippedReason: 'Chrome bookmark permission was not granted.',
      markerBookmark: { chromeBookmarkId: undefined },
    });
  });

  it('does not save Chrome-only bookmarks when permission is denied', async () => {
    const db = testDb();
    const service = new BookmarkSaveService(new BookmarkRepository(db), chromePort());

    const result = await service.saveBookmark({
      destination: 'chrome',
      hasChromePermission: false,
      url: 'https://example.com',
    });

    expect(result).toEqual({ ok: false, reason: 'Chrome bookmark permission was not granted.' });
    expect(await db.bookmarks.count()).toBe(0);
  });
});
