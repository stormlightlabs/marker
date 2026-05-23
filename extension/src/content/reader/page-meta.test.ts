// @vitest-environment happy-dom
import { beforeEach, describe, expect, it } from 'vitest';
import { extractPageMetadata, parseJsonLd } from './page-meta';

function loadHtml(html: string): void {
  document.documentElement.innerHTML = html;
}

beforeEach(() => {
  loadHtml('<head><title></title></head><body></body>');
});

describe('extractPageMetadata', () => {
  it('extracts canonical links, standard meta tags, Open Graph, Twitter fallbacks, and favicons', () => {
    loadHtml(`
      <head>
        <title>Document title</title>
        <link rel="canonical" href="/canonical" />
        <link rel="icon" href="/icon.png" />
        <meta name="description" content="Standard description" />
        <meta name="author" content="Ada" />
        <meta property="og:title" content="OG title" />
        <meta property="og:description" content="OG description" />
        <meta property="og:site_name" content="Example Site" />
        <meta property="og:type" content="article" />
        <meta property="og:image" content="/og.png" />
        <meta property="article:published_time" content="2026-05-20" />
        <meta property="article:modified_time" content="2026-05-21" />
        <meta name="twitter:title" content="Twitter title" />
      </head>
    `);

    expect(extractPageMetadata(document, 'https://example.com/path/page')).toMatchObject({
      canonicalUrl: 'https://example.com/canonical',
      title: 'OG title',
      description: 'Standard description',
      siteName: 'Example Site',
      author: 'Ada',
      publishedAt: '2026-05-20',
      modifiedAt: '2026-05-21',
      imageUrl: 'https://example.com/og.png',
      faviconUrl: 'https://example.com/icon.png',
      type: 'article',
    });
  });

  it('uses Twitter and document title fallbacks when stronger metadata is absent', () => {
    loadHtml(`
      <head>
        <title>Document title</title>
        <meta name="twitter:description" content="Twitter description" />
        <meta name="twitter:image" content="relative-twitter.png" />
      </head>
    `);

    expect(extractPageMetadata(document, 'https://example.com/articles/page')).toMatchObject({
      title: 'Document title',
      description: 'Twitter description',
      imageUrl: 'https://example.com/articles/relative-twitter.png',
      faviconUrl: 'https://example.com/favicon.ico',
    });
  });

  it('extracts article-like JSON-LD from arrays and graph nodes', () => {
    loadHtml(`
      <head>
        <script type="application/ld+json">
          [
            {"@type":"BreadcrumbList","name":"Breadcrumbs"},
            {"@graph":[
              {"@type":"Person","name":"Ignored"},
              {
                "@type":"NewsArticle",
                "headline":"JSON-LD headline",
                "description":"JSON-LD description",
                "author":{"name":"Grace"},
                "publisher":{"name":"Daily Example"},
                "datePublished":"2026-05-19",
                "dateModified":"2026-05-20",
                "image":{"url":"/jsonld.png"}
              }
            ]}
          ]
        </script>
      </head>
    `);

    const metadata = extractPageMetadata(document, 'https://example.com/post');

    expect(metadata).toMatchObject({
      title: 'JSON-LD headline',
      description: 'JSON-LD description',
      author: 'Grace',
      siteName: 'Daily Example',
      publishedAt: '2026-05-19',
      modifiedAt: '2026-05-20',
      imageUrl: 'https://example.com/jsonld.png',
      type: 'NewsArticle',
    });
    expect(metadata.jsonLd).toHaveLength(4);
  });

  it('ignores malformed JSON-LD scripts without failing metadata extraction', () => {
    loadHtml(`
      <head>
        <title>Still works</title>
        <script type="application/ld+json">{bad json</script>
      </head>
    `);

    const metadata = extractPageMetadata(document, 'https://example.com/post');

    expect(metadata.title).toBe('Still works');
    expect(metadata.jsonLd).toEqual([]);
  });
});

describe('parseJsonLd', () => {
  it('returns flattened nodes for arrays and @graph containers', () => {
    loadHtml(`
      <head>
        <script type="application/ld+json">
          {"@graph":[{"@type":"WebPage","name":"Page"},{"@type":"Article","name":"Article"}]}
        </script>
      </head>
    `);

    expect(parseJsonLd(document).map((node) => node['@type'])).toEqual([undefined, 'WebPage', 'Article']);
  });
});
