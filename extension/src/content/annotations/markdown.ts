export function renderMarkdown(markdown: string): string {
  const escaped = escapeHtml(markdown);
  return escaped
    .split(/\n{2,}/)
    .map((paragraph) => `<p>${inlineMarkdown(paragraph).replace(/\n/g, '<br>')}</p>`)
    .join('');
}

function inlineMarkdown(value: string): string {
  return value
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\*([^*]+)\*/g, '<em>$1</em>')
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\[([^\]]+)]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2" target="_blank" rel="noreferrer noopener">$1</a>');
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
