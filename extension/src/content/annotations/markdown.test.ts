import { describe, expect, it } from 'vitest';
import { renderMarkdown } from './markdown';

describe('renderMarkdown', () => {
  it('renders simple markdown and sanitizes unsafe html', () => {
    expect(renderMarkdown('**bold** <script>alert(1)</script> [site](https://example.com)')).toBe(
      '<p><strong>bold</strong> &lt;script&gt;alert(1)&lt;/script&gt; <a href="https://example.com" target="_blank" rel="noreferrer noopener">site</a></p>',
    );
  });
});
