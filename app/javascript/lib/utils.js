// Utils for ShadCN UI components
export function cn(...classes) {
  return classes.filter(Boolean).join(' ');
}
