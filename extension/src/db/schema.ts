import Dexie, { type EntityTable } from 'dexie';

export type PageMetadata = {
  canonicalUrl?: string;
  title?: string;
  description?: string;
  siteName?: string;
  author?: string;
  publishedAt?: string;
  modifiedAt?: string;
  imageUrl?: string;
  faviconUrl?: string;
  type?: string;
  jsonLd: Array<Record<string, unknown>>;
};

export type PageRecord = {
  id: string;
  url: string;
  canonicalUrl?: string;
  title?: string;
  description?: string;
  faviconUrl?: string;
  metadata?: PageMetadata;
  createdAt: string;
  lastVisitedAt: string;
  deletedAt?: string;
};

export type BookmarkFolderRecord = {
  id: string;
  parentId?: string;
  title: string;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
};

export type BookmarkRecord = {
  id: string;
  folderId?: string;
  pageId?: string;
  chromeBookmarkId?: string;
  url: string;
  title?: string;
  description?: string;
  tags: string[];
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
};

export type AnnotationMotivation = 'highlighting' | 'commenting' | 'tagging' | 'linking';

export type Selector =
  | { type: 'TextQuoteSelector'; exact: string; prefix?: string; suffix?: string }
  | { type: 'TextPositionSelector'; start: number; end: number }
  | { type: 'CssSelector'; value: string };

export type AnnotationRecord = {
  id: string;
  pageId: string;
  motivation: AnnotationMotivation;
  createdAt: string;
  modifiedAt: string;
  deletedAt?: string;
};

export type AnnotationTargetRecord = { id: string; annotationId: string; sourceUrl: string; selector: Selector[] };

export type AnnotationBodyRecord = {
  id: string;
  annotationId: string;
  type: 'TextualBody' | 'StyleHint';
  format?: 'text/markdown' | 'text/plain' | 'application/json';
  value: string;
};

export class MarkerDb extends Dexie {
  pages!: EntityTable<PageRecord, 'id'>;
  bookmarkFolders!: EntityTable<BookmarkFolderRecord, 'id'>;
  bookmarks!: EntityTable<BookmarkRecord, 'id'>;
  annotations!: EntityTable<AnnotationRecord, 'id'>;
  annotationTargets!: EntityTable<AnnotationTargetRecord, 'id'>;
  annotationBodies!: EntityTable<AnnotationBodyRecord, 'id'>;

  constructor(databaseName = 'marker-extension') {
    super(databaseName);
    this.version(1).stores({
      pages: 'id, &url, canonicalUrl, lastVisitedAt, deletedAt',
      bookmarkFolders: 'id, parentId, sortOrder, deletedAt, updatedAt',
      bookmarks: 'id, folderId, pageId, chromeBookmarkId, url, sortOrder, deletedAt, updatedAt, *tags',
      annotations: 'id, pageId, motivation, deletedAt, modifiedAt',
      annotationTargets: 'id, annotationId, sourceUrl',
      annotationBodies: 'id, annotationId, type, format',
    });
  }
}

export function createMarkerDb(databaseName?: string): MarkerDb {
  return new MarkerDb(databaseName);
}
