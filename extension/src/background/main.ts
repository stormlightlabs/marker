import { getActiveTabSummary, getTabSummary } from '@/background/active-tab';
import { injectMarkerContentRuntime } from '@/background/content-injection';
import { isMarkerMessage, MarkerMessageType, type MarkerMessageResponse } from '@/shared/messages';

const sidePanelPath = 'src/pages/sidepanel/index.html';
const libraryPath = 'src/pages/library/index.html';
const optionsPath = 'src/pages/options/index.html';

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

  if (message.type === MarkerMessageType.OpenLibrary) {
    void openExtensionPage(libraryPath);
    return false;
  }

  if (message.type === MarkerMessageType.OpenOptions) {
    void openExtensionPage(optionsPath);
    return false;
  }

  if (message.type === MarkerMessageType.GetActiveTabSummary) {
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

  if (message.type === MarkerMessageType.EnableSite) {
    enableSite(message.tabId)
      .then((response) => sendResponse(response))
      .catch((error: unknown) => {
        console.debug('Marker could not enable the active site.', error);
        sendResponse({ ok: false, reason: 'Marker could not inject the content runtime.' });
      });
    return true;
  }

  return false;
});

void configureSidePanel();
