import type { JSX } from 'solid-js';
import { Icon, IconLabel, type IconKind } from '@/components/Icon';

export type IconButtonProps = JSX.ButtonHTMLAttributes<HTMLButtonElement> & {
  icon: IconKind;
  label: string;
  visibleLabel?: string;
};

export function IconButton(props: IconButtonProps): JSX.Element {
  const visibleLabel = () => props.visibleLabel ?? props.label;
  return (
    <button {...props} title={props.title ?? props.label}>
      <Icon name={props.icon} />
      <span aria-hidden="true">{visibleLabel()}</span>
      <IconLabel label={props.label} />
    </button>
  );
}
