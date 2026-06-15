import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { ApiError, getSprints, synchronize } from "../api";
import { ErrorState } from "../components/ErrorState";
import { LoadingState } from "../components/LoadingState";
import { formatDate, formatNumber, formatPercent, stabilityTone } from "../format";
import type { SprintSummary } from "../types";

export function SprintsPage() {
  const [sprints, setSprints] = useState<SprintSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  const load = useCallback(async () => {
    setError("");
    try {
      setSprints(await getSprints());
    } catch {
      setError("Проверьте соединение и попробуйте ещё раз.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function handleSync() {
    setSyncing(true);
    setNotice("");
    setError("");
    try {
      await synchronize();
      await load();
      setNotice("Данные YouTrack обновлены");
    } catch (reason) {
      setError(
        reason instanceof ApiError && reason.code === "sync_in_progress"
          ? "Синхронизация уже выполняется."
          : "YouTrack не ответил. Старые данные сохранены.",
      );
    } finally {
      setSyncing(false);
    }
  }

  if (loading) return <LoadingState />;

  return (
    <div className="page">
      <div className="page-heading">
        <div>
          <span className="eyebrow">ОБЗОР КОМАНДЫ</span>
          <h1>Спринты</h1>
          <p>План, выполнение и изменения объёма по данным YouTrack.</p>
        </div>
        <button className="button button--primary" onClick={handleSync} disabled={syncing}>
          <span className={syncing ? "sync-icon sync-icon--active" : "sync-icon"}>↻</span>
          {syncing ? "Обновляем…" : "Обновить данные"}
        </button>
      </div>

      {notice && <div className="notice notice--success">{notice}</div>}
      {error && <ErrorState message={error} onRetry={error.includes("соединение") ? load : undefined} />}

      {!error && sprints.length === 0 ? (
        <div className="empty-state">
          <strong>Спринтов пока нет</strong>
          <p>Запустите первую синхронизацию, чтобы получить данные YouTrack.</p>
        </div>
      ) : (
        <section className="panel">
          <div className="table-wrap">
            <table className="data-table sprint-table">
              <thead>
                <tr>
                  <th>Спринт</th>
                  <th>Период</th>
                  <th>Задачи</th>
                  <th>План</th>
                  <th>Готово</th>
                  <th>Добавлено</th>
                  <th>Выпало</th>
                  <th>Выполнение</th>
                  <th>Scope drop</th>
                  <th>Стабильность</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {sprints.map((sprint) => (
                  <tr key={sprint.id}>
                    <td>
                      <strong>{sprint.name}</strong>
                      {sprint.archived && <span className="muted-label">Архив</span>}
                    </td>
                    <td className="date-cell">
                      {formatDate(sprint.start_date)}
                      <span>— {formatDate(sprint.end_date)}</span>
                    </td>
                    <td>{sprint.issues_count}</td>
                    <td>{formatNumber(sprint.planned_sp)}</td>
                    <td>{formatNumber(sprint.completed_sp)}</td>
                    <td className="metric-positive">+{formatNumber(sprint.added_sp)}</td>
                    <td className="metric-negative">{formatNumber(sprint.dropped_sp)}</td>
                    <td>{formatPercent(sprint.completion_rate)}</td>
                    <td>{formatPercent(sprint.scope_drop_rate)}</td>
                    <td>
                      <span className={`stability stability--${stabilityTone(sprint.scope_stability_index)}`}>
                        {formatPercent(sprint.scope_stability_index)}
                      </span>
                    </td>
                    <td>
                      <Link className="arrow-link" to={`/sprints/${sprint.id}`} aria-label={`Открыть ${sprint.name}`}>
                        →
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}
