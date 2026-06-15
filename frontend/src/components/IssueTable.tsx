import type { SprintIssue } from "../types";
import { formatNumber } from "../format";

type Props = {
  issues: SprintIssue[];
  emptyText: string;
  compact?: boolean;
};

export function IssueTable({ issues, emptyText, compact = false }: Props) {
  if (issues.length === 0) return <div className="empty-inline">{emptyText}</div>;

  return (
    <div className="table-wrap">
      <table className={compact ? "data-table data-table--compact" : "data-table"}>
        <thead>
          <tr>
            <th>Задача</th>
            <th>Исполнитель</th>
            <th>Статус</th>
            <th>Оценка BE</th>
            {!compact && <th>Признаки</th>}
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) => (
            <tr key={issue.id}>
              <td>
                <a className="issue-link" href={issue.url} target="_blank" rel="noreferrer">
                  <strong>{issue.key}</strong>
                  <span>{issue.summary}</span>
                </a>
              </td>
              <td>{issue.assignee_name}</td>
              <td>
                <span className="status-pill">{issue.status || "Без статуса"}</span>
              </td>
              <td>{issue.has_estimation ? formatNumber(issue.estimation_be || 0) : "—"}</td>
              {!compact && (
                <td>
                  <div className="tag-list">
                    {!issue.has_estimation && <span className="tag tag--warn">Без оценки</span>}
                    {issue.is_added_after_start && <span className="tag tag--info">Добавлена</span>}
                    {issue.is_removed_from_sprint && <span className="tag tag--bad">Снята</span>}
                    {!issue.currently_in_sprint && !issue.is_removed_from_sprint && (
                      <span className="tag">Вне спринта</span>
                    )}
                  </div>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
