import { describe, expect, it } from 'vitest';
import { buildActiveTabSummary, getOrigin, getOriginPattern } from './permissions';

describe('permission URL helpers', () => {
  it('builds current-origin host permission patterns for http and https pages', () => {
    expect(getOrigin('https://example.com/path?x=1')).toBe('https://example.com');
    expect(getOriginPattern('https://example.com/path?x=1')).toBe('https://example.com/*');
    expect(getOriginPattern('http://localhost:3000/a')).toBe('http://localhost:3000/*');
  });

  it('rejects browser-internal and invalid URLs', () => {
    expect(getOriginPattern('chrome://extensions')).toBeUndefined();
    expect(getOriginPattern('not a url')).toBeUndefined();
  });
});

describe('buildActiveTabSummary', () => {
  it('marks annotatable pages as needing permission until host and scripting access are granted', () => {
    expect(
      buildActiveTabSummary(
        { id: 7, title: 'Example', url: 'https://example.com/article' },
        { hasHostPermission: true, hasScriptingPermission: false },
      ),
    ).toMatchObject({
      tabId: 7,
      origin: 'https://example.com',
      originPattern: 'https://example.com/*',
      canAnnotate: false,
      status: 'needs-permission',
    });
  });

  it('marks pages as enabled when host and scripting access are granted', () => {
    expect(
      buildActiveTabSummary(
        { id: 7, title: 'Example', url: 'https://example.com/article' },
        { hasHostPermission: true, hasScriptingPermission: true },
      ),
    ).toMatchObject({ canAnnotate: true, status: 'enabled' });
  });

  it('marks unsupported pages with a clear reason', () => {
    expect(
      buildActiveTabSummary(
        { id: 7, title: 'Extensions', url: 'chrome://extensions' },
        { hasHostPermission: true, hasScriptingPermission: true },
      ),
    ).toMatchObject({ canAnnotate: false, status: 'unsupported' });
  });
});
