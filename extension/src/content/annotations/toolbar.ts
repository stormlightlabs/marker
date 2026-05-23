import type { AnnotationWithParts } from '@/db/annotation-repository';
import { MarkerMessageType, type CreateAnnotationMessage, type MarkerMessageResponse } from '@/shared/messages';
import { currentPageMetadata } from '@/content/reader/page-meta';
import { captureSelection, clearSelection, type CapturedSelection } from './selectors';
import { ANNOTATION_ATTRIBUTE, cleanupRenderedAnnotations, renderAnnotation } from './renderer';
import { renderMarkdown } from './markdown';

const TOOLBAR_HOST_ID = 'marker-annotation-toolbar-host';

export function installAnnotationToolbar(): () => void {
  const toolbar = new AnnotationToolbar();
  toolbar.install();
  return () => toolbar.dispose();
}

class AnnotationToolbar {
  private host?: HTMLElement;
  private shadow?: ShadowRoot;
  private currentSelection?: CapturedSelection;
  private currentAnnotationIds: string[] = [];
  private anchorRect?: DOMRect;
  private readonly handleSelectionChanged = (event: Event) => {
    if (this.isToolbarEvent(event)) {
      return;
    }
    this.updateFromSelection();
  };
  private readonly handleKeydown = (event: KeyboardEvent) => {
    if (event.key === 'Escape') {
      this.hide();
      clearSelection();
    }
  };
  private readonly handleAnnotationPointer = (event: Event) => {
    if (this.isToolbarEvent(event)) {
      return;
    }
    const annotation = (event.target as Element | null)?.closest<HTMLElement>(`[${ANNOTATION_ATTRIBUTE}]`);
    if (annotation == null) {
      return;
    }
    this.showForAnnotation(annotation);
  };

  install(): void {
    document.addEventListener('mouseup', this.handleSelectionChanged);
    document.addEventListener('keyup', this.handleSelectionChanged);
    document.addEventListener('keydown', this.handleKeydown);
    document.addEventListener('click', this.handleAnnotationPointer);
    document.addEventListener('pointerover', this.handleAnnotationPointer);
  }

  dispose(): void {
    document.removeEventListener('mouseup', this.handleSelectionChanged);
    document.removeEventListener('keyup', this.handleSelectionChanged);
    document.removeEventListener('keydown', this.handleKeydown);
    document.removeEventListener('click', this.handleAnnotationPointer);
    document.removeEventListener('pointerover', this.handleAnnotationPointer);
    this.host?.remove();
  }

  private updateFromSelection(): void {
    const captured = captureSelection();
    if (captured == null) {
      this.hide();
      return;
    }
    this.currentSelection = captured;
    this.currentAnnotationIds = annotationIdsForSelection();
    this.anchorRect = selectionRect();
    this.renderToolbar();
  }

  private showForAnnotation(annotation: HTMLElement): void {
    const annotationId = annotation.getAttribute(ANNOTATION_ATTRIBUTE);
    if (annotationId == null) return;
    this.currentSelection = undefined;
    this.currentAnnotationIds = [annotationId];
    this.anchorRect = annotation.getBoundingClientRect();
    this.renderToolbar();
  }

  private ensureShadow(): ShadowRoot {
    if (this.shadow != null) return this.shadow;
    this.host = document.createElement('div');
    this.host.id = TOOLBAR_HOST_ID;
    this.host.style.position = 'fixed';
    this.host.style.zIndex = '2147483647';
    document.documentElement.append(this.host);
    this.shadow = this.host.attachShadow({ mode: 'open' });
    const style = document.createElement('style');
    style.textContent = toolbarStyles;
    this.shadow.append(style);
    return this.shadow;
  }

  private renderToolbar(): void {
    const anchorRect = this.anchorRect;
    const shadow = this.ensureShadow();
    this.host!.style.left = `${Math.max(8, anchorRect?.left ?? 8)}px`;
    this.host!.style.top = `${Math.max(8, (anchorRect?.top ?? 48) - 48)}px`;
    shadow.querySelector('.marker-toolbar')?.remove();
    const toolbar = document.createElement('div');
    toolbar.className = 'marker-toolbar';
    const createDisabled = this.currentSelection == null ? 'disabled' : '';
    toolbar.innerHTML = `
      <button type="button" data-action="highlight" aria-label="Highlight" ${createDisabled}><span class="icon i-lucide-highlighter" aria-hidden="true"></span><span>Highlight</span></button>
      <button type="button" data-action="underline" aria-label="Underline" ${createDisabled}><span class="icon i-lucide-underline" aria-hidden="true"></span><span>Underline</span></button>
      <button type="button" data-action="note" aria-label="Note" ${createDisabled}><span class="icon i-lucide-sticky-note" aria-hidden="true"></span><span>Note</span></button>
      <button type="button" data-action="remove" aria-label="Remove" ${this.currentAnnotationIds.length === 0 ? 'disabled' : ''}><span class="icon i-lucide-trash-2" aria-hidden="true"></span><span>Remove</span></button>
      <button type="button" data-action="dismiss" aria-label="Dismiss"><span class="icon i-lucide-x" aria-hidden="true"></span></button>
    `;
    toolbar.addEventListener('pointerdown', (event) => {
      event.preventDefault();
      event.stopPropagation();
    });
    toolbar.addEventListener('mousedown', (event) => {
      event.preventDefault();
      event.stopPropagation();
    });
    toolbar.addEventListener('click', (event) => this.handleToolbarClick(event));
    shadow.append(toolbar);
  }

