import { renderAnnotations } from '@/content/annotations/renderer';
import { currentPageMetadata } from '@/content/reader/page-meta';
import { MarkerMessageType, type MarkerMessageResponse, type PageVisitedMessage } from '@/shared/messages';

try {
  const message: PageVisitedMessage = {
    type: MarkerMessageType.PageVisited,
    url: window.location.href,
    metadata: currentPageMetadata(),
  };
  void chrome.runtime.sendMessage(message).then((response: MarkerMessageResponse<PageVisitedMessage>) => {
    if (response?.annotations != null) {
      renderAnnotations(response.annotations);
    }
  });
} catch (error) {
  console.debug('Marker could not send page metadata.', error);
}

console.debug('Marker content runtime loaded.');
