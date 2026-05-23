import 'fake-indexeddb/auto';
import { afterEach, describe, expect, it } from 'vitest';
import { SettingsRepository } from './settings-repository';
import { createMarkerDb, type MarkerDb } from './schema';

const databases: MarkerDb[] = [];

function testDb(): MarkerDb {
  const db = createMarkerDb(`marker-settings-test-${crypto.randomUUID()}`);
  databases.push(db);
  return db;
}

afterEach(async () => {
  await Promise.all(
    databases.splice(0).map(async (db) => {
      await db.delete();
    }),
  );
});

describe('SettingsRepository', () => {
  it('defaults to asking before bookmark saves', async () => {
    expect(await new SettingsRepository(testDb()).getBookmarkSaveBehavior()).toBe('always-ask');
  });

  it('persists bookmark save behavior', async () => {
    const settings = new SettingsRepository(testDb());

    await settings.setBookmarkSaveBehavior('both', '2026-05-22T00:00:00.000Z');

    expect(await settings.getBookmarkSaveBehavior()).toBe('both');
  });

  it('persists annotation display mode', async () => {
    const settings = new SettingsRepository(testDb());

    expect(await settings.getAnnotationDisplayMode()).toBe('visible');
    await settings.setAnnotationDisplayMode('hidden', '2026-05-22T00:00:00.000Z');

    expect(await settings.getAnnotationDisplayMode()).toBe('hidden');
  });
});
