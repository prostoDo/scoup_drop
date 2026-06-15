import { Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, ProtectedRoute } from "./auth";
import { AppLayout } from "./components/AppLayout";
import { LoginPage } from "./pages/LoginPage";
import { SprintDetailPage } from "./pages/SprintDetailPage";
import { SprintsPage } from "./pages/SprintsPage";

export function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          element={
            <ProtectedRoute>
              <AppLayout />
            </ProtectedRoute>
          }
        >
          <Route path="/sprints" element={<SprintsPage />} />
          <Route path="/sprints/:id" element={<SprintDetailPage />} />
        </Route>
        <Route path="*" element={<Navigate to="/sprints" replace />} />
      </Routes>
    </AuthProvider>
  );
}
