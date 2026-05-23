export type PageIdentity = { url: string; canonicalUrl?: string; lookupUrls: string[] };

export function resolveUrl(value: string | undefined, baseUrl: string): string | undefined {
  if (value == null || value.trim().length === 0) {
    return undefined;
  }

  try {
    return new URL(value, baseUrl).href;
  } catch {
    return undefined;
  }
}

export function stripHash(url: string): string {
  const parsedUrl = new URL(url);
  parsedUrl.hash = '';
  return parsedUrl.href;
}

export function normalizeLookupUrl(url: string): string | undefined {
  try {
    return stripHash(url);
  } catch {
    return undefined;
  }
}

export function buildPageIdentity(url: string, canonicalUrl?: string): PageIdentity {
  const normalizedUrl = normalizeLookupUrl(url) ?? url;
  const normalizedCanonicalUrl = canonicalUrl == null ? undefined : normalizeLookupUrl(canonicalUrl);
  const lookupUrls = [normalizedUrl, normalizedCanonicalUrl].filter((value): value is string => value != null);

  return { url: normalizedUrl, canonicalUrl: normalizedCanonicalUrl, lookupUrls: [...new Set(lookupUrls)] };
}

export function canonicalUrlsConflict(
  firstCanonicalUrl: string | undefined,
  secondCanonicalUrl: string | undefined,
): boolean {
  if (firstCanonicalUrl == null || secondCanonicalUrl == null) {
    return false;
  }

  return normalizeLookupUrl(firstCanonicalUrl) !== normalizeLookupUrl(secondCanonicalUrl);
}
