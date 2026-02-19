// App.jsx
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import React, { useState, useEffect } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
  useNavigate,
  useLocation,
} from "react-router-dom";

import AdminLogin from "./AdminLogin";
import Dashboard from "./Dashboard";
import Header from "./Header";
import TeacherApproval from "./TeacherApproval";
import ManageTeacher from "./ManageTeacher";
import ViewStudents from "./ViewStudents";
import ReportLogs from "./ReportLogs";
import Settings from "./Settings";

import { auth } from "../firebase";
import { onAuthStateChanged, signOut } from "firebase/auth";

function App() {
  return (
    <Router>
      <AppRoutes />
    </Router>
  );
}

function AppRoutes() {
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setLoading(true);
      if (user) {
        try {
          const token = await user.getIdTokenResult();
          if (token.claims.role === "admin") {
            setIsAdmin(true);
            if (location.pathname === "/login" || location.pathname === "/") {
              navigate("/dashboard");
            }
          } else {
            await signOut(auth);
            setIsAdmin(false);
            navigate("/login");
          }
        } catch (err) {
          console.error("Admin claim error:", err);
          await signOut(auth);
          setIsAdmin(false);
          navigate("/login");
        }
      } else {
        setIsAdmin(false);
        if (location.pathname !== "/login") {
          navigate("/login");
        }
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, [navigate, location]);

  if (loading) return <div>Loading...</div>;

  return (
    <>
      {isAdmin && <Header />}
      <div className="app-container">
        <Routes>
          <Route path="/login" element={<AdminLogin />} />
          <Route
            path="/dashboard"
            element={isAdmin ? <Dashboard /> : <Navigate to="/login" />}
          />
          <Route
            path="/teacher-approval"
            element={isAdmin ? <TeacherApproval /> : <Navigate to="/login" />}
          />
          <Route
            path="/manage-teacher"
            element={isAdmin ? <ManageTeacher /> : <Navigate to="/login" />}
          />
          <Route
            path="/view-students"
            element={isAdmin ? <ViewStudents /> : <Navigate to="/login" />}
          />
          <Route
            path="/reports-logs"
            element={isAdmin ? <ReportLogs /> : <Navigate to="/login" />}
          />
          <Route
            path="/settings"
            element={isAdmin ? <Settings /> : <Navigate to="/login" />}
          />
          <Route path="*" element={<Navigate to="/login" />} />
        </Routes>
      </div>
    </>
  );
}

export default App;
