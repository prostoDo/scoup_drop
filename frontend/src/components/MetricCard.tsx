type Props = {
  label: string;
  value: string;
  tone?: "default" | "good" | "warn" | "bad";
  hint?: string;
};

export function MetricCard({ label, value, tone = "default", hint }: Props) {
  return (
    <article className={`metric-card metric-card--${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
      {hint && <small>{hint}</small>}
    </article>
  );
}
