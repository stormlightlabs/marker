// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { installAnnotationToolbar } from './toolbar';

function selectText(text: Text, start: number, end: number): void {
  const range = document.createRange();
  range.setStart(text, start);
  range.setEnd(text, end);
  range.getBoundingClientRect = () => ({
    left: 20,
    top: 80,
    right: 120,
    bottom: 100,
    width: 100,
    height: 20,
    x: 20,
    y: 80,
    toJSON: () => ({}),
  });
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}

beforeEach(() => {
  document.body.innerHTML = '<p>Alpha beta gamma</p>';
  vi.stubGlobal('chrome', {
    runtime: {
      sendMessage: vi
        .fn()
        .mockResolvedValue({
          ok: true,
          annotation: {
            annotation: {
              id: 'annotation_1',
              pageId: 'page_1',
              motivation: 'highlighting',
              createdAt: 'now',
              modifiedAt: 'now',
            },
            targets: [
              {
                id: 'target_1',
                annotationId: 'annotation_1',
                sourceUrl: location.href,
                selector: [{ type: 'TextQuoteSelector', exact: 'beta' }],
              },
            ],
            bodies: [],
          },
        }),
    },
  });
});

afterEach(() => {
  window.getSelection()?.removeAllRanges();
  vi.unstubAllGlobals();
});

describe('annotation toolbar', () => {
  it('opens in shadow DOM and sends create messages for highlights', async () => {
    const dispose = installAnnotationToolbar();
    selectText(document.querySelector('p')!.firstChild as Text, 6, 10);

    document.dispatchEvent(new MouseEvent('mouseup'));
    const host = document.querySelector<HTMLElement>('#marker-annotation-toolbar-host')!;
    expect(host.shadowRoot!.querySelector('[data-action="highlight"] .i-lucide-highlighter')).not.toBeNull();
    expect(host.shadowRoot!.querySelector('[data-action="underline"] .i-lucide-underline')).not.toBeNull();
    expect(host.shadowRoot!.querySelector('[data-action="note"] .i-lucide-sticky-note')).not.toBeNull();
    expect(host.shadowRoot!.querySelector('[data-action="remove"] .i-lucide-trash-2')).not.toBeNull();
    host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="highlight"]')!.click();
    await vi.waitFor(() => {
      expect(chrome.runtime.sendMessage).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'marker:create-annotation', motivation: 'highlighting' }),
      );
    });
    await vi.waitFor(() => {
      expect(document.querySelector('[data-marker-annotation-id="annotation_1"]')).not.toBeNull();
    });
    dispose();
  });

  it('keeps actions clickable when mouseup fires from the shadow toolbar', async () => {
    const dispose = installAnnotationToolbar();
    selectText(document.querySelector('p')!.firstChild as Text, 6, 10);

    document.dispatchEvent(new MouseEvent('mouseup'));
    const host = document.querySelector<HTMLElement>('#marker-annotation-toolbar-host')!;
    const button = host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="highlight"]')!;
    button.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, composed: true }));
    button.click();

    await vi.waitFor(() => {
      expect(chrome.runtime.sendMessage).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'marker:create-annotation', motivation: 'highlighting' }),
      );
    });
    dispose();
  });

  it('opens the toolbar from rendered annotation hover and click', () => {
    document.body.innerHTML = '<p>Alpha <mark data-marker-annotation-id="annotation_1">beta</mark> gamma</p>';
    const dispose = installAnnotationToolbar();
    const mark = document.querySelector<HTMLElement>('mark')!;

    mark.dispatchEvent(new PointerEvent('pointerover', { bubbles: true }));

    let host = document.querySelector<HTMLElement>('#marker-annotation-toolbar-host')!;
    expect(host).not.toBeNull();
    expect(host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="highlight"]')!.disabled).toBe(true);
    expect(host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="remove"]')!.disabled).toBe(false);

    host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="dismiss"]')!.click();
    mark.click();

    host = document.querySelector<HTMLElement>('#marker-annotation-toolbar-host')!;
    expect(host).not.toBeNull();
    expect(host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="remove"]')!.disabled).toBe(false);
    dispose();
  });

  it('removes selected rendered annotations from the toolbar', async () => {
    const sendMessage = chrome.runtime.sendMessage as ReturnType<typeof vi.fn>;
    sendMessage.mockResolvedValueOnce({ ok: true });
    document.body.innerHTML = '<p>Alpha <mark data-marker-annotation-id="annotation_1">beta</mark> gamma</p>';
    const dispose = installAnnotationToolbar();
    selectText(document.querySelector('mark')!.firstChild as Text, 0, 4);

    document.dispatchEvent(new MouseEvent('mouseup'));
    const host = document.querySelector<HTMLElement>('#marker-annotation-toolbar-host')!;
    const remove = host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="remove"]')!;
    expect(remove.disabled).toBe(false);
    remove.click();

    await vi.waitFor(() => {
      expect(chrome.runtime.sendMessage).toHaveBeenCalledWith({
        type: 'marker:delete-annotation',
        annotationId: 'annotation_1',
      });
    });
    await vi.waitFor(() => {
      expect(document.querySelector('[data-marker-annotation-id="annotation_1"]')).toBeNull();
    });
    expect(document.body.textContent).toBe('Alpha beta gamma');
    dispose();
  });

  it('shows a markdown note dialog with sanitized live preview', async () => {
    const dispose = installAnnotationToolbar();
    selectText(document.querySelector('p')!.firstChild as Text, 6, 10);

    document.dispatchEvent(new MouseEvent('mouseup'));
    const host = document.querySelector<HTMLElement>('#marker-annotation-toolbar-host')!;
    host.shadowRoot!.querySelector<HTMLButtonElement>('[data-action="note"]')!.click();
    const textarea = host.shadowRoot!.querySelector<HTMLTextAreaElement>('textarea')!;
    textarea.value = '**safe** <img src=x onerror=alert(1)>';
    textarea.dispatchEvent(new InputEvent('input'));

    expect(host.shadowRoot!.querySelector('.preview')!.innerHTML).toContain('<strong>safe</strong>');
    expect(host.shadowRoot!.querySelector('.preview')!.innerHTML).not.toContain('<img');
    host.shadowRoot!.querySelector('form')!.dispatchEvent(new SubmitEvent('submit'));
    await vi.waitFor(() => {
      expect(chrome.runtime.sendMessage).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'marker:create-annotation', motivation: 'commenting' }),
      );
    });
    dispose();
  });
});
