import { nowIso } from './id';
import type { MarkerDb } from './schema';

export const bookmarkSaveBehaviors = ['always-ask', 'marker-only', 'chrome-only', 'both'] as const;
export const annotationDisplayModes = ['visible', 'hidden'] as const;

export type BookmarkSaveBehavior = (typeof bookmarkSaveBehaviors)[number];
export type AnnotationDisplayMode = (typeof annotationDisplayModes)[number];

const bookmarkSaveBehaviorKey = 'bookmark-save-behavior';
const annotationDisplayModeKey = 'annotation-display-mode';
const defaultBookmarkSaveBehavior: BookmarkSaveBehavior = 'always-ask';
const defaultAnnotationDisplayMode: AnnotationDisplayMode = 'visible';

function isBookmarkSaveBehavior(value: string): value is BookmarkSaveBehavior {
  return bookmarkSaveBehaviors.includes(value as BookmarkSaveBehavior);
}

function isAnnotationDisplayMode(value: string): value is AnnotationDisplayMode {
  return annotationDisplayModes.includes(value as AnnotationDisplayMode);
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

  async getAnnotationDisplayMode(): Promise<AnnotationDisplayMode> {
    const setting = await this.db.appSettings.get(annotationDisplayModeKey);
    return setting != null && isAnnotationDisplayMode(setting.value) ? setting.value : defaultAnnotationDisplayMode;
  }

  async setAnnotationDisplayMode(value: AnnotationDisplayMode, now = nowIso()): Promise<void> {
    await this.db.appSettings.put({ key: annotationDisplayModeKey, value, updatedAt: now });
  }
}
