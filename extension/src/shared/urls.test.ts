import { describe, expect, it } from 'vitest';
import { buildPageIdentity, canonicalUrlsConflict, resolveUrl } from './urls';

describe('resolveUrl', () => {
  it('resolves relative URLs against a page URL', () => {
    expect(resolveUrl('/image.png', 'https://example.com/articles/page')).toBe('https://example.com/image.png');
  });

  it('rejects empty and invalid URLs', () => {
    expect(resolveUrl('', 'https://example.com')).toBeUndefined();
    expect(resolveUrl('https://[bad]', 'https://example.com')).toBeUndefined();
  });
});

describe('buildPageIdentity', () => {
  it('strips hash fragments but keeps query parameters for loaded and canonical URLs', () => {
    expect(buildPageIdentity('https://example.com/a?b=1#section', 'https://example.com/canonical?x=1#top')).toEqual({
      url: 'https://example.com/a?b=1',
      canonicalUrl: 'https://example.com/canonical?x=1',
      lookupUrls: ['https://example.com/a?b=1', 'https://example.com/canonical?x=1'],
    });
  });

  it('deduplicates equivalent loaded and canonical lookup URLs', () => {
    expect(buildPageIdentity('https://example.com/a#section', 'https://example.com/a')).toMatchObject({
      lookupUrls: ['https://example.com/a'],
    });
  });
});

describe('canonicalUrlsConflict', () => {
  it('detects conflicting canonical URLs while ignoring hash-only differences', () => {
    expect(canonicalUrlsConflict('https://example.com/a#one', 'https://example.com/a#two')).toBe(false);
    expect(canonicalUrlsConflict('https://example.com/a', 'https://example.com/b')).toBe(true);
  });
});
