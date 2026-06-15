import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type PropsWithChildren,
} from "react";
import { Navigate, useLocation } from "react-router-dom";
import * as api from "./api";
import { LoadingState } from "./components/LoadingState";

type AuthContextValue = {
  authenticated: boolean;
  signIn: (login: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: PropsWithChildren) {
  const [authenticated, setAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .getAuthState()
      .then((state) => setAuthenticated(state.authenticated))
      .finally(() => setLoading(false));
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      authenticated,
      signIn: async (login, password) => {
        await api.login(login, password);
        setAuthenticated(true);
      },
      signOut: async () => {
        await api.logout();
        setAuthenticated(false);
      },
    }),
    [authenticated],
  );

  if (loading) return <LoadingState label="Проверяем сессию" fullPage />;

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used inside AuthProvider");
  return context;
}

export function ProtectedRoute({ children }: PropsWithChildren) {
  const { authenticated } = useAuth();
  const location = useLocation();

  if (!authenticated) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }

  return children;
}
