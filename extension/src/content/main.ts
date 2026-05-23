import { currentPageMetadata } from '@/content/reader/page-meta';
import { MarkerMessageType } from '@/shared/messages';

try {
  void chrome.runtime.sendMessage({
    type: MarkerMessageType.PageVisited,
    url: window.location.href,
    metadata: currentPageMetadata(),
  });
} catch (error) {
  console.debug('Marker could not send page metadata.', error);
}

console.debug('Marker content runtime loaded.');
