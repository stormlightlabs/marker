import { nowIso } from './id';
import type { MarkerDb } from './schema';

export const bookmarkSaveBehaviors = ['always-ask', 'marker-only', 'chrome-only', 'both'] as const;

export type BookmarkSaveBehavior = (typeof bookmarkSaveBehaviors)[number];

const bookmarkSaveBehaviorKey = 'bookmark-save-behavior';
const defaultBookmarkSaveBehavior: BookmarkSaveBehavior = 'always-ask';

function isBookmarkSaveBehavior(value: string): value is BookmarkSaveBehavior {
  return bookmarkSaveBehaviors.includes(value as BookmarkSaveBehavior);
}

export class SettingsRepository {
  constructor(private readonly db: MarkerDb) {}

  async getBookmarkSaveBehavior(): Promise<BookmarkSaveBehavior> {
    const setting = await this.db.appSettings.get(bookmarkSaveBehaviorKey);
    return setting != null && isBookmarkSaveBehavior(setting.value) ? setting.value : defaultBookmarkSaveBehavior;
  }

  async setBookmarkSaveBehavior(value: BookmarkSaveBehavior, now = nowIso()): Promise<void> {
    await this.db.appSettings.put({ key: bookmarkSaveBehaviorKey, value, updatedAt: now });
  }
}
