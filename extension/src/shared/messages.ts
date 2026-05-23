export enum MarkerMessageType {
  OpenLibrary = 'marker:open-library',
  OpenOptions = 'marker:open-options',
  GetActiveTabSummary = 'marker:get-active-tab-summary',
}

export type OpenLibraryMessage = { type: MarkerMessageType.OpenLibrary };

export type OpenOptionsMessage = { type: MarkerMessageType.OpenOptions };

export type GetActiveTabSummaryMessage = { type: MarkerMessageType.GetActiveTabSummary };

export type MarkerMessage = OpenLibraryMessage | OpenOptionsMessage | GetActiveTabSummaryMessage;

const markerMessageTypeValues = new Set<string>(Object.values(MarkerMessageType));

export function isMarkerMessage(value: unknown): value is MarkerMessage {
  if (typeof value !== 'object' || value === null || !('type' in value)) {
    return false;
  }

  const type = (value as { type: unknown }).type;
  return typeof type === 'string' && markerMessageTypeValues.has(type);
}
