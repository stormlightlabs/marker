import { getActiveTabSummary, getTabSummary } from '@/background/active-tab';
import { BookmarkSaveService } from '@/background/bookmark-save-service';
import { importChromeBookmarks } from '@/background/chrome-bookmarks';
import { injectMarkerContentRuntime } from '@/background/content-injection';
import { BookmarkFolderRepository, BookmarkRepository } from '@/db/bookmark-repository';
import { AnnotationRepository } from '@/db/annotation-repository';
import { PageRepository } from '@/db/page-repository';
import { createMarkerDb } from '@/db/schema';
import { SettingsRepository } from '@/db/settings-repository';
import { isMarkerMessage, MarkerMessageType, type MarkerMessageResponse } from '@/shared/messages';

const sidePanelPath = 'src/pages/sidepanel/index.html';
const libraryPath = 'src/pages/library/index.html';
const optionsPath = 'src/pages/options/index.html';

const db = createMarkerDb();
const pages = new PageRepository(db);
const bookmarkFolders = new BookmarkFolderRepository(db);
const bookmarks = new BookmarkRepository(db);
const annotations = new AnnotationRepository(db);
const settings = new SettingsRepository(db);
const bookmarkSaveService = new BookmarkSaveService(bookmarks, chrome.bookmarks);

async function configureSidePanel(): Promise<void> {
  try {
    await chrome.sidePanel.setOptions({ path: sidePanelPath, enabled: true });
    await chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true });
  } catch (error) {
    console.debug('Marker could not configure the side panel.', error);
  }
}

async function openSidePanel(tab?: chrome.tabs.Tab): Promise<void> {
  try {
    if (tab?.id != null) {
      await chrome.sidePanel.open({ tabId: tab.id });
      return;
    }

    if (tab?.windowId != null) {
      await chrome.sidePanel.open({ windowId: tab.windowId });
    }
  } catch (error) {
    console.debug('Marker could not open the side panel.', error);
  }
}

async function openExtensionPage(path: string): Promise<void> {
  await chrome.tabs.create({ url: chrome.runtime.getURL(path) });
}

async function hasChromeBookmarkPermission(): Promise<boolean> {
  return chrome.permissions.contains({ permissions: ['bookmarks'] });
}

async function enableSite(
  tabId: number,
): Promise<MarkerMessageResponse<{ type: MarkerMessageType.EnableSite; tabId: number }>> {
  const summary = await getTabSummary(tabId);

  if (!summary.canAnnotate) {
    return { ok: false, reason: summary.reason ?? 'Marker does not have permission to annotate this page.' };
  }

  await injectMarkerContentRuntime(tabId);
  return { ok: true };
}

chrome.runtime.onInstalled.addListener(() => {
  void configureSidePanel();
});

chrome.runtime.onStartup.addListener(() => {
  void configureSidePanel();
});

chrome.action.onClicked.addListener((tab) => {
  void openSidePanel(tab);
});

