export function markerContentRuntimeBootstrap(): void {
  const markerWindow = window as Window & { __markerContentRuntimeLoaded?: boolean };
  markerWindow.__markerContentRuntimeLoaded = true;
  console.debug('Marker content runtime loaded.');
}

export async function injectMarkerContentRuntime(tabId: number): Promise<void> {
  await chrome.scripting.executeScript({ target: { tabId }, func: markerContentRuntimeBootstrap });
}
