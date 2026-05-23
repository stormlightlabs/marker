import { MarkerMessageType, type MarkerMessageResponse } from '@/shared/messages';

export function markerContentRuntimeFiles(): string[] {
  const scripts = chrome.runtime.getManifest().content_scripts ?? [];
  const markerScript = scripts.find((script) => script.js?.some((file) => file.includes('content')));
  return markerScript?.js ?? [];
}

export async function isMarkerContentRuntimeLoaded(tabId: number): Promise<boolean> {
  try {
    const response = (await chrome.tabs.sendMessage(tabId, {
      type: MarkerMessageType.ContentRuntimeStatus,
    })) as MarkerMessageResponse<{ type: MarkerMessageType.ContentRuntimeStatus }>;
    return response?.ok === true;
  } catch (error) {
    console.debug('Marker content runtime is not loaded in the active tab yet.', error);
    return false;
  }
}

export async function injectMarkerContentRuntime(tabId: number): Promise<void> {
  const files = markerContentRuntimeFiles();
  if (files.length === 0) {
    throw new Error('Marker content runtime is not listed in the extension manifest.');
  }
  await chrome.scripting.executeScript({ target: { tabId }, files });
}

export async function ensureMarkerContentRuntime(tabId: number): Promise<void> {
  if (await isMarkerContentRuntimeLoaded(tabId)) {
    return;
  }
  await injectMarkerContentRuntime(tabId);
}
