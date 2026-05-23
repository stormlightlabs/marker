import { describe, expect, it } from 'vitest';
import { isMarkerMessage, MarkerMessageType } from './messages';

describe('isMarkerMessage', () => {
  it('accepts known Marker messages', () => {
    expect(isMarkerMessage({ type: MarkerMessageType.OpenLibrary })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.EnableSite, tabId: 7 })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.SetAppTheme, theme: 'retro' })).toBe(true);
    expect(
      isMarkerMessage({
        type: MarkerMessageType.CreateAnnotation,
        url: 'https://example.com',
        metadata: { jsonLd: [] },
        motivation: 'highlighting',
        selector: [{ type: 'TextQuoteSelector', exact: 'text' }],
      }),
    ).toBe(true);
  });

  it('rejects unknown values', () => {
    expect(isMarkerMessage(null)).toBe(false);
    expect(isMarkerMessage({})).toBe(false);
    expect(isMarkerMessage({ type: 'other' })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.EnableSite })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.CreateAnnotation, url: 'https://example.com' })).toBe(false);
  });
});
