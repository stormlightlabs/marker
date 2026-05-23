import type { ActiveTabSummary } from './permissions';

export enum MarkerMessageType {
  OpenLibrary = 'marker:open-library',
  OpenOptions = 'marker:open-options',
  GetActiveTabSummary = 'marker:get-active-tab-summary',
  EnableSite = 'marker:enable-site',
}

export type OpenLibraryMessage = { type: MarkerMessageType.OpenLibrary };

export type OpenOptionsMessage = { type: MarkerMessageType.OpenOptions };

export type GetActiveTabSummaryMessage = { type: MarkerMessageType.GetActiveTabSummary };

export type EnableSiteMessage = { type: MarkerMessageType.EnableSite; tabId: number };

export type MarkerMessage = OpenLibraryMessage | OpenOptionsMessage | GetActiveTabSummaryMessage | EnableSiteMessage;

export type EnableSiteResponse = { ok: true } | { ok: false; reason: string };

export type MarkerMessageResponse<T extends MarkerMessage = MarkerMessage> = T extends GetActiveTabSummaryMessage
  ? ActiveTabSummary
  : T extends EnableSiteMessage
    ? EnableSiteResponse
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

  if (type === MarkerMessageType.EnableSite) {
    return typeof (value as { tabId?: unknown }).tabId === 'number';
  }

  return true;
}
