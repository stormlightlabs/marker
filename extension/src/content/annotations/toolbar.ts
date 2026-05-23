import type { AnnotationWithParts } from '@/db/annotation-repository';
import { MarkerMessageType, type CreateAnnotationMessage, type MarkerMessageResponse } from '@/shared/messages';
import { currentPageMetadata } from '@/content/reader/page-meta';
import { captureSelection, clearSelection, type CapturedSelection } from './selectors';
import { renderAnnotation } from './renderer';
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
  private readonly handleSelectionChanged = () => this.updateFromSelection();
  private readonly handleKeydown = (event: KeyboardEvent) => {
    if (event.key === 'Escape') {
      this.hide();
      clearSelection();
    }
  };

  install(): void {
    document.addEventListener('mouseup', this.handleSelectionChanged);
    document.addEventListener('keyup', this.handleSelectionChanged);
    document.addEventListener('keydown', this.handleKeydown);
  }

  dispose(): void {
    document.removeEventListener('mouseup', this.handleSelectionChanged);
    document.removeEventListener('keyup', this.handleSelectionChanged);
    document.removeEventListener('keydown', this.handleKeydown);
    this.host?.remove();
  }

  private updateFromSelection(): void {
    const captured = captureSelection();
    if (captured == null) {
      this.hide();
      return;
    }
    this.currentSelection = captured;
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
    const selectionRect = window.getSelection()?.rangeCount ? window.getSelection()?.getRangeAt(0).getBoundingClientRect() : undefined;
    const shadow = this.ensureShadow();
    this.host!.style.left = `${Math.max(8, selectionRect?.left ?? 8)}px`;
    this.host!.style.top = `${Math.max(8, (selectionRect?.top ?? 48) - 48)}px`;
    shadow.querySelector('.marker-toolbar')?.remove();
    const toolbar = document.createElement('div');
    toolbar.className = 'marker-toolbar';
    toolbar.innerHTML = `
      <button type="button" data-action="highlight">Highlight</button>
      <button type="button" data-action="underline">Underline</button>
      <button type="button" data-action="note">Note</button>
      <button type="button" data-action="dismiss" aria-label="Dismiss">×</button>
    `;
    toolbar.addEventListener('click', (event) => this.handleToolbarClick(event));
    shadow.append(toolbar);
  }

  private handleToolbarClick(event: Event): void {
    const button = (event.target as Element).closest<HTMLButtonElement>('button[data-action]');
    const action = button?.dataset.action;
    if (action === 'highlight') void this.saveStyleAnnotation('highlight');
    if (action === 'underline') void this.saveStyleAnnotation('underline');
    if (action === 'note') this.renderNoteDialog();
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
    this.host?.remove();
    this.host = undefined;
    this.shadow = undefined;
  }
}

async function createAnnotation(input: Pick<CreateAnnotationMessage, 'selector' | 'motivation' | 'bodies'>): Promise<MarkerMessageResponse<CreateAnnotationMessage>> {
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
  button { appearance: none; border: 1px solid rgb(0 0 0 / 16%); border-radius: 999px; background: #161616; color: white; cursor: pointer; font: 600 12px/1 Inter, ui-sans-serif, system-ui, sans-serif; padding: 8px 10px; }
  button:hover { filter: brightness(1.08); }
  .marker-note-dialog { width: min(320px, calc(100vw - 24px)); align-items: stretch; flex-direction: column; }
  label { display: grid; gap: 6px; font: 600 12px/1.3 Inter, ui-sans-serif, system-ui, sans-serif; }
  textarea { box-sizing: border-box; width: 100%; border: 1px solid rgb(0 0 0 / 18%); border-radius: 10px; color: #161616; padding: 8px; resize: vertical; font: 13px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace; }
  .preview { min-height: 36px; border: 1px dashed rgb(0 0 0 / 18%); border-radius: 10px; padding: 8px; font: 13px/1.4 Inter, ui-sans-serif, system-ui, sans-serif; }
  .preview p { margin: 0 0 0.5em; }
  .preview p:last-child { margin-bottom: 0; }
  .actions { display: flex; justify-content: flex-end; gap: 6px; }
  .error { margin: 8px 0 0; border-radius: 10px; background: #ffe4e6; color: #9f1239; padding: 8px; font: 12px/1.4 Inter, ui-sans-serif, system-ui, sans-serif; }
`;
