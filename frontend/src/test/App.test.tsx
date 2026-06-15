import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { App } from "../App";

function jsonResponse(body: unknown, status = 200) {
  return Promise.resolve(
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    }),
  );
}

describe("Scope Drop app", () => {
  test("redirects an unauthenticated user to login and shows credential errors", async () => {
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ authenticated: false, csrf_token: "csrf" }))
      .mockImplementationOnce(() =>
        jsonResponse({ success: false, error: "invalid_credentials" }, 401),
      );

    render(
      <MemoryRouter initialEntries={["/sprints"]}>
        <App />
      </MemoryRouter>,
    );

    expect(await screen.findByRole("heading", { name: "Вход в сервис" })).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText("Логин"), "admin");
    await userEvent.type(screen.getByLabelText("Пароль"), "wrong");
    await userEvent.click(screen.getByRole("button", { name: "Войти" }));
    expect(await screen.findByText("Неверный логин или пароль")).toBeInTheDocument();
  });

  test("renders sprint list and runs manual synchronization", async () => {
    const fetchMock = vi
      .spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ authenticated: true, csrf_token: "csrf" }))
      .mockImplementationOnce(() =>
        jsonResponse({
          items: [
            {
              id: 1,
              name: "Sprint 24",
              start_date: "2026-06-01",
              end_date: "2026-06-14",
              archived: false,
              issues_count: 4,
              planned_sp: 10,
              completed_sp: 5,
              added_sp: 2,
              dropped_sp: 5,
              completion_rate: 50,
              scope_drop_rate: 50,
              scope_stability_index: 30,
            },
          ],
        }),
      )
      .mockImplementationOnce(() => jsonResponse({ status: "success" }))
      .mockImplementationOnce(() => jsonResponse({ items: [] }));

    render(
      <MemoryRouter initialEntries={["/sprints"]}>
        <App />
      </MemoryRouter>,
    );

    expect(await screen.findByText("Sprint 24")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: /Обновить данные/ }));
    expect(await screen.findByText("Данные YouTrack обновлены")).toBeInTheDocument();
    expect(fetchMock).toHaveBeenCalledWith(
      "/api/sync",
      expect.objectContaining({
        method: "POST",
        headers: expect.any(Headers),
      }),
    );
  });

  test("renders inferred scope warning and filtered issue sections", async () => {
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ authenticated: true, csrf_token: "csrf" }))
      .mockImplementationOnce(() =>
        jsonResponse({
          sprint: {
            id: 1,
            name: "Sprint 24",
            start_date: "2026-06-01",
            end_date: "2026-06-14",
            archived: false,
            initial_scope_inferred: true,
          },
          metrics: {
            planned_sp: 5,
            completed_sp: 0,
            added_sp: 3,
            dropped_sp: 5,
            remaining_sp: 0,
            completion_rate: 0,
            scope_drop_rate: 100,
            added_scope_rate: 60,
            scope_change_rate: 160,
            scope_stability_index: 0,
            issues_count: 0,
            without_estimation_count: 1,
          },
          developers: [],
          issues: [
            {
              id: 1,
              key: "SD-1",
              summary: "Unestimated",
              url: "https://example.test/SD-1",
              assignee_name: "Без исполнителя",
              status: "Open",
              estimation_be: null,
              has_estimation: false,
              is_initial_scope: true,
              is_added_after_start: false,
              is_removed_from_sprint: true,
              currently_in_sprint: false,
            },
            {
              id: 2,
              key: "SD-2",
              summary: "Added",
              url: "https://example.test/SD-2",
              assignee_name: "Ivan",
              status: "Open",
              estimation_be: 3,
              has_estimation: true,
              is_initial_scope: false,
              is_added_after_start: true,
              is_removed_from_sprint: false,
              currently_in_sprint: true,
            },
          ],
        }),
      );

    render(
      <MemoryRouter initialEntries={["/sprints/1"]}>
        <App />
      </MemoryRouter>,
    );

    expect(await screen.findByText(/Initial Scope определён/)).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Без оценки" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Добавлены после старта" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Снятые / выпавшие задачи" })).toBeInTheDocument();
    await waitFor(() => expect(screen.getAllByText("SD-1").length).toBeGreaterThan(1));
  });
});
