import { useState, type FormEvent } from "react";
import { Navigate, useLocation, useNavigate } from "react-router-dom";
import { ApiError } from "../api";
import { useAuth } from "../auth";

export function LoginPage() {
  const { authenticated, signIn } = useAuth();
  const [login, setLogin] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  if (authenticated) return <Navigate to="/sprints" replace />;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError("");
    try {
      await signIn(login, password);
      const destination = (location.state as { from?: string } | null)?.from || "/sprints";
      navigate(destination, { replace: true });
    } catch (reason) {
      setError(
        reason instanceof ApiError && reason.code === "invalid_credentials"
          ? "Неверный логин или пароль"
          : "Сервис временно недоступен",
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="login-page">
      <section className="login-visual">
        <div className="login-visual__content">
          <span className="eyebrow">SPRINT INTELLIGENCE</span>
          <h1>Видно, где спринт теряет фокус.</h1>
          <p>
            План, фактическое выполнение и изменения scope — в одном спокойном,
            честном представлении.
          </p>
          <div className="signal-card">
            <span>Scope stability</span>
            <strong>82%</strong>
            <div className="signal-line">
              <i />
            </div>
          </div>
        </div>
      </section>
      <section className="login-panel">
        <form className="login-card" onSubmit={handleSubmit}>
          <div className="brand brand--login">
            <span className="brand__mark">SD</span>
            <span><strong>Scope Drop</strong></span>
          </div>
          <div>
            <span className="eyebrow">ДОБРО ПОЖАЛОВАТЬ</span>
            <h2>Вход в сервис</h2>
            <p>Используйте общие данные доступа вашей команды.</p>
          </div>
          <label>
            <span>Логин</span>
            <input
              autoComplete="username"
              value={login}
              onChange={(event) => setLogin(event.target.value)}
              required
            />
          </label>
          <label>
            <span>Пароль</span>
            <input
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
            />
          </label>
          {error && <div className="form-error" role="alert">{error}</div>}
          <button className="button button--primary button--wide" disabled={submitting}>
            {submitting ? "Входим…" : "Войти"}
          </button>
        </form>
      </section>
    </main>
  );
}
