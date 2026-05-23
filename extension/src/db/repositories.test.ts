import 'fake-indexeddb/auto';
import { afterEach, describe, expect, it } from 'vitest';
import { AnnotationRepository } from './annotation-repository';
import { BookmarkFolderRepository, BookmarkRepository } from './bookmark-repository';
import { ExportRepository } from './export-repository';
import { PageRepository } from './page-repository';
import { createMarkerDb, type MarkerDb } from './schema';

const databases: MarkerDb[] = [];

function testDb(): MarkerDb {
  const db = createMarkerDb(`marker-test-${crypto.randomUUID()}`);
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

describe('PageRepository', () => {
  it('stores loaded and canonical URLs and updates visits by canonical URL', async () => {
    const pages = new PageRepository(testDb());
    const first = await pages.recordPageVisit({
      url: 'https://example.com/article?utm=1',
      canonicalUrl: 'https://example.com/article',
      title: 'First title',
      visitedAt: '2026-05-22T00:00:00.000Z',
    });
    const second = await pages.recordPageVisit({
      url: 'https://example.com/article?utm=2',
      canonicalUrl: 'https://example.com/article',
      title: 'Updated title',
      visitedAt: '2026-05-22T01:00:00.000Z',
    });

    expect(second.id).toBe(first.id);
    expect(second.url).toBe('https://example.com/article?utm=1');
    expect(second.canonicalUrl).toBe('https://example.com/article');
    expect(second.title).toBe('Updated title');
  });
});

describe('bookmark repositories', () => {
  it('supports nested folders, bookmark order, tags, Chrome IDs, and soft deletion', async () => {
    const db = testDb();
    const folders = new BookmarkFolderRepository(db);
    const bookmarks = new BookmarkRepository(db);

    const root = await folders.createFolder({ title: 'Research', sortOrder: 2, now: '2026-05-22T00:00:00.000Z' });
    const child = await folders.createFolder({
      title: 'Browsers',
      parentId: root.id,
      sortOrder: 1,
      now: '2026-05-22T00:00:00.000Z',
    });
    const bookmark = await bookmarks.createBookmark({
      folderId: child.id,
      url: 'https://example.com',
      title: 'Example',
      chromeBookmarkId: 'chrome-1',
      tags: ['browser', 'research'],
      sortOrder: 5,
      now: '2026-05-22T00:00:00.000Z',
    });

    expect(await folders.listFolders(root.id)).toMatchObject([{ id: child.id, parentId: root.id }]);
    expect(await folders.listAllFolders()).toHaveLength(2);
    expect(await bookmarks.listBookmarks(child.id)).toMatchObject([
      { id: bookmark.id, chromeBookmarkId: 'chrome-1', tags: ['browser', 'research'] },
    ]);
    expect(await bookmarks.searchBookmarks('research')).toHaveLength(1);
    expect(await bookmarks.listAllBookmarks()).toHaveLength(1);
    expect(await bookmarks.findBookmarkForUrl('https://example.com')).toMatchObject({ id: bookmark.id });

    await bookmarks.softDeleteBookmark(bookmark.id, '2026-05-22T02:00:00.000Z');
    expect(await bookmarks.listBookmarks(child.id)).toHaveLength(0);
    expect(await bookmarks.listAllBookmarks()).toHaveLength(0);
    expect(await bookmarks.findBookmarkForUrl('https://example.com')).toBeUndefined();
  });

  it('soft deletes folder trees and contained bookmarks', async () => {
    const db = testDb();
    const folders = new BookmarkFolderRepository(db);
    const bookmarks = new BookmarkRepository(db);

    const root = await folders.createFolder({ title: 'Root' });
    const child = await folders.createFolder({ title: 'Child', parentId: root.id });
    await bookmarks.createBookmark({ folderId: child.id, url: 'https://example.com' });

    await folders.deleteFolderTree(root.id, '2026-05-22T03:00:00.000Z');

    expect(await folders.listFolders()).toHaveLength(0);
    expect(await folders.listFolders(root.id)).toHaveLength(0);
    expect(await bookmarks.listBookmarks(child.id)).toHaveLength(0);
  });
});

describe('AnnotationRepository', () => {
  it('creates annotations with targets and mobile-compatible bodies', async () => {
    const db = testDb();
    const annotations = new AnnotationRepository(db);
    const created = await annotations.createAnnotation({
      pageId: 'page-1',
      sourceUrl: 'https://example.com/article',
      motivation: 'commenting',
      selector: [{ type: 'TextQuoteSelector', exact: 'selected text', prefix: 'before ', suffix: ' after' }],
      bodies: [
        { type: 'TextualBody', format: 'text/markdown', value: '# Note' },
        { type: 'StyleHint', format: 'application/json', value: '{"style":"highlight","color":"#ffd85a"}' },
      ],
      now: '2026-05-22T00:00:00.000Z',
    });

    expect(created.annotation.motivation).toBe('commenting');
    expect(created.targets[0]?.selector[0]).toMatchObject({ type: 'TextQuoteSelector', exact: 'selected text' });
    expect(created.bodies).toHaveLength(2);

    expect(await annotations.listAllAnnotations()).toHaveLength(1);

    await annotations.updateMarkdownBody(created.annotation.id, 'updated', '2026-05-22T02:00:00.000Z');
    const [updated] = await annotations.listAnnotationsForPage('page-1');
    expect(updated?.bodies.find((body) => body.format === 'text/markdown')?.value).toBe('updated');

    await annotations.deleteAnnotation(created.annotation.id, '2026-05-22T03:00:00.000Z');
    expect(await annotations.listAnnotationsForPage('page-1')).toHaveLength(0);
  });
});

describe('ExportRepository', () => {
  it('round trips pages, bookmarks, folders, annotations, targets, bodies, and metadata', async () => {
    const sourceDb = testDb();
    const pages = new PageRepository(sourceDb);
    const folders = new BookmarkFolderRepository(sourceDb);
    const bookmarks = new BookmarkRepository(sourceDb);
    const annotations = new AnnotationRepository(sourceDb);

    const page = await pages.recordPageVisit({
      url: 'https://example.com/article',
      canonicalUrl: 'https://example.com/canonical',
      metadata: { title: 'Metadata title', jsonLd: [{ '@type': 'Article' }] },
    });
    const folder = await folders.createFolder({ title: 'Articles' });
    await bookmarks.createBookmark({ folderId: folder.id, pageId: page.id, url: page.url, tags: ['article'] });
    await annotations.createAnnotation({
      pageId: page.id,
      sourceUrl: page.url,
      motivation: 'highlighting',
      selector: [{ type: 'TextPositionSelector', start: 1, end: 4 }],
      bodies: [{ type: 'StyleHint', format: 'application/json', value: '{"style":"underline"}' }],
    });

    const exported = await new ExportRepository(sourceDb).exportJson('2026-05-22T00:00:00.000Z');
    const targetDb = testDb();
    await new ExportRepository(targetDb).importJson(exported);

    expect(await targetDb.pages.count()).toBe(1);
    expect(await targetDb.bookmarkFolders.count()).toBe(1);
    expect(await targetDb.bookmarks.count()).toBe(1);
    expect(await targetDb.annotations.count()).toBe(1);
    expect(await targetDb.annotationTargets.count()).toBe(1);
    expect(await targetDb.annotationBodies.count()).toBe(1);
    const importedPages = await targetDb.pages.toArray();
    expect(importedPages[0]?.metadata?.jsonLd[0]?.['@type']).toBe('Article');
  });
});