  private handleToolbarClick(event: Event): void {
    const button = (event.target as Element).closest<HTMLButtonElement>('button[data-action]');
    const action = button?.dataset.action;
    if (action === 'highlight') void this.saveStyleAnnotation('highlight');
    if (action === 'underline') void this.saveStyleAnnotation('underline');
    if (action === 'note') this.renderNoteDialog();
    if (action === 'remove') void this.removeSelectedAnnotations();
    if (action === 'dismiss') this.hide();
  }

  private async saveStyleAnnotation(style: 'highlight' | 'underline'): Promise<void> {
    const captured = this.currentSelection;
    if (captured == null) return;
    const response = await createAnnotation({
      selector: captured.selectors,
      motivation: style === 'highlight' ? 'highlighting' : 'linking',
      bodies: [{ type: 'StyleHint', format: 'application/json', value: JSON.stringify({ style }) }],
    });
    this.applyCreatedAnnotation(response);
  }

  private async removeSelectedAnnotations(): Promise<void> {
    const annotationIds = this.currentAnnotationIds;
    if (annotationIds.length === 0) return;

    const results = await Promise.all(
      annotationIds.map(
        (annotationId) =>
          chrome.runtime.sendMessage({ type: MarkerMessageType.DeleteAnnotation, annotationId }) as Promise<
            { ok: true } | { ok: false; reason: string }
          >,
      ),
    );
    const failed = results.find((result) => !result.ok);
    if (failed != null && !failed.ok) {
      this.showError(failed.reason);
      return;
    }

    for (const annotationId of annotationIds) {
      cleanupRenderedAnnotations(annotationId);
    }
    this.hide();
    clearSelection();
  }

  private renderNoteDialog(): void {
    const shadow = this.ensureShadow();
    shadow.querySelector('.marker-toolbar')?.remove();
    const dialog = document.createElement('form');
    dialog.className = 'marker-note-dialog';
    dialog.innerHTML = `
      <label>Markdown note<textarea name="note" rows="5" placeholder="Why does this matter?"></textarea></label>
      <div class="preview" aria-live="polite"></div>
      <div class="actions"><button type="submit">Save note</button><button type="button" data-action="cancel">Cancel</button></div>
    `;
    const textarea = dialog.querySelector<HTMLTextAreaElement>('textarea')!;
    const preview = dialog.querySelector<HTMLElement>('.preview')!;
    textarea.addEventListener('input', () => {
      preview.innerHTML = renderMarkdown(textarea.value);
    });
    dialog.addEventListener('pointerdown', (event) => {
      event.stopPropagation();
    });
    dialog.addEventListener('mousedown', (event) => {
      event.stopPropagation();
    });
    dialog.addEventListener('click', (event) => {
      if ((event.target as Element).closest('[data-action="cancel"]') != null) this.hide();
    });
    dialog.addEventListener('submit', (event) => {
      event.preventDefault();
      void this.saveNote(textarea.value);
    });
    shadow.append(dialog);
    textarea.focus();
  }

  private async saveNote(markdown: string): Promise<void> {
    const captured = this.currentSelection;
    if (captured == null) return;
    const response = await createAnnotation({
      selector: captured.selectors,
      motivation: 'commenting',
      bodies: [
        { type: 'TextualBody', format: 'text/markdown', value: markdown },
        { type: 'TextualBody', format: 'text/plain', value: captured.exact },
      ],
    });
    this.applyCreatedAnnotation(response);
  }

  private applyCreatedAnnotation(response: MarkerMessageResponse<CreateAnnotationMessage>): void {
    if (response?.ok) {
      renderAnnotation(response.annotation as AnnotationWithParts);
      this.hide();
      clearSelection();
      return;
    }
    this.showError(response?.reason ?? 'Marker could not save this annotation.');
  }

  private showError(message: string): void {
    const shadow = this.ensureShadow();
    const error = document.createElement('p');
    error.className = 'error';
    error.textContent = message;
    shadow.append(error);
  }

  private hide(): void {
    this.currentSelection = undefined;
    this.currentAnnotationIds = [];
    this.anchorRect = undefined;
    this.host?.remove();
    this.host = undefined;
    this.shadow = undefined;
  }

  private isToolbarEvent(event: Event): boolean {
    return this.host != null && event.composedPath().includes(this.host);
  }
}

function selectionRect(): DOMRect | undefined {
  const selection = window.getSelection();
  return selection?.rangeCount ? selection.getRangeAt(0).getBoundingClientRect() : undefined;
}

