type Props = {
  message: string;
  onRetry?: () => void;
};

export function ErrorState({ message, onRetry }: Props) {
  return (
    <div className="error-state" role="alert">
      <strong>Не удалось загрузить данные</strong>
      <span>{message}</span>
      {onRetry && (
        <button className="button button--secondary" type="button" onClick={onRetry}>
          Повторить
        </button>
      )}
    </div>
  );
}
