import { useCallback, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { getSprint } from "../api";
import { ErrorState } from "../components/ErrorState";
import { IssueTable } from "../components/IssueTable";
import { LoadingState } from "../components/LoadingState";
import { MetricCard } from "../components/MetricCard";
import { formatDate, formatNumber, formatPercent, stabilityTone } from "../format";
import type { SprintDetail } from "../types";

export function SprintDetailPage() {
  const { id = "" } = useParams();
  const [detail, setDetail] = useState<SprintDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setError("");
    try {
      setDetail(await getSprint(id));
    } catch {
      setError("Спринт не найден или сервис временно недоступен.");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    void load();
  }, [load]);

  if (loading) return <LoadingState />;
  if (error || !detail) return <ErrorState message={error} onRetry={load} />;

  const { sprint, metrics, developers, issues } = detail;
  const withoutEstimation = issues.filter((issue) => !issue.has_estimation);
  const added = issues.filter((issue) => issue.is_added_after_start);
  const removed = issues.filter((issue) => issue.is_removed_from_sprint);

  return (
    <div className="page">
      <Link className="back-link" to="/sprints">← Все спринты</Link>
      <div className="page-heading page-heading--detail">
        <div>
          <span className="eyebrow">КАРТОЧКА СПРИНТА</span>
          <h1>{sprint.name}</h1>
          <p>{formatDate(sprint.start_date)} — {formatDate(sprint.end_date)}</p>
        </div>
        <span className={`stability stability--large stability--${stabilityTone(metrics.scope_stability_index)}`}>
          Стабильность {formatPercent(metrics.scope_stability_index)}
        </span>
      </div>

      {sprint.initial_scope_inferred && (
        <div className="notice notice--warn">
          <strong>Initial Scope определён по первому snapshot.</strong>
          <span>Историческое состояние на дату старта недоступно.</span>
        </div>
      )}

      <section>
        <div className="section-heading">
          <h2>Метрики спринта</h2>
          <span>{metrics.issues_count} задач в текущем scope</span>
        </div>
        <div className="metric-grid">
          <MetricCard label="Planned SP" value={formatNumber(metrics.planned_sp)} hint="Initial scope" />
          <MetricCard label="Completed SP" value={formatNumber(metrics.completed_sp)} tone="good" />
          <MetricCard label="Added SP" value={`+${formatNumber(metrics.added_sp)}`} tone="warn" />
          <MetricCard label="Dropped SP" value={formatNumber(metrics.dropped_sp)} tone="bad" />
          <MetricCard label="Remaining SP" value={formatNumber(metrics.remaining_sp)} />
          <MetricCard label="Completion Rate" value={formatPercent(metrics.completion_rate)} tone="good" />
          <MetricCard label="Scope Drop Rate" value={formatPercent(metrics.scope_drop_rate)} tone="bad" />
          <MetricCard
            label="Scope Stability"
            value={formatPercent(metrics.scope_stability_index)}
            tone={stabilityTone(metrics.scope_stability_index)}
          />
          <MetricCard
            label="Без оценки"
            value={String(metrics.without_estimation_count)}
            tone={metrics.without_estimation_count > 0 ? "warn" : "default"}
          />
        </div>
      </section>

      <section className="panel">
        <div className="section-heading section-heading--inside">
          <div>
            <span className="eyebrow">РАСПРЕДЕЛЕНИЕ</span>
            <h2>Загрузка по разработчикам</h2>
          </div>
        </div>
        {developers.length === 0 ? (
          <div className="empty-inline">Нет данных по исполнителям.</div>
        ) : (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Разработчик</th>
                  <th>Задачи</th>
                  <th>План</th>
                  <th>Готово</th>
                  <th>Добавлено</th>
                  <th>Выпало</th>
                  <th>Осталось</th>
                  <th>Выполнение</th>
                </tr>
              </thead>
              <tbody>
                {developers.map((developer) => (
                  <tr key={developer.assignee_name}>
                    <td><strong>{developer.assignee_name}</strong></td>
                    <td>{developer.issues_count}</td>
                    <td>{formatNumber(developer.planned_sp)}</td>
                    <td>{formatNumber(developer.completed_sp)}</td>
                    <td className="metric-positive">+{formatNumber(developer.added_sp)}</td>
                    <td className="metric-negative">{formatNumber(developer.dropped_sp)}</td>
                    <td>{formatNumber(developer.remaining_sp)}</td>
                    <td>{formatPercent(developer.completion_rate)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="panel">
        <div className="section-heading section-heading--inside">
          <div>
            <span className="eyebrow">ПОЛНЫЙ СОСТАВ</span>
            <h2>Задачи спринта</h2>
          </div>
          <span>{issues.length} записей с учётом снятых</span>
        </div>
        <IssueTable issues={issues} emptyText="Задач в спринте нет." />
      </section>

      <div className="split-sections">
        <section className="panel">
          <div className="section-heading section-heading--inside">
            <h2>Без оценки</h2>
            <span className="count-badge count-badge--warn">{withoutEstimation.length}</span>
          </div>
          <IssueTable issues={withoutEstimation} emptyText="Все задачи оценены." compact />
        </section>
        <section className="panel">
          <div className="section-heading section-heading--inside">
            <h2>Добавлены после старта</h2>
            <span className="count-badge count-badge--info">{added.length}</span>
          </div>
          <IssueTable issues={added} emptyText="Scope не расширялся." compact />
        </section>
      </div>

      <section className="panel">
        <div className="section-heading section-heading--inside">
          <h2>Снятые / выпавшие задачи</h2>
          <span className="count-badge count-badge--bad">{removed.length}</span>
        </div>
        <IssueTable issues={removed} emptyText="Снятых задач нет." compact />
      </section>
    </div>
  );
}
