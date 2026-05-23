import 'virtual:uno.css';
import { Match, Switch, type JSX } from 'solid-js';

export type IconKind =
  | 'book-open'
  | 'bookmark'
  | 'bookmark-plus'
  | 'check'
  | 'chevron-right'
  | 'download'
  | 'eye'
  | 'eye-off'
  | 'file-down'
  | 'file-up'
  | 'highlighter'
  | 'library'
  | 'link'
  | 'palette'
  | 'pencil'
  | 'settings'
  | 'shield-check'
  | 'trash-2'
  | 'upload';

export function Icon(props: { name: IconKind; class?: string }): JSX.Element {
  const className = (iconClass: string) => `icon ${iconClass} ${props.class ?? ''}`;

  return (
    <Switch>
      <Match when={props.name === 'book-open'}>
        <span class={className('i-lucide-book-open')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'bookmark'}>
        <span class={className('i-lucide-bookmark')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'bookmark-plus'}>
        <span class={className('i-lucide-bookmark-plus')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'check'}>
        <span class={className('i-lucide-check')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'chevron-right'}>
        <span class={className('i-lucide-chevron-right')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'download'}>
        <span class={className('i-lucide-download')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'eye'}>
        <span class={className('i-lucide-eye')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'eye-off'}>
        <span class={className('i-lucide-eye-off')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'file-down'}>
        <span class={className('i-lucide-file-down')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'file-up'}>
        <span class={className('i-lucide-file-up')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'highlighter'}>
        <span class={className('i-lucide-highlighter')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'library'}>
        <span class={className('i-lucide-library')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'link'}>
        <span class={className('i-lucide-link')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'palette'}>
        <span class={className('i-lucide-palette')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'pencil'}>
        <span class={className('i-lucide-pencil')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'settings'}>
        <span class={className('i-lucide-settings')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'shield-check'}>
        <span class={className('i-lucide-shield-check')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'trash-2'}>
        <span class={className('i-lucide-trash-2')} aria-hidden="true" />
      </Match>
      <Match when={props.name === 'upload'}>
        <span class={className('i-lucide-upload')} aria-hidden="true" />
      </Match>
    </Switch>
  );
}

export function IconLabel(props: { label: string }): JSX.Element {
  return <span class="sr-only">{props.label}</span>;
}
