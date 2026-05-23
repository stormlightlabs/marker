import 'fake-indexeddb/auto';
import { afterEach, describe, expect, it } from 'vitest';
import { createChromeBookmark, importChromeBookmarks, type ChromeBookmarksPort } from './chrome-bookmarks';
import { BookmarkFolderRepository, BookmarkRepository } from '@/db/bookmark-repository';
import { createMarkerDb, type MarkerDb } from '@/db/schema';

const databases: MarkerDb[] = [];

function testDb(): MarkerDb {
  const db = createMarkerDb(`marker-import-test-${crypto.randomUUID()}`);
  databases.push(db);
  return db;
}

afterEach(async () => {
  await Promise.all(
    databases.splice(0).map(async (db) => {
      await db.delete();
    }),
  );
});

describe('createChromeBookmark', () => {
  it('passes bookmark details through to Chrome', async () => {
    const created: Array<{ parentId?: string; title?: string; url?: string }> = [];
    const port: ChromeBookmarksPort = {
      async create(details) {
        created.push(details);
        return { id: 'chrome-1', title: details.title ?? '', url: details.url };
      },
      async getTree() {
        return [];
      },
    };

    await createChromeBookmark(port, { parentId: '1', title: 'Example', url: 'https://example.com' });

    expect(created).toEqual([{ parentId: '1', title: 'Example', url: 'https://example.com' }]);
  });
});

describe('importChromeBookmarks', () => {
  it('maps Chrome trees to Marker folders and bookmarks with Chrome IDs', async () => {
    const db = testDb();
    const port: ChromeBookmarksPort = {
      async create() {
        throw new Error('create should not be called during import');
      },
      async getTree() {
        return [
          {
            id: '0',
            title: '',
            children: [
              {
                id: '1',
                title: 'Bookmarks Bar',
                children: [
                  { id: '10', title: 'Example', url: 'https://example.com' },
                  {
                    id: '11',
                    title: 'Articles',
                    children: [{ id: '12', title: 'Article', url: 'https://example.com/article' }],
                  },
                ],
              },
            ],
          },
        ];
      },
    };

    const result = await importChromeBookmarks(port, new BookmarkFolderRepository(db), new BookmarkRepository(db));

    expect(result.folders.map((folder) => folder.title)).toEqual(['Bookmarks Bar', 'Articles']);
    expect(result.bookmarks).toMatchObject([
      { chromeBookmarkId: '10', title: 'Example', url: 'https://example.com' },
      { chromeBookmarkId: '12', title: 'Article', url: 'https://example.com/article' },
    ]);
    expect(await db.bookmarks.where('chromeBookmarkId').equals('12').count()).toBe(1);
  });
});
