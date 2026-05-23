import type { Selector } from '@/db/schema';

export type CapturedSelection = { selectors: Selector[]; exact: string };

type VisibleTextNode = { node: Text; start: number; end: number };

const CONTEXT_LENGTH = 32;

export function captureSelection(selection = globalThis.getSelection?.() ?? null): CapturedSelection | null {
  if (selection == null || selection.rangeCount === 0 || selection.isCollapsed) {
    return null;
  }

  const range = selection.getRangeAt(0);
  if (!isValidRange(range)) {
    return null;
  }

  const exact = visibleTextForRange(range);
  if (exact.trim().length === 0) {
    return null;
  }

  const position = textPositionForRange(range);
  if (position == null || position.start === position.end) {
    return null;
  }

  const documentText = visibleText(document.body);
  const prefix = documentText.slice(Math.max(0, position.start - CONTEXT_LENGTH), position.start);
  const suffix = documentText.slice(position.end, Math.min(documentText.length, position.end + CONTEXT_LENGTH));
  const cssSelector = cssSelectorForRange(range);

  const selectors: Selector[] = [
    { type: 'TextQuoteSelector', exact, prefix, suffix },
    { type: 'TextPositionSelector', start: position.start, end: position.end },
  ];

  if (cssSelector != null) {
    selectors.push({ type: 'CssSelector', value: cssSelector });
  }

  return { selectors, exact };
}

export function clearSelection(selection = globalThis.getSelection?.() ?? null): void {
  selection?.removeAllRanges();
}

export function visibleText(root: ParentNode = document.body): string {
  return visibleTextNodes(root)
    .map(({ node }) => node.data)
    .join('');
}

export function visibleTextNodes(root: ParentNode = document.body): VisibleTextNode[] {
  const ownerDocument = root instanceof Document ? root : (root.ownerDocument ?? document);
  const walker = ownerDocument.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      if (!(node instanceof Text) || node.data.length === 0 || isHiddenNode(node)) {
        return NodeFilter.FILTER_REJECT;
      }
      return NodeFilter.FILTER_ACCEPT;
    },
  });

  const nodes: VisibleTextNode[] = [];
  let offset = 0;
  let current = walker.nextNode();
  while (current != null) {
    const text = current as Text;
    nodes.push({ node: text, start: offset, end: offset + text.data.length });
    offset += text.data.length;
    current = walker.nextNode();
  }
  return nodes;
}

export function isHiddenNode(node: Node): boolean {
  const element = node.nodeType === Node.ELEMENT_NODE ? (node as Element) : node.parentElement;
  for (let current: Element | null = element; current != null; current = current.parentElement) {
    if (current.hasAttribute('hidden') || current.getAttribute('aria-hidden') === 'true') {
      return true;
    }
    const style = globalThis.getComputedStyle?.(current);
    if (style != null && (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0')) {
      return true;
    }
  }
  return false;
}

function isValidRange(range: Range): boolean {
  const common = range.commonAncestorContainer;
  return document.body.contains(common.nodeType === Node.ELEMENT_NODE ? common : common.parentElement);
}

function visibleTextForRange(range: Range): string {
  return visibleTextNodes(
    range.commonAncestorContainer.nodeType === Node.ELEMENT_NODE
      ? (range.commonAncestorContainer as Element)
      : (range.commonAncestorContainer.parentElement ?? document.body),
  )
    .filter(({ node }) => range.intersectsNode(node))
    .map(({ node }) => {
      const start = node === range.startContainer ? range.startOffset : 0;
      const end = node === range.endContainer ? range.endOffset : node.data.length;
      return node.data.slice(start, end);
    })
    .join('');
}

function textPositionForRange(range: Range): { start: number; end: number } | null {
  const nodes = visibleTextNodes(document.body);
  const startNode = nodes.find(({ node }) => node === range.startContainer);
  const endNode = nodes.find(({ node }) => node === range.endContainer);
  if (startNode == null || endNode == null) {
    return null;
  }
  return { start: startNode.start + range.startOffset, end: endNode.start + range.endOffset };
}

function cssSelectorForRange(range: Range): string | null {
  const element = nearestElement(range.commonAncestorContainer);
  if (element == null || element === document.documentElement) {
    return null;
  }
  return cssPath(element);
}

function nearestElement(node: Node): Element | null {
  return node.nodeType === Node.ELEMENT_NODE ? (node as Element) : node.parentElement;
}

function cssPath(element: Element): string {
  if (element.id.length > 0) {
    return `#${CSS.escape(element.id)}`;
  }
  const parts: string[] = [];
  for (
    let current: Element | null = element;
    current != null && current !== document.body;
    current = current.parentElement
  ) {
    const parent = current.parentElement;
    if (parent == null) {
      break;
    }
    const tag = current.tagName.toLowerCase();
    const siblings = [...parent.children].filter((child) => child.tagName === current.tagName);
    const index = siblings.indexOf(current) + 1;
    parts.unshift(siblings.length > 1 ? `${tag}:nth-of-type(${index})` : tag);
  }
  return parts.length === 0 ? 'body' : `body > ${parts.join(' > ')}`;
}
