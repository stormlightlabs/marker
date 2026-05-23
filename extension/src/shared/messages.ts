import type { AnnotationDisplayMode, BookmarkSaveBehavior } from '@/db/settings-repository';
import type { BookmarkSaveDestination, SaveBookmarkResult } from '@/background/bookmark-save-service';
import type { ImportChromeBookmarksResult } from '@/background/chrome-bookmarks';
import type { MarkerExport } from '@/db/export-repository';
import type { AnnotationWithParts } from '@/db/annotation-repository';
import type {
  AnnotationMotivation,
  BookmarkFolderRecord,
  BookmarkRecord,
  PageMetadata,
  PageRecord,
  Selector,
} from '@/db/schema';
import type { ActiveTabSummary } from './permissions';

export enum MarkerMessageType {
  OpenLibrary = 'marker:open-library',
  OpenOptions = 'marker:open-options',
  GetActiveTabSummary = 'marker:get-active-tab-summary',
  EnableSite = 'marker:enable-site',
  PageVisited = 'marker:page-visited',
  SaveBookmark = 'marker:save-bookmark',
  ImportChromeBookmarks = 'marker:import-chrome-bookmarks',
  GetLibraryState = 'marker:get-library-state',
  ExportJson = 'marker:export-json',
  ImportJson = 'marker:import-json',
  GetPermissionStatus = 'marker:get-permission-status',
  GetBookmarkSaveBehavior = 'marker:get-bookmark-save-behavior',
  SetBookmarkSaveBehavior = 'marker:set-bookmark-save-behavior',
  GetAnnotationDisplayMode = 'marker:get-annotation-display-mode',
  SetAnnotationDisplayMode = 'marker:set-annotation-display-mode',
  SettingsChanged = 'marker:settings-changed',
  CreateAnnotation = 'marker:create-annotation',
  GetCurrentPageState = 'marker:get-current-page-state',
  UpdateAnnotationNote = 'marker:update-annotation-note',
  DeleteAnnotation = 'marker:delete-annotation',
  ScrollToAnnotation = 'marker:scroll-to-annotation',
  RemoveRenderedAnnotation = 'marker:remove-rendered-annotation',
  SetAnnotationVisibility = 'marker:set-annotation-visibility',
  ContentRuntimeStatus = 'marker:content-runtime-status',
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

export type LibraryState = {
  pages: PageRecord[];
  folders: BookmarkFolderRecord[];
  bookmarks: BookmarkRecord[];
  annotations: AnnotationWithParts[];
};

export type GetLibraryStateMessage = { type: MarkerMessageType.GetLibraryState };

export type ExportJsonMessage = { type: MarkerMessageType.ExportJson };

export type ImportJsonMessage = { type: MarkerMessageType.ImportJson; data: MarkerExport };

export type GetPermissionStatusMessage = { type: MarkerMessageType.GetPermissionStatus };

export type GetBookmarkSaveBehaviorMessage = { type: MarkerMessageType.GetBookmarkSaveBehavior };

export type SetBookmarkSaveBehaviorMessage = {
  type: MarkerMessageType.SetBookmarkSaveBehavior;
  behavior: BookmarkSaveBehavior;
};

export type GetAnnotationDisplayModeMessage = { type: MarkerMessageType.GetAnnotationDisplayMode };

export type SetAnnotationDisplayModeMessage = {
  type: MarkerMessageType.SetAnnotationDisplayMode;
  mode: AnnotationDisplayMode;
};

export type SettingsChangedMessage = {
  type: MarkerMessageType.SettingsChanged;
  key: 'bookmark-save-behavior' | 'annotation-display-mode';
  value: string;
};

export type CreateAnnotationMessage = {
  type: MarkerMessageType.CreateAnnotation;
  url: string;
  metadata: PageMetadata;
  selector: Selector[];
  motivation: AnnotationMotivation;
  bodies?: Array<{
    type: 'TextualBody' | 'StyleHint';
    format?: 'text/markdown' | 'text/plain' | 'application/json';
    value: string;
  }>;
};

export type CurrentPageState = {
  summary: ActiveTabSummary;
  page?: PageRecord;
  bookmark?: BookmarkRecord;
  annotations: AnnotationWithParts[];
  bookmarkSaveBehavior: BookmarkSaveBehavior;
  annotationDisplayMode: AnnotationDisplayMode;
};

export type GetCurrentPageStateMessage = { type: MarkerMessageType.GetCurrentPageState };

export type UpdateAnnotationNoteMessage = {
  type: MarkerMessageType.UpdateAnnotationNote;
  annotationId: string;
  value: string;
};

export type DeleteAnnotationMessage = { type: MarkerMessageType.DeleteAnnotation; annotationId: string };

export type ScrollToAnnotationMessage = { type: MarkerMessageType.ScrollToAnnotation; annotationId: string };

export type RemoveRenderedAnnotationMessage = {
  type: MarkerMessageType.RemoveRenderedAnnotation;
  annotationId: string;
};

export type SetAnnotationVisibilityMessage = { type: MarkerMessageType.SetAnnotationVisibility; visible: boolean };

export type ContentRuntimeStatusMessage = { type: MarkerMessageType.ContentRuntimeStatus };

export type MarkerMessage =
  | OpenLibraryMessage
  | OpenOptionsMessage
  | GetActiveTabSummaryMessage
  | EnableSiteMessage
  | PageVisitedMessage
  | SaveBookmarkMessage
  | ImportChromeBookmarksMessage
  | GetLibraryStateMessage
  | ExportJsonMessage
  | ImportJsonMessage
  | GetPermissionStatusMessage
  | GetBookmarkSaveBehaviorMessage
  | SetBookmarkSaveBehaviorMessage
  | GetAnnotationDisplayModeMessage
  | SetAnnotationDisplayModeMessage
  | SettingsChangedMessage
  | CreateAnnotationMessage
  | GetCurrentPageStateMessage
  | UpdateAnnotationNoteMessage
  | DeleteAnnotationMessage
  | ScrollToAnnotationMessage
  | RemoveRenderedAnnotationMessage
  | SetAnnotationVisibilityMessage
  | ContentRuntimeStatusMessage;

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
          : T extends GetLibraryStateMessage
            ? LibraryState
            : T extends ExportJsonMessage
              ? MarkerExport
              : T extends ImportJsonMessage
                ? { ok: true } | { ok: false; reason: string }
                : T extends GetPermissionStatusMessage
                  ? { hasChromeBookmarkPermission: boolean; activeTab: ActiveTabSummary }
                  : T extends GetBookmarkSaveBehaviorMessage
                    ? { behavior: BookmarkSaveBehavior }
                    : T extends GetAnnotationDisplayModeMessage
                      ? { mode: AnnotationDisplayMode }
                      : T extends CreateAnnotationMessage
                        ? { ok: true; annotation: AnnotationWithParts } | { ok: false; reason: string }
                        : T extends GetCurrentPageStateMessage
                          ? CurrentPageState
                          : T extends UpdateAnnotationNoteMessage | DeleteAnnotationMessage
                            ? { ok: true } | { ok: false; reason: string }
                            : T extends ScrollToAnnotationMessage
                              ? { ok: true } | { ok: false; reason: string }
                              : T extends ContentRuntimeStatusMessage
                                ? { ok: true }
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
    case MarkerMessageType.ImportJson: {
      return typeof (value as { data?: unknown }).data === 'object' && (value as { data?: unknown }).data !== null;
    }
    case MarkerMessageType.SetBookmarkSaveBehavior: {
      return typeof (value as { behavior?: unknown }).behavior === 'string';
    }
    case MarkerMessageType.SetAnnotationDisplayMode: {
      return typeof (value as { mode?: unknown }).mode === 'string';
    }
    case MarkerMessageType.SettingsChanged: {
      const message = value as { key?: unknown; value?: unknown };
      return typeof message.key === 'string' && typeof message.value === 'string';
    }
    case MarkerMessageType.UpdateAnnotationNote: {
      const message = value as { annotationId?: unknown; value?: unknown };
      return typeof message.annotationId === 'string' && typeof message.value === 'string';
    }
    case MarkerMessageType.DeleteAnnotation:
    case MarkerMessageType.ScrollToAnnotation:
    case MarkerMessageType.RemoveRenderedAnnotation: {
      return typeof (value as { annotationId?: unknown }).annotationId === 'string';
    }
    case MarkerMessageType.SetAnnotationVisibility: {
      return typeof (value as { visible?: unknown }).visible === 'boolean';
    }
    case MarkerMessageType.CreateAnnotation: {
      const message = value as { url?: unknown; metadata?: unknown; selector?: unknown; motivation?: unknown };
      return (
        typeof message.url === 'string' &&
        typeof message.metadata === 'object' &&
        message.metadata !== null &&
        Array.isArray(message.selector) &&
        typeof message.motivation === 'string'
      );
    }
    default: {
      return true;
    }
  }
}
