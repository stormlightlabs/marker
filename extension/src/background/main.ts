import { isMarkerMessage, MarkerMessageType } from '@/shared/messages';

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

chrome.runtime.onInstalled.addListener(() => {
  void configureSidePanel();
});

chrome.runtime.onStartup.addListener(() => {
  void configureSidePanel();
});

chrome.action.onClicked.addListener((tab) => {
  void openSidePanel(tab);
});

chrome.runtime.onMessage.addListener((message: unknown) => {
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

  return false;
});

void configureSidePanel();
