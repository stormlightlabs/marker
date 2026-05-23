import { describe, expect, it } from 'vitest';
import { isMarkerMessage, MarkerMessageType } from './messages';

describe('isMarkerMessage', () => {
  it('accepts known Marker messages', () => {
    expect(isMarkerMessage({ type: MarkerMessageType.OpenLibrary })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.EnableSite, tabId: 7 })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.GetAnnotationDisplayMode })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.SetAnnotationDisplayMode, mode: 'hidden' })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.DeleteAnnotation, annotationId: 'annotation_1' })).toBe(true);
    expect(
      isMarkerMessage({ type: MarkerMessageType.UpdateAnnotationNote, annotationId: 'annotation_1', value: 'note' }),
    ).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.SetAnnotationVisibility, visible: false })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.ContentRuntimeStatus })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.GetLibraryState })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.ExportJson })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.ImportJson, data: { version: 1 } })).toBe(true);
    expect(isMarkerMessage({ type: MarkerMessageType.GetPermissionStatus })).toBe(true);
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
    expect(isMarkerMessage({ type: MarkerMessageType.SetAnnotationDisplayMode })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.SettingsChanged, key: 'annotation-display-mode' })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.DeleteAnnotation })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.UpdateAnnotationNote, annotationId: 'annotation_1' })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.SetAnnotationVisibility, visible: 'yes' })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.ImportJson })).toBe(false);
    expect(isMarkerMessage({ type: MarkerMessageType.CreateAnnotation, url: 'https://example.com' })).toBe(false);
  });
});
