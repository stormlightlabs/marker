import { createId, nowIso } from './id';
import type { MarkerDb, PageMetadata, PageRecord } from './schema';

export type RecordPageVisitInput = {
  url: string;
  canonicalUrl?: string;
  title?: string;
  description?: string;
  faviconUrl?: string;
  metadata?: PageMetadata;
  visitedAt?: string;
};

export class PageRepository {
  constructor(private readonly db: MarkerDb) {}

  async recordPageVisit(input: RecordPageVisitInput): Promise<PageRecord> {
    const visitedAt = input.visitedAt ?? nowIso();
    const existing = await this.findByUrl(input.url, input.canonicalUrl);
    const record: PageRecord = {
      id: existing?.id ?? createId('page'),
      url: existing?.url ?? input.url,
      canonicalUrl: input.canonicalUrl ?? existing?.canonicalUrl,
      title: input.title ?? existing?.title,
      description: input.description ?? existing?.description,
      faviconUrl: input.faviconUrl ?? existing?.faviconUrl,
      metadata: input.metadata ?? existing?.metadata,
      createdAt: existing?.createdAt ?? visitedAt,
      lastVisitedAt: visitedAt,
      deletedAt: existing?.deletedAt,
    };

    await this.db.pages.put(record);
    return record;
  }

  async findById(id: string): Promise<PageRecord | undefined> {
    return this.db.pages.get(id);
  }

  async findByUrl(url: string, canonicalUrl?: string): Promise<PageRecord | undefined> {
    const byUrl = await this.db.pages.where('url').equals(url).first();
    if (byUrl != null) {
      return byUrl;
    }

    return canonicalUrl == null ? undefined : this.db.pages.where('canonicalUrl').equals(canonicalUrl).first();
  }

  async listPages(): Promise<PageRecord[]> {
    const pages = await this.db.pages
      .orderBy('lastVisitedAt')
      .filter((page) => page.deletedAt == null)
      .toArray();
    const reversedPages: PageRecord[] = [];
    for (const page of pages) {
      reversedPages.unshift(page);
    }
    return reversedPages;
  }
}
