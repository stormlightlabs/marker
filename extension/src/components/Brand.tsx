export function Brand(props: { label: string }) {
  return (
    <div class="brand-lockup" aria-label={props.label}>
      {/* TODO: we'll want to replace this with an icon eventually */}
      <span class="brand-mark" aria-hidden="true">
        M
      </span>
      <span class="wordmark wordmark--large">Marker</span>
    </div>
  );
}
