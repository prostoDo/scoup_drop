import { Link, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../auth";

export function AppLayout() {
  const { signOut } = useAuth();
  const navigate = useNavigate();

  async function handleLogout() {
    await signOut();
    navigate("/login", { replace: true });
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <Link className="brand" to="/sprints">
          <span className="brand__mark">SD</span>
          <span>
            <strong>Scope Drop</strong>
            <small>YouTrack sprint health</small>
          </span>
        </Link>
        <button className="button button--ghost" type="button" onClick={handleLogout}>
          Выйти
        </button>
      </header>
      <main className="page-shell">
        <Outlet />
      </main>
    </div>
  );
}
