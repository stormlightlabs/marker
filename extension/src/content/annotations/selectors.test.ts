// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { captureSelection, clearSelection, visibleText } from './selectors';

function selectText(startNode: Text, start: number, endNode: Text, end: number): void {
  const range = document.createRange();
  range.setStart(startNode, start);
  range.setEnd(endNode, end);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}

beforeEach(() => {
  document.body.innerHTML = '';
});

afterEach(() => {
  window.getSelection()?.removeAllRanges();
});

describe('captureSelection', () => {
  it('captures quote, text position, and css selectors for a selection', () => {
    document.body.innerHTML = '<main id="article">Alpha beta gamma</main>';
    const text = document.querySelector('main')!.firstChild as Text;
    selectText(text, 6, text, 10);

    const captured = captureSelection();

    expect(captured?.exact).toBe('beta');
    expect(captured?.selectors).toContainEqual({ type: 'TextPositionSelector', start: 6, end: 10 });
    expect(captured?.selectors[0]).toMatchObject({ type: 'TextQuoteSelector', exact: 'beta', prefix: 'Alpha ', suffix: ' gamma' });
    expect(captured?.selectors).toContainEqual({ type: 'CssSelector', value: '#article' });
  });

  it('keeps offsets safe when leading and trailing whitespace are selected', () => {
    document.body.innerHTML = '<p>Alpha  beta  gamma</p>';
    const text = document.querySelector('p')!.firstChild as Text;
    selectText(text, 5, text, 12);

    const position = captureSelection()?.selectors.find((selector) => selector.type === 'TextPositionSelector');

    expect(position).toEqual({ type: 'TextPositionSelector', start: 5, end: 12 });
  });

  it('captures cross-element and nested inline ranges', () => {
    document.body.innerHTML = '<p>Alpha <strong>nested <em>inline</em></strong> omega</p>';
    const start = document.querySelector('p')!.firstChild as Text;
    const end = document.querySelector('em')!.firstChild as Text;
    selectText(start, 2, end, 6);

    const captured = captureSelection();

    expect(captured?.exact).toBe('pha nested inline');
    expect(captured?.selectors).toContainEqual({ type: 'TextPositionSelector', start: 2, end: 19 });
  });

  it('filters hidden text from text and offsets', () => {
    document.body.innerHTML = '<p>Visible <span hidden>hidden</span><span style="display: none">gone</span>text</p>';

    expect(visibleText()).toBe('Visible text');
  });

  it('returns null for empty, whitespace-only, and invalid selections', () => {
    expect(captureSelection()).toBeNull();

    document.body.innerHTML = '<p>   </p>';
    const text = document.querySelector('p')!.firstChild as Text;
    selectText(text, 0, text, 3);
    expect(captureSelection()).toBeNull();
  });

  it('clears the active selection', () => {
    document.body.innerHTML = '<p>Alpha beta</p>';
    const text = document.querySelector('p')!.firstChild as Text;
    selectText(text, 0, text, 5);

    clearSelection();

    expect(window.getSelection()?.rangeCount).toBe(0);
  });
});
