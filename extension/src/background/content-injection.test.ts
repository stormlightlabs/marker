import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  ensureMarkerContentRuntime,
  injectMarkerContentRuntime,
  isMarkerContentRuntimeLoaded,
  markerContentRuntimeFiles,
} from './content-injection';

const originalChrome = globalThis.chrome;

afterEach(() => {
  globalThis.chrome = originalChrome;
  vi.restoreAllMocks();
});

describe('content injection', () => {
  it('uses the content script path rewritten into the runtime manifest', async () => {
    const executeScript = vi.fn().mockResolvedValue([]);
    globalThis.chrome = {
      runtime: {
        getManifest: () => ({ content_scripts: [{ matches: ['https://*/*'], js: ['assets/content-main.js'] }] }),
      },
      scripting: { executeScript },
      tabs: { sendMessage: vi.fn() },
    } as unknown as typeof chrome;

    expect(markerContentRuntimeFiles()).toEqual(['assets/content-main.js']);
    await injectMarkerContentRuntime(7);

    expect(executeScript).toHaveBeenCalledWith({ target: { tabId: 7 }, files: ['assets/content-main.js'] });
  });

  it('throws when the manifest does not include the content runtime', async () => {
    globalThis.chrome = {
      runtime: { getManifest: () => ({ content_scripts: [] }) },
      scripting: { executeScript: vi.fn() },
      tabs: { sendMessage: vi.fn() },
    } as unknown as typeof chrome;

    await expect(injectMarkerContentRuntime(7)).rejects.toThrow('content runtime');
  });

  it('detects an already-loaded content runtime', async () => {
    const sendMessage = vi.fn().mockResolvedValue({ ok: true });
    globalThis.chrome = {
      runtime: { getManifest: () => ({ content_scripts: [] }) },
      scripting: { executeScript: vi.fn() },
      tabs: { sendMessage },
    } as unknown as typeof chrome;

    await expect(isMarkerContentRuntimeLoaded(7)).resolves.toBe(true);
    expect(sendMessage).toHaveBeenCalledWith(7, { type: 'marker:content-runtime-status' });
  });

  it('injects only when the content runtime ping fails', async () => {
    const executeScript = vi.fn().mockResolvedValue([]);
    globalThis.chrome = {
      runtime: {
        getManifest: () => ({ content_scripts: [{ matches: ['https://*/*'], js: ['assets/content-main.js'] }] }),
      },
      scripting: { executeScript },
      tabs: { sendMessage: vi.fn().mockRejectedValue(new Error('No receiver')) },
    } as unknown as typeof chrome;

    await ensureMarkerContentRuntime(7);

    expect(executeScript).toHaveBeenCalledWith({ target: { tabId: 7 }, files: ['assets/content-main.js'] });
  });

  it('skips injection when the content runtime is already loaded', async () => {
    const executeScript = vi.fn().mockResolvedValue([]);
    globalThis.chrome = {
      runtime: {
        getManifest: () => ({ content_scripts: [{ matches: ['https://*/*'], js: ['assets/content-main.js'] }] }),
      },
      scripting: { executeScript },
      tabs: { sendMessage: vi.fn().mockResolvedValue({ ok: true }) },
    } as unknown as typeof chrome;

    await ensureMarkerContentRuntime(7);

    expect(executeScript).not.toHaveBeenCalled();
  });
});
