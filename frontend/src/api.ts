import type { SprintDetail, SprintSummary } from "./types";

type AuthState = {
  authenticated: boolean;
  csrf_token: string;
};

type ApiErrorBody = {
  error?: string;
};

export class ApiError extends Error {
  status: number;
  code?: string;

  constructor(status: number, code?: string) {
    super(code || `HTTP ${status}`);
    this.status = status;
    this.code = code;
  }
}

let csrfToken = "";

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set("Accept", "application/json");
  if (init.body) headers.set("Content-Type", "application/json");
  if (csrfToken && !["GET", "HEAD"].includes(init.method || "GET")) {
    headers.set("X-CSRF-Token", csrfToken);
  }

  const response = await fetch(path, {
    ...init,
    headers,
    credentials: "same-origin",
  });

  const body = response.status === 204 ? null : await response.json();
  if (!response.ok) {
    throw new ApiError(response.status, (body as ApiErrorBody | null)?.error);
  }
  return body as T;
}

export async function getAuthState(): Promise<AuthState> {
  const state = await request<AuthState>("/api/auth/me");
  csrfToken = state.csrf_token;
  return state;
}

export async function login(loginValue: string, password: string): Promise<void> {
  await request("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ login: loginValue, password }),
  });
  await getAuthState();
}

export async function logout(): Promise<void> {
  await request("/api/auth/logout", { method: "POST" });
  await getAuthState();
}

export async function getSprints(): Promise<SprintSummary[]> {
  const response = await request<{ items: SprintSummary[] }>("/api/sprints");
  return response.items;
}

export function getSprint(id: string): Promise<SprintDetail> {
  return request<SprintDetail>(`/api/sprints/${id}`);
}

export function synchronize(): Promise<{ status: string }> {
  return request("/api/sync", { method: "POST" });
}
