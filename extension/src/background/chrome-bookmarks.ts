import type { BookmarkFolderRepository, BookmarkRepository } from '@/db/bookmark-repository';
import type { BookmarkFolderRecord, BookmarkRecord } from '@/db/schema';

export type ChromeBookmarkNode = { children?: ChromeBookmarkNode[]; id: string; title: string; url?: string };

export type ChromeBookmarkCreateDetails = { parentId?: string; title?: string; url?: string };

export type ChromeBookmarksPort = {
  create(bookmark: ChromeBookmarkCreateDetails): Promise<ChromeBookmarkNode>;
  getTree(): Promise<ChromeBookmarkNode[]>;
};

export type CreateChromeBookmarkInput = { parentId?: string; title?: string; url: string };

export type ImportChromeBookmarksResult = { folders: BookmarkFolderRecord[]; bookmarks: BookmarkRecord[] };

export async function createChromeBookmark(
  chromeBookmarks: ChromeBookmarksPort,
  input: CreateChromeBookmarkInput,
): Promise<ChromeBookmarkNode> {
  return chromeBookmarks.create({ parentId: input.parentId, title: input.title ?? input.url, url: input.url });
}

function isImportableChromeFolder(node: ChromeBookmarkNode): boolean {
  return node.url == null && node.title.trim().length > 0;
}

async function importChromeNode(
  node: ChromeBookmarkNode,
  markerParentId: string | undefined,
  sortOrder: number,
  folders: BookmarkFolderRepository,
  bookmarks: BookmarkRepository,
  result: ImportChromeBookmarksResult,
): Promise<void> {
  if (node.url != null) {
    result.bookmarks.push(
      await bookmarks.createBookmark({
        chromeBookmarkId: node.id,
        folderId: markerParentId,
        sortOrder,
        title: node.title,
        url: node.url,
      }),
    );
    return;
  }

  const importedFolder = isImportableChromeFolder(node)
    ? await folders.createFolder({ parentId: markerParentId, sortOrder, title: node.title })
    : undefined;

  if (importedFolder != null) {
    result.folders.push(importedFolder);
  }

  const childParentId = importedFolder?.id ?? markerParentId;
  const children = node.children ?? [];
  await Promise.all(
    children.map((child, childIndex) => importChromeNode(child, childParentId, childIndex, folders, bookmarks, result)),
  );
}

export async function importChromeBookmarks(
  chromeBookmarks: ChromeBookmarksPort,
  folders: BookmarkFolderRepository,
  bookmarks: BookmarkRepository,
  markerParentId?: string,
): Promise<ImportChromeBookmarksResult> {
  const result: ImportChromeBookmarksResult = { folders: [], bookmarks: [] };
  const roots = await chromeBookmarks.getTree();
  await Promise.all(
    roots.map((root, index) => importChromeNode(root, markerParentId, index, folders, bookmarks, result)),
  );
  return result;
}
