export type MetricSet = {
  planned_sp: number;
  completed_sp: number;
  added_sp: number;
  dropped_sp: number;
  remaining_sp: number;
  completion_rate: number;
  scope_drop_rate: number;
  added_scope_rate: number;
  scope_change_rate: number;
  scope_stability_index: number;
  issues_count: number;
  without_estimation_count: number;
};

export type SprintSummary = Pick<
  MetricSet,
  | "issues_count"
  | "planned_sp"
  | "completed_sp"
  | "added_sp"
  | "dropped_sp"
  | "completion_rate"
  | "scope_drop_rate"
  | "scope_stability_index"
> & {
  id: number;
  name: string;
  start_date: string | null;
  end_date: string | null;
  archived: boolean;
};

export type DeveloperMetrics = MetricSet & {
  assignee_name: string;
};

export type SprintIssue = {
  id: number;
  key: string;
  summary: string;
  url: string;
  assignee_name: string;
  status: string | null;
  estimation_be: number | null;
  has_estimation: boolean;
  is_initial_scope: boolean;
  is_added_after_start: boolean;
  is_removed_from_sprint: boolean;
  currently_in_sprint: boolean;
};

export type SprintDetail = {
  sprint: {
    id: number;
    name: string;
    start_date: string | null;
    end_date: string | null;
    archived: boolean;
    initial_scope_inferred: boolean;
  };
  metrics: MetricSet;
  developers: DeveloperMetrics[];
  issues: SprintIssue[];
};