chrome.runtime.onMessage.addListener((message: unknown, _sender, sendResponse) => {
  if (!isMarkerMessage(message)) {
    return false;
  }

  switch (message.type) {
    case MarkerMessageType.OpenLibrary: {
      void openExtensionPage(libraryPath);
      return false;
    }

    case MarkerMessageType.OpenOptions: {
      void openExtensionPage(optionsPath);
      return false;
    }

    case MarkerMessageType.GetActiveTabSummary: {
      getActiveTabSummary()
        .then((summary) => sendResponse(summary))
        .catch((error: unknown) => {
          console.debug('Marker could not summarize the active tab.', error);
          sendResponse({
            canAnnotate: false,
            hasHostPermission: false,
            hasScriptingPermission: false,
            status: 'unsupported',
            reason: 'Marker could not read the active tab.',
          });
        });
      return true;
    }

    case MarkerMessageType.EnableSite: {
      enableSite(message.tabId)
        .then((response) => sendResponse(response))
        .catch((error: unknown) => {
          console.debug('Marker could not enable the active site.', error);
          sendResponse({ ok: false, reason: 'Marker could not inject the content runtime.' });
        });
      return true;
    }

    case MarkerMessageType.CreateAnnotation: {
      pages
        .recordPageVisit({
          url: message.url,
          canonicalUrl: message.metadata.canonicalUrl,
          title: message.metadata.title,
          description: message.metadata.description,
          faviconUrl: message.metadata.faviconUrl,
          metadata: message.metadata,
        })
        .then((page) =>
          annotations.createAnnotation({
            pageId: page.id,
            sourceUrl: message.url,
            selector: message.selector,
            motivation: message.motivation,
            bodies: message.bodies,
          }),
        )
        .then((annotation) => sendResponse({ ok: true, annotation }))
        .catch((error: unknown) => {
          console.debug('Marker could not create annotation.', error);
          sendResponse({ ok: false, reason: 'Marker could not save this annotation.' });
        });
      return true;
    }

    case MarkerMessageType.PageVisited: {
      pages
        .recordPageVisit({
          url: message.url,
          canonicalUrl: message.metadata.canonicalUrl,
          title: message.metadata.title,
          description: message.metadata.description,
          faviconUrl: message.metadata.faviconUrl,
          metadata: message.metadata,
        })
        .then(async (page) => ({ pageId: page.id, annotations: await annotations.listAnnotationsForPage(page.id) }))
        .then((response) => sendResponse(response))
        .catch((error: unknown) => {
          console.debug('Marker could not record page metadata.', error);
          sendResponse({ pageId: '', annotations: [] });
        });
      return true;
    }

    case MarkerMessageType.SaveBookmark: {
      hasChromeBookmarkPermission()
        .then((hasChromePermission) =>
          bookmarkSaveService.saveBookmark({
            chromeParentId: message.chromeParentId,
            destination: message.destination,
            folderId: message.folderId,
            hasChromePermission,
            title: message.title,
            url: message.url,
          }),
        )
        .then((response) => sendResponse(response))
        .catch((error: unknown) => {
          console.debug('Marker could not save bookmark.', error);
          sendResponse({ ok: false, reason: 'Marker could not save this bookmark.' });
        });
      return true;
    }

    case MarkerMessageType.ImportChromeBookmarks: {
      hasChromeBookmarkPermission()
        .then(async (hasChromePermission) => {
          if (!hasChromePermission) {
            return { ok: false, reason: 'Chrome bookmark permission was not granted.' };
          }

          return importChromeBookmarks(chrome.bookmarks, bookmarkFolders, bookmarks, message.folderId);
        })
        .then((response) => sendResponse(response))
        .catch((error: unknown) => {
          console.debug('Marker could not import Chrome bookmarks.', error);
          sendResponse({ ok: false, reason: 'Marker could not import Chrome bookmarks.' });
        });
      return true;
    }

    case MarkerMessageType.GetBookmarkSaveBehavior: {
      settings
        .getBookmarkSaveBehavior()
        .then((behavior) => sendResponse({ behavior }))
        .catch((error: unknown) => {
          console.debug('Marker could not load bookmark settings.', error);
          sendResponse({ behavior: 'always-ask' });
        });
      return true;
    }

    case MarkerMessageType.SetBookmarkSaveBehavior: {
      settings
        .setBookmarkSaveBehavior(message.behavior)
        .then(() => sendResponse())
        .catch((error: unknown) => {
          console.debug('Marker could not save bookmark settings.', error);
          sendResponse();
        });
      return true;
    }

    case MarkerMessageType.GetAppTheme: {
      settings
        .getAppTheme()
        .then((theme) => sendResponse({ theme }))
        .catch((error: unknown) => {
          console.debug('Marker could not load theme settings.', error);
          sendResponse({ theme: 'minimal-light' });
        });
      return true;
    }

    case MarkerMessageType.SetAppTheme: {
      settings
        .setAppTheme(message.theme)
        .then(() => sendResponse())
        .catch((error: unknown) => {
          console.debug('Marker could not save theme settings.', error);
          sendResponse();
        });
      return true;
    }
  }
});

void configureSidePanel();
