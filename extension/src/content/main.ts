import { cleanupRenderedAnnotations, renderAnnotations, scrollToAnnotation } from '@/content/annotations/renderer';
import { installAnnotationToolbar } from '@/content/annotations/toolbar';
import { currentPageMetadata } from '@/content/reader/page-meta';
import { MarkerMessageType, type MarkerMessageResponse, type PageVisitedMessage } from '@/shared/messages';

installAnnotationToolbar();
const visibilityStyle = document.createElement('style');
visibilityStyle.textContent = 'html[data-marker-annotations-hidden] .marker-annotation { background: transparent !important; text-decoration: none !important; }';
document.documentElement.append(visibilityStyle);
let annotationsVisible = true;

chrome.runtime.onMessage.addListener((message: unknown, _sender, sendResponse) => {
  if (typeof message !== 'object' || message == null || !('type' in message)) {
    return false;
  }

  const candidate = message as { type: unknown; annotationId?: unknown; visible?: unknown };

  if (candidate.type === MarkerMessageType.ScrollToAnnotation && typeof candidate.annotationId === 'string') {
    const ok = scrollToAnnotation(candidate.annotationId);
    sendResponse(ok ? { ok: true } : { ok: false, reason: 'Annotation is not visible on this page.' });
    return false;
  }

  if (candidate.type === MarkerMessageType.RemoveRenderedAnnotation && typeof candidate.annotationId === 'string') {
    cleanupRenderedAnnotations(candidate.annotationId);
    sendResponse({ ok: true });
    return false;
  }

  if (candidate.type === MarkerMessageType.SetAnnotationVisibility && typeof candidate.visible === 'boolean') {
    annotationsVisible = candidate.visible;
    document.documentElement.toggleAttribute('data-marker-annotations-hidden', !annotationsVisible);
    sendResponse({ ok: true });
    return false;
  }

  return false;
});

try {
  const message: PageVisitedMessage = {
    type: MarkerMessageType.PageVisited,
    url: window.location.href,
    metadata: currentPageMetadata(),
  };
  void chrome.runtime.sendMessage(message).then((response: MarkerMessageResponse<PageVisitedMessage>) => {
    if (response?.annotations != null && annotationsVisible) {
      renderAnnotations(response.annotations);
    }
  });
} catch (error) {
  console.debug('Marker could not send page metadata.', error);
}

console.debug('Marker content runtime loaded.');
