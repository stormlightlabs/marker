import type { AnnotationWithParts } from '@/db/annotation-repository';
import type { Selector } from '@/db/schema';
import { isHiddenNode, visibleText, visibleTextNodes } from './selectors';

export const ANNOTATION_ATTRIBUTE = 'data-marker-annotation-id';
export const ANNOTATION_LAYER_CLASS = 'marker-annotation';

export type RenderAnnotationOptions = { retryMs?: number; onMissing?: (annotationId: string) => void };

export function renderAnnotations(
  annotations: AnnotationWithParts[],
  options: RenderAnnotationOptions = {},
): () => void {
  cleanupRenderedAnnotations();
  let missing = annotations.filter((annotation) => !renderAnnotation(annotation));

  let observer: MutationObserver | null = null;
  let timeoutId: number | undefined;
  if (missing.length > 0 && options.retryMs !== 0) {
    const observe = () => observer?.observe(document.body, { childList: true, subtree: true, characterData: true });
    const retry = () => {
      observer?.disconnect();
      cleanupRenderedAnnotations();
      missing = annotations.filter((annotation) => !renderAnnotation(annotation));
      for (const annotation of missing) {
        options.onMissing?.(annotation.annotation.id);
      }
      if (missing.length > 0) {
        observe();
      }
    };
    observer = new MutationObserver(retry);
    observe();
    timeoutId = window.setTimeout(retry, options.retryMs ?? 150);
  }

  return () => {
    observer?.disconnect();
    if (timeoutId != null) {
      window.clearTimeout(timeoutId);
    }
    cleanupRenderedAnnotations();
  };
}

export function renderAnnotation(annotation: AnnotationWithParts): boolean {
  const selectors = annotation.targets[0]?.selector ?? [];
  const range = resolveRange(selectors);
  if (range == null || range.collapsed) {
    return false;
  }

  const style = annotation.annotation.motivation === 'linking' ? 'underline' : 'highlight';
  wrapRange(range, annotation.annotation.id, style);
  return true;
}

export function cleanupRenderedAnnotations(annotationId?: string): void {
  const selector =
    annotationId == null ? `[${ANNOTATION_ATTRIBUTE}]` : `[${ANNOTATION_ATTRIBUTE}="${CSS.escape(annotationId)}"]`;
  const wrappers = [...document.querySelectorAll<HTMLElement>(selector)];
  for (const wrapper of wrappers) {
    const parent = wrapper.parentNode;
    if (parent == null) {
      continue;
    }
    while (wrapper.firstChild != null) {
      parent.insertBefore(wrapper.firstChild, wrapper);
    }
    wrapper.remove();
    parent.normalize();
  }
}

export function scrollToAnnotation(annotationId: string): boolean {
  const element = document.querySelector<HTMLElement>(`[${ANNOTATION_ATTRIBUTE}="${CSS.escape(annotationId)}"]`);
  if (element == null) {
    return false;
  }
  element.scrollIntoView({ block: 'center', inline: 'nearest', behavior: 'smooth' });
  return true;
}

export function resolveRange(selectors: Selector[]): Range | null {
  const quote = selectors.find(
    (selector): selector is Extract<Selector, { type: 'TextQuoteSelector' }> => selector.type === 'TextQuoteSelector',
  );
  if (quote != null) {
    const range = resolveQuoteSelector(quote);
    if (range != null) return range;
  }

  const position = selectors.find(
    (selector): selector is Extract<Selector, { type: 'TextPositionSelector' }> =>
      selector.type === 'TextPositionSelector',
  );
  if (position != null) {
    const range = resolvePositionSelector(position);
    if (range != null) return range;
  }

  const css = selectors.find(
    (selector): selector is Extract<Selector, { type: 'CssSelector' }> => selector.type === 'CssSelector',
  );
  if (css != null) {
    const element = document.querySelector(css.value);
    if (element != null && !isHiddenNode(element)) {
      const range = document.createRange();
      range.selectNodeContents(element);
      return range;
    }
  }

  return null;
}

function resolveQuoteSelector(selector: Extract<Selector, { type: 'TextQuoteSelector' }>): Range | null {
  const text = visibleText(document.body);
  const candidates: Array<{ start: number; score: number }> = [];
  let index = text.indexOf(selector.exact);
  while (index !== -1) {
    let score = 0;
    if (selector.prefix != null && text.slice(Math.max(0, index - selector.prefix.length), index) === selector.prefix)
      score += selector.prefix.length;
    if (
      selector.suffix != null &&
      text.slice(index + selector.exact.length, index + selector.exact.length + selector.suffix.length) ===
        selector.suffix
    )
      score += selector.suffix.length;
    candidates.push({ start: index, score });
    index = text.indexOf(selector.exact, index + 1);
  }
  candidates.sort((a, b) => b.score - a.score || a.start - b.start);
  const best = candidates[0];
  return best == null ? null : rangeFromOffsets(best.start, best.start + selector.exact.length);
}

function resolvePositionSelector(selector: Extract<Selector, { type: 'TextPositionSelector' }>): Range | null {
  return rangeFromOffsets(selector.start, selector.end);
}

function rangeFromOffsets(start: number, end: number): Range | null {
  if (start < 0 || end <= start) {
    return null;
  }
  const nodes = visibleTextNodes(document.body);
  const startNode = nodes.find((node) => start >= node.start && start <= node.end);
  const endNode = nodes.find((node) => end >= node.start && end <= node.end);
  if (startNode == null || endNode == null) {
    return null;
  }
  const range = document.createRange();
  range.setStart(startNode.node, start - startNode.start);
  range.setEnd(endNode.node, end - endNode.start);
  return range;
}

function wrapRange(range: Range, annotationId: string, style: 'highlight' | 'underline'): void {
  const textNodes = visibleTextNodes(
    range.commonAncestorContainer.nodeType === Node.ELEMENT_NODE
      ? (range.commonAncestorContainer as Element)
      : (range.commonAncestorContainer.parentElement ?? document.body),
  )
    .map(({ node }) => node)
    .filter((node) => range.intersectsNode(node));

  for (const node of textNodes) {
    const start = node === range.startContainer ? range.startOffset : 0;
    const end = node === range.endContainer ? range.endOffset : node.data.length;
    if (start === end) {
      continue;
    }
    const nodeRange = document.createRange();
    nodeRange.setStart(node, start);
    nodeRange.setEnd(node, end);
    const wrapper = document.createElement('mark');
    wrapper.className = `${ANNOTATION_LAYER_CLASS} marker-annotation--${style}`;
    wrapper.setAttribute(ANNOTATION_ATTRIBUTE, annotationId);
    wrapper.dataset.markerStyle = style;
    if (style === 'underline') {
      wrapper.style.backgroundColor = 'transparent';
      wrapper.style.color = 'inherit';
      wrapper.style.textDecoration = 'underline';
      wrapper.style.textDecorationColor = 'currentColor';
      wrapper.style.textDecorationThickness = '0.12em';
    } else {
      wrapper.style.backgroundColor = 'rgba(255, 214, 10, 0.45)';
      wrapper.style.color = 'inherit';
    }
    nodeRange.surroundContents(wrapper);
  }
}
