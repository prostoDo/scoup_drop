export function formatNumber(value: number): string {
  return new Intl.NumberFormat("ru-RU", { maximumFractionDigits: 2 }).format(value);
}

export function formatPercent(value: number): string {
  return `${formatNumber(value)}%`;
}

export function formatDate(value: string | null): string {
  if (!value) return "—";
  return new Intl.DateTimeFormat("ru-RU", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(`${value}T00:00:00`));
}

export function stabilityTone(value: number): "good" | "warn" | "bad" {
  if (value >= 85) return "good";
  if (value >= 70) return "warn";
  return "bad";
}
