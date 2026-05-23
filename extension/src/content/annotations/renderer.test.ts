// @vitest-environment happy-dom
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { AnnotationWithParts } from '@/db/annotation-repository';
import type { AnnotationMotivation, Selector } from '@/db/schema';
import { cleanupRenderedAnnotations, renderAnnotations, resolveRange, scrollToAnnotation } from './renderer';

function annotation(
  id: string,
  selector: Selector[],
  motivation: AnnotationMotivation = 'highlighting',
): AnnotationWithParts {
  return {
    annotation: { id, pageId: 'page_1', motivation, createdAt: 'now', modifiedAt: 'now' },
    targets: [{ id: `target_${id}`, annotationId: id, sourceUrl: 'https://example.com', selector }],
    bodies: [],
  };
}

beforeEach(() => {
  document.body.innerHTML = '';
});

describe('annotation renderer', () => {
  it('resolves duplicate quotes with prefix and suffix scoring', () => {
    document.body.innerHTML = '<p>First repeat middle repeat final</p>';

    const range = resolveRange([{ type: 'TextQuoteSelector', exact: 'repeat', prefix: ' middle ', suffix: ' final' }]);

    expect(range?.toString()).toBe('repeat');
    expect(range?.startOffset).toBe(20);
  });

  it('renders multi-node ranges', () => {
    document.body.innerHTML = '<p>Alpha <strong>beta</strong> gamma</p>';

    renderAnnotations([annotation('a1', [{ type: 'TextPositionSelector', start: 3, end: 14 }])], { retryMs: 0 });

    expect(document.querySelectorAll('[data-marker-annotation-id="a1"]')).toHaveLength(3);
    expect(document.body.textContent).toBe('Alpha beta gamma');
  });

  it('uses position fallback then css fallback when quote cannot resolve', () => {
    document.body.innerHTML = '<article id="story">Alpha beta</article>';

    expect(
      resolveRange([
        { type: 'TextQuoteSelector', exact: 'missing' },
        { type: 'TextPositionSelector', start: 6, end: 10 },
      ])?.toString(),
    ).toBe('beta');
    expect(resolveRange([{ type: 'CssSelector', value: '#story' }])?.toString()).toBe('Alpha beta');
  });

  it('supports underline rendering', () => {
    document.body.innerHTML = '<p>Alpha beta</p>';

    renderAnnotations([annotation('a1', [{ type: 'TextQuoteSelector', exact: 'beta' }], 'linking')], { retryMs: 0 });

    const mark = document.querySelector<HTMLElement>('[data-marker-annotation-id="a1"]')!;
    expect(mark.dataset.markerStyle).toBe('underline');
    expect(mark.style.backgroundColor).toBe('transparent');
    expect(mark.style.color).toBe('inherit');
    expect(mark.style.textDecoration).toContain('underline');
  });

  it('cleans up repeated renders and deleted annotations', () => {
    document.body.innerHTML = '<p>Alpha beta gamma</p>';
    const first = annotation('a1', [{ type: 'TextQuoteSelector', exact: 'beta' }]);
    const second = annotation('a2', [{ type: 'TextQuoteSelector', exact: 'gamma' }]);

    renderAnnotations([first], { retryMs: 0 });
    renderAnnotations([first, second], { retryMs: 0 });
    cleanupRenderedAnnotations('a1');

    expect(document.querySelectorAll('[data-marker-annotation-id="a1"]')).toHaveLength(0);
    expect(document.querySelectorAll('[data-marker-annotation-id="a2"]')).toHaveLength(1);
    expect(document.body.textContent).toBe('Alpha beta gamma');
  });

  it('does not render hidden nodes', () => {
    document.body.innerHTML = '<p><span hidden>hidden</span>Visible</p>';

    renderAnnotations([annotation('a1', [{ type: 'TextQuoteSelector', exact: 'hidden' }])], { retryMs: 0 });

    expect(document.querySelector('[data-marker-annotation-id="a1"]')).toBeNull();
  });

  it('handles nested annotations by rerendering from clean text', () => {
    document.body.innerHTML = '<p>Alpha beta gamma</p>';

    renderAnnotations(
      [
        annotation('outer', [{ type: 'TextQuoteSelector', exact: 'beta gamma' }]),
        annotation('inner', [{ type: 'TextQuoteSelector', exact: 'beta' }]),
      ],
      { retryMs: 0 },
    );

    expect(document.querySelectorAll('[data-marker-annotation-id]')).toHaveLength(2);
    expect(document.body.textContent).toBe('Alpha beta gamma');
  });

  it('retries delayed content and can be disposed', async () => {
    vi.useFakeTimers();
    document.body.innerHTML = '<main></main>';

    const dispose = renderAnnotations([annotation('a1', [{ type: 'TextQuoteSelector', exact: 'later' }])], {
      retryMs: 25,
    });
    document.querySelector('main')!.textContent = 'loaded later';
    await vi.advanceTimersByTimeAsync(25);

    expect(document.querySelector('[data-marker-annotation-id="a1"]')).not.toBeNull();
    dispose();
    expect(document.querySelector('[data-marker-annotation-id="a1"]')).toBeNull();
    vi.useRealTimers();
  });

  it('scrolls to annotations', () => {
    document.body.innerHTML = '<p>Alpha beta</p>';
    renderAnnotations([annotation('a1', [{ type: 'TextQuoteSelector', exact: 'beta' }])], { retryMs: 0 });
    const mark = document.querySelector<HTMLElement>('[data-marker-annotation-id="a1"]')!;
    const scrollIntoView = vi.fn();
    mark.scrollIntoView = scrollIntoView;

    expect(scrollToAnnotation('a1')).toBe(true);
    expect(scrollIntoView).toHaveBeenCalledWith({ block: 'center', inline: 'nearest', behavior: 'smooth' });
    expect(scrollToAnnotation('missing')).toBe(false);
  });
});
