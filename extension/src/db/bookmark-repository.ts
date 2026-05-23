import { createId, nowIso } from './id';
import type { BookmarkFolderRecord, BookmarkRecord, MarkerDb } from './schema';

export type CreateBookmarkFolderInput = { title: string; parentId?: string; sortOrder?: number; now?: string };
export type CreateBookmarkInput = {
  url: string;
  title?: string;
  description?: string;
  folderId?: string;
  pageId?: string;
  chromeBookmarkId?: string;
  tags?: string[];
  sortOrder?: number;
  now?: string;
};

export class BookmarkFolderRepository {
  constructor(private readonly db: MarkerDb) {}

  async createFolder(input: CreateBookmarkFolderInput): Promise<BookmarkFolderRecord> {
    const now = input.now ?? nowIso();
    const folder: BookmarkFolderRecord = {
      id: createId('folder'),
      parentId: input.parentId,
      title: input.title,
      sortOrder: input.sortOrder ?? 0,
      createdAt: now,
      updatedAt: now,
    };
    await this.db.bookmarkFolders.add(folder);
    return folder;
  }

  async moveFolder(id: string, parentId: string | undefined, sortOrder: number, now = nowIso()): Promise<void> {
    await this.db.bookmarkFolders.update(id, { parentId, sortOrder, updatedAt: now });
  }

  async listFolders(parentId?: string): Promise<BookmarkFolderRecord[]> {
    const collection =
      parentId == null
        ? this.db.bookmarkFolders.filter((folder) => folder.parentId == null)
        : this.db.bookmarkFolders.where('parentId').equals(parentId);

    return collection.filter((folder) => folder.deletedAt == null).sortBy('sortOrder');
  }

  async deleteFolderTree(id: string, now = nowIso()): Promise<void> {
    const childFolders = await this.db.bookmarkFolders.where('parentId').equals(id).toArray();
    await Promise.all(childFolders.map((folder) => this.deleteFolderTree(folder.id, now)));
    await this.db.bookmarks.where('folderId').equals(id).modify({ deletedAt: now, updatedAt: now });
    await this.db.bookmarkFolders.update(id, { deletedAt: now, updatedAt: now });
  }

  async listAllFolders(): Promise<BookmarkFolderRecord[]> {
    return this.db.bookmarkFolders.filter((folder) => folder.deletedAt == null).sortBy('sortOrder');
  }
}

export class BookmarkRepository {
  constructor(private readonly db: MarkerDb) {}

  async createBookmark(input: CreateBookmarkInput): Promise<BookmarkRecord> {
    const now = input.now ?? nowIso();
    const bookmark: BookmarkRecord = {
      id: createId('bookmark'),
      folderId: input.folderId,
      pageId: input.pageId,
      chromeBookmarkId: input.chromeBookmarkId,
      url: input.url,
      title: input.title,
      description: input.description,
      tags: input.tags ?? [],
      sortOrder: input.sortOrder ?? 0,
      createdAt: now,
      updatedAt: now,
    };
    await this.db.bookmarks.add(bookmark);
    return bookmark;
  }

  async moveBookmark(id: string, folderId: string | undefined, sortOrder: number, now = nowIso()): Promise<void> {
    await this.db.bookmarks.update(id, { folderId, sortOrder, updatedAt: now });
  }

  async updateTags(id: string, tags: string[], now = nowIso()): Promise<void> {
    await this.db.bookmarks.update(id, { tags, updatedAt: now });
  }

  async softDeleteBookmark(id: string, now = nowIso()): Promise<void> {
    await this.db.bookmarks.update(id, { deletedAt: now, updatedAt: now });
  }

  async findBookmarkForUrl(url: string): Promise<BookmarkRecord | undefined> {
    return this.db.bookmarks
      .where('url')
      .equals(url)
      .filter((bookmark) => bookmark.deletedAt == null)
      .first();
  }

  async listBookmarks(folderId?: string): Promise<BookmarkRecord[]> {
    const collection =
      folderId == null
        ? this.db.bookmarks.filter((bookmark) => bookmark.folderId == null)
        : this.db.bookmarks.where('folderId').equals(folderId);

    return collection.filter((bookmark) => bookmark.deletedAt == null).sortBy('sortOrder');
  }

  async listAllBookmarks(): Promise<BookmarkRecord[]> {
    return this.db.bookmarks.filter((bookmark) => bookmark.deletedAt == null).sortBy('sortOrder');
  }

  async searchBookmarks(query: string): Promise<BookmarkRecord[]> {
    const normalizedQuery = query.trim().toLocaleLowerCase();
    if (normalizedQuery.length === 0) {
      return [];
    }

    return this.db.bookmarks
      .filter((bookmark) => {
        if (bookmark.deletedAt != null) {
          return false;
        }

        const searchable = [bookmark.title, bookmark.url, bookmark.description, ...bookmark.tags]
          .filter((value): value is string => value != null)
          .join(' ')
          .toLocaleLowerCase();
        return searchable.includes(normalizedQuery);
      })
      .toArray();
  }
}