function annotationIdsForSelection(): string[] {
  const selection = window.getSelection();
  if (selection == null || selection.rangeCount === 0) return [];

  const range = selection.getRangeAt(0);
  const ids = new Set<string>();
  for (const element of document.querySelectorAll<HTMLElement>(`[${ANNOTATION_ATTRIBUTE}]`)) {
    if (range.intersectsNode(element)) {
      const annotationId = element.getAttribute(ANNOTATION_ATTRIBUTE);
      if (annotationId != null) ids.add(annotationId);
    }
  }
  return [...ids];
}

async function createAnnotation(
  input: Pick<CreateAnnotationMessage, 'selector' | 'motivation' | 'bodies'>,
): Promise<MarkerMessageResponse<CreateAnnotationMessage>> {
  const message: CreateAnnotationMessage = {
    type: MarkerMessageType.CreateAnnotation,
    url: window.location.href,
    metadata: currentPageMetadata(),
    ...input,
  };
  return chrome.runtime.sendMessage(message);
}

const toolbarStyles = `
  :host { all: initial; font-family: Inter, ui-sans-serif, system-ui, sans-serif; color: #161616; }
  .marker-toolbar, .marker-note-dialog { box-sizing: border-box; border: 1px solid rgb(0 0 0 / 18%); border-radius: 12px; background: #fffdf7; box-shadow: 0 18px 50px rgb(0 0 0 / 20%); padding: 8px; display: flex; gap: 6px; align-items: center; }
  button { appearance: none; border: 1px solid rgb(0 0 0 / 16%); border-radius: 999px; background: #161616; color: white; cursor: pointer; display: inline-flex; align-items: center; gap: 6px; font: 600 12px/1 Inter, ui-sans-serif, system-ui, sans-serif; padding: 8px 10px; }
  button:hover { filter: brightness(1.08); }
  button:disabled { cursor: not-allowed; opacity: 0.45; filter: none; }
  .icon { display: inline-block; width: 1em; height: 1em; flex: 0 0 auto; background-color: currentColor; color: inherit; -webkit-mask: var(--un-icon) no-repeat; mask: var(--un-icon) no-repeat; -webkit-mask-size: 100% 100%; mask-size: 100% 100%; }
  .i-lucide-highlighter { --un-icon: url("data:image/svg+xml;utf8,%3Csvg viewBox='0 0 24 24' width='1em' height='1em' xmlns='http://www.w3.org/2000/svg' %3E%3Cg fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round' stroke-width='2'%3E%3Cpath d='m9 11l-6 6v3h9l3-3'/%3E%3Cpath d='m22 12l-4.6 4.6a2 2 0 0 1-2.8 0l-5.2-5.2a2 2 0 0 1 0-2.8L14 4'/%3E%3C/g%3E%3C/svg%3E"); }
  .i-lucide-sticky-note { --un-icon: url("data:image/svg+xml;utf8,%3Csvg viewBox='0 0 24 24' width='1em' height='1em' xmlns='http://www.w3.org/2000/svg' %3E%3Cpath fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M16 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8Zm-1 0v4a2 2 0 0 0 2 2h4'/%3E%3C/svg%3E"); }
  .i-lucide-trash-2 { --un-icon: url("data:image/svg+xml;utf8,%3Csvg viewBox='0 0 24 24' width='1em' height='1em' xmlns='http://www.w3.org/2000/svg' %3E%3Cpath fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M10 11v6m4-6v6m5-11v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2'/%3E%3C/svg%3E"); }
  .i-lucide-underline { --un-icon: url("data:image/svg+xml;utf8,%3Csvg viewBox='0 0 24 24' width='1em' height='1em' xmlns='http://www.w3.org/2000/svg' %3E%3Cg fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round' stroke-width='2'%3E%3Cpath d='M6 4v6a6 6 0 0 0 12 0V4'/%3E%3Cpath d='M4 20h16'/%3E%3C/g%3E%3C/svg%3E"); }
  .i-lucide-x { --un-icon: url("data:image/svg+xml;utf8,%3Csvg viewBox='0 0 24 24' width='1em' height='1em' xmlns='http://www.w3.org/2000/svg' %3E%3Cpath fill='none' stroke='currentColor' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M18 6 6 18M6 6l12 12'/%3E%3C/svg%3E"); }
  .marker-note-dialog { width: min(320px, calc(100vw - 24px)); align-items: stretch; flex-direction: column; }
  label { display: grid; gap: 6px; font: 600 12px/1.3 Inter, ui-sans-serif, system-ui, sans-serif; }
  textarea { box-sizing: border-box; width: 100%; border: 1px solid rgb(0 0 0 / 18%); border-radius: 10px; color: #161616; padding: 8px; resize: vertical; font: 13px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace; }
  .preview { min-height: 36px; border: 1px dashed rgb(0 0 0 / 18%); border-radius: 10px; padding: 8px; font: 13px/1.4 Inter, ui-sans-serif, system-ui, sans-serif; }
  .preview p { margin: 0 0 0.5em; }
  .preview p:last-child { margin-bottom: 0; }
  .actions { display: flex; justify-content: flex-end; gap: 6px; }
  .error { margin: 8px 0 0; border-radius: 10px; background: #ffe4e6; color: #9f1239; padding: 8px; font: 12px/1.4 Inter, ui-sans-serif, system-ui, sans-serif; }
`;
