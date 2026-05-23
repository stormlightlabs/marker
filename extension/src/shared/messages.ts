import type { BookmarkSaveBehavior } from '@/db/settings-repository';
import type { BookmarkSaveDestination, SaveBookmarkResult } from '@/background/bookmark-save-service';
import type { ImportChromeBookmarksResult } from '@/background/chrome-bookmarks';
import type { AnnotationWithParts } from '@/db/annotation-repository';
import type { PageMetadata } from '@/db/schema';
import type { ActiveTabSummary } from './permissions';

export enum MarkerMessageType {
  OpenLibrary = 'marker:open-library',
  OpenOptions = 'marker:open-options',
  GetActiveTabSummary = 'marker:get-active-tab-summary',
  EnableSite = 'marker:enable-site',
  PageVisited = 'marker:page-visited',
  SaveBookmark = 'marker:save-bookmark',
  ImportChromeBookmarks = 'marker:import-chrome-bookmarks',
  GetBookmarkSaveBehavior = 'marker:get-bookmark-save-behavior',
  SetBookmarkSaveBehavior = 'marker:set-bookmark-save-behavior',
}

export type OpenLibraryMessage = { type: MarkerMessageType.OpenLibrary };

export type OpenOptionsMessage = { type: MarkerMessageType.OpenOptions };

export type GetActiveTabSummaryMessage = { type: MarkerMessageType.GetActiveTabSummary };

export type EnableSiteMessage = { type: MarkerMessageType.EnableSite; tabId: number };

export type PageVisitedMessage = { type: MarkerMessageType.PageVisited; url: string; metadata: PageMetadata };

export type SaveBookmarkMessage = {
  type: MarkerMessageType.SaveBookmark;
  destination: BookmarkSaveDestination;
  url: string;
  title?: string;
  folderId?: string;
  chromeParentId?: string;
};

export type ImportChromeBookmarksMessage = { type: MarkerMessageType.ImportChromeBookmarks; folderId?: string };

export type GetBookmarkSaveBehaviorMessage = { type: MarkerMessageType.GetBookmarkSaveBehavior };

export type SetBookmarkSaveBehaviorMessage = {
  type: MarkerMessageType.SetBookmarkSaveBehavior;
  behavior: BookmarkSaveBehavior;
};

export type MarkerMessage =
  | OpenLibraryMessage
  | OpenOptionsMessage
  | GetActiveTabSummaryMessage
  | EnableSiteMessage
  | PageVisitedMessage
  | SaveBookmarkMessage
  | ImportChromeBookmarksMessage
  | GetBookmarkSaveBehaviorMessage
  | SetBookmarkSaveBehaviorMessage;

export type EnableSiteResponse = { ok: true } | { ok: false; reason: string };

export type MarkerMessageResponse<T extends MarkerMessage = MarkerMessage> = T extends GetActiveTabSummaryMessage
  ? ActiveTabSummary
  : T extends PageVisitedMessage
    ? { pageId: string; annotations: AnnotationWithParts[] }
    : T extends EnableSiteMessage
      ? EnableSiteResponse
      : T extends SaveBookmarkMessage
        ? SaveBookmarkResult
        : T extends ImportChromeBookmarksMessage
          ? ImportChromeBookmarksResult | { ok: false; reason: string }
          : T extends GetBookmarkSaveBehaviorMessage
            ? { behavior: BookmarkSaveBehavior }
            : undefined;

const markerMessageTypeValues = new Set<string>(Object.values(MarkerMessageType));

export function isMarkerMessage(value: unknown): value is MarkerMessage {
  if (typeof value !== 'object' || value === null || !('type' in value)) {
    return false;
  }

  const type = (value as { type: unknown }).type;
  if (!markerMessageTypeValues.has(String(type))) {
    return false;
  }

  switch (type) {
    case MarkerMessageType.EnableSite: {
      return typeof (value as { tabId?: unknown }).tabId === 'number';
    }
    case MarkerMessageType.PageVisited: {
      const message = value as { metadata?: unknown; url?: unknown };
      return typeof message.url === 'string' && typeof message.metadata === 'object' && message.metadata !== null;
    }
    case MarkerMessageType.SaveBookmark: {
      const message = value as { destination?: unknown; url?: unknown };
      return typeof message.url === 'string' && typeof message.destination === 'string';
    }
    case MarkerMessageType.SetBookmarkSaveBehavior: {
      return typeof (value as { behavior?: unknown }).behavior === 'string';
    }
    default: {
      return true;
    }
  }
}
