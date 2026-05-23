import { createChromeBookmark, type ChromeBookmarksPort } from './chrome-bookmarks';
import type { BookmarkRepository, CreateBookmarkInput } from '@/db/bookmark-repository';
import type { BookmarkRecord } from '@/db/schema';

export const bookmarkSaveDestinations = ['marker', 'chrome', 'both'] as const;

export type BookmarkSaveDestination = (typeof bookmarkSaveDestinations)[number];

export type SaveBookmarkInput = Omit<CreateBookmarkInput, 'chromeBookmarkId'> & {
  chromeParentId?: string;
  destination: BookmarkSaveDestination;
  hasChromePermission: boolean;
};

export type SaveBookmarkResult =
  | { ok: true; markerBookmark?: BookmarkRecord; chromeBookmarkId?: string; chromeSkippedReason?: string }
  | { ok: false; reason: string };

export class BookmarkSaveService {
  constructor(
    private readonly bookmarks: BookmarkRepository,
    private readonly chromeBookmarks: ChromeBookmarksPort,
  ) {}

  async saveBookmark(input: SaveBookmarkInput): Promise<SaveBookmarkResult> {
    if (input.destination === 'marker') {
      return { ok: true, markerBookmark: await this.createMarkerBookmark(input) };
    }

    if (!input.hasChromePermission) {
      if (input.destination === 'both') {
        return {
          ok: true,
          markerBookmark: await this.createMarkerBookmark(input),
          chromeSkippedReason: 'Chrome bookmark permission was not granted.',
        };
      }

      return { ok: false, reason: 'Chrome bookmark permission was not granted.' };
    }

    const chromeBookmark = await createChromeBookmark(this.chromeBookmarks, {
      parentId: input.chromeParentId,
      title: input.title,
      url: input.url,
    });

    if (input.destination === 'chrome') {
      return { ok: true, chromeBookmarkId: chromeBookmark.id };
    }

    return {
      ok: true,
      chromeBookmarkId: chromeBookmark.id,
      markerBookmark: await this.createMarkerBookmark(input, chromeBookmark.id),
    };
  }

  private async createMarkerBookmark(input: SaveBookmarkInput, chromeBookmarkId?: string): Promise<BookmarkRecord> {
    return this.bookmarks.createBookmark({
      chromeBookmarkId,
      description: input.description,
      folderId: input.folderId,
      pageId: input.pageId,
      sortOrder: input.sortOrder,
      tags: input.tags,
      title: input.title,
      url: input.url,
    });
  }
}
