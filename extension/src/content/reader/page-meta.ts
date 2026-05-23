import type { PageMetadata } from '@/db/schema';
import { resolveUrl } from '@/shared/urls';

const articleJsonLdTypes = new Set(['Article', 'NewsArticle', 'BlogPosting', 'ScholarlyArticle', 'WebPage']);

type JsonLdNode = Record<string, unknown>;

type MetadataDocument = Pick<Document, 'title' | 'querySelector' | 'querySelectorAll'>;

function attribute(element: Element | null, name: string): string | undefined {
  const value = element?.getAttribute(name)?.trim();
  return value == null || value.length === 0 ? undefined : value;
}

function metaContent(document: MetadataDocument, selector: string): string | undefined {
  return attribute(document.querySelector(selector), 'content');
}

function firstValue(...values: Array<string | undefined>): string | undefined {
  return values.find((value) => value != null && value.length > 0);
}

function normalizeJsonLdType(value: unknown): string[] {
  if (typeof value === 'string') {
    return [value];
  }

  return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : [];
}

function isJsonObject(value: unknown): value is JsonLdNode {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function flattenJsonLd(value: unknown): JsonLdNode[] {
  if (Array.isArray(value)) {
    return value.flatMap((item) => flattenJsonLd(item));
  }

  if (!isJsonObject(value)) {
    return [];
  }

  const graph = value['@graph'];
  return Array.isArray(graph) ? [value, ...graph.flatMap((node) => flattenJsonLd(node))] : [value];
}

export function parseJsonLd(document: MetadataDocument): JsonLdNode[] {
  const scripts = [...document.querySelectorAll('script[type="application/ld+json"]')];
  return scripts.flatMap((script) => {
    try {
      return flattenJsonLd(JSON.parse(script.textContent ?? ''));
    } catch (error) {
      console.debug('Marker ignored invalid JSON-LD metadata.', error);
      return [];
    }
  });
}

function jsonLdString(value: unknown): string | undefined {
  if (typeof value === 'string') {
    return value;
  }

  if (isJsonObject(value)) {
    const nestedValue = value.name ?? value.url ?? value['@id'];
    return typeof nestedValue === 'string' ? nestedValue : undefined;
  }

  return undefined;
}

function jsonLdDate(value: unknown): string | undefined {
  return typeof value === 'string' ? value : undefined;
}

function jsonLdImage(value: unknown, baseUrl: string): string | undefined {
  if (typeof value === 'string') {
    return resolveUrl(value, baseUrl);
  }

  if (Array.isArray(value)) {
    return value.map((item) => jsonLdImage(item, baseUrl)).find((item) => item != null);
  }

  if (isJsonObject(value)) {
    return jsonLdImage(value.url ?? value.contentUrl, baseUrl);
  }

  return undefined;
}

function preferredJsonLdNode(nodes: JsonLdNode[]): JsonLdNode | undefined {
  return nodes.find((node) => normalizeJsonLdType(node['@type']).some((type) => articleJsonLdTypes.has(type)));
}

function faviconUrl(document: MetadataDocument, pageUrl: string): string | undefined {
  const icon = document.querySelector(
    'link[rel~="icon"][href], link[rel="shortcut icon"][href], link[rel="apple-touch-icon"][href]',
  );
  return resolveUrl(attribute(icon, 'href'), pageUrl) ?? resolveUrl('/favicon.ico', pageUrl);
}

export function extractPageMetadata(document: MetadataDocument, pageUrl: string): PageMetadata {
  const canonicalUrl = resolveUrl(attribute(document.querySelector('link[rel="canonical"][href]'), 'href'), pageUrl);
  const jsonLd = parseJsonLd(document);
  const jsonLdNode = preferredJsonLdNode(jsonLd);
  const title = firstValue(
    metaContent(document, 'meta[property="og:title"]'),
    metaContent(document, 'meta[name="twitter:title"]'),
    jsonLdString(jsonLdNode?.headline),
    jsonLdString(jsonLdNode?.name),
    document.title.trim(),
  );
  const description = firstValue(
    metaContent(document, 'meta[name="description"]'),
    metaContent(document, 'meta[property="og:description"]'),
    metaContent(document, 'meta[name="twitter:description"]'),
    jsonLdString(jsonLdNode?.description),
  );
  const imageUrl = firstValue(
    resolveUrl(metaContent(document, 'meta[property="og:image"]'), pageUrl),
    resolveUrl(metaContent(document, 'meta[name="twitter:image"]'), pageUrl),
    jsonLdImage(jsonLdNode?.image, pageUrl),
  );

  return {
    canonicalUrl,
    title,
    description,
    siteName: firstValue(metaContent(document, 'meta[property="og:site_name"]'), jsonLdString(jsonLdNode?.publisher)),
    author: firstValue(metaContent(document, 'meta[name="author"]'), jsonLdString(jsonLdNode?.author)),
    publishedAt: firstValue(
      metaContent(document, 'meta[property="article:published_time"]'),
      jsonLdDate(jsonLdNode?.datePublished),
    ),
    modifiedAt: firstValue(
      metaContent(document, 'meta[property="article:modified_time"]'),
      jsonLdDate(jsonLdNode?.dateModified),
    ),
    imageUrl,
    faviconUrl: faviconUrl(document, pageUrl),
    type: firstValue(metaContent(document, 'meta[property="og:type"]'), normalizeJsonLdType(jsonLdNode?.['@type'])[0]),
    jsonLd,
  };
}

export function currentPageMetadata(): PageMetadata {
  return extractPageMetadata(document, window.location.href);
}
