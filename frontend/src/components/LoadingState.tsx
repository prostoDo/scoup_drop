type Props = {
  label?: string;
  fullPage?: boolean;
};

export function LoadingState({ label = "Загружаем данные", fullPage = false }: Props) {
  return (
    <div className={fullPage ? "state state--full" : "state"}>
      <span className="spinner" aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}
