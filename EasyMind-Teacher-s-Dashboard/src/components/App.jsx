import "bootstrap/dist/css/bootstrap.min.css";
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import "../styles/App.css";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  NavLink,
  useLocation,
} from "react-router-dom";
import { useState, useEffect } from "react";
import { getAuth, signOut } from "firebase/auth";
import {
  getFirestore,
  doc,
  getDoc,
  setDoc,
  serverTimestamp,
} from "firebase/firestore";
import { app } from "../firebase";
import StudentList from "./StudentList.jsx";
import Contents from "./Contents.jsx";
import EditContent from "./Editc.jsx";
import TeacherLogin from "./TeacherLogin.jsx";
import Assessments from "./Assessments.jsx";
import UserProfile from "./UserProfile.jsx";
import Dashboard from "./Dashboard.jsx";
import Reports from "./Reports.jsx";
import StudentDetails from "./StudentDetails.jsx";
import BuiltInModules from "./BuiltInModules.jsx";

// Navbar Component with Dropdown
const Navbar = ({ isCollapsed, setIsCollapsed }) => {
  const [showDropdown, setShowDropdown] = useState(false);
  const [teacherProfileImage, setTeacherProfileImage] = useState(null);
  const auth = getAuth(app);
  const db = getFirestore(app);

  // Fetch teacher profile image
  useEffect(() => {
    const fetchTeacherProfile = async () => {
      try {
        const user = auth.currentUser;
        if (user) {
          // Try to get from teachers collection first
          const teacherDocRef = doc(db, "teachers", user.uid);
          const teacherDoc = await getDoc(teacherDocRef);
          
          if (teacherDoc.exists()) {
            const teacherData = teacherDoc.data();
            if (teacherData.profilePhoto) {
              setTeacherProfileImage(teacherData.profilePhoto);
              return;
            }
          }
          
          // If not found in teachers, try teacherRequests collection
          const teacherRequestDocRef = doc(db, "teacherRequests", user.uid);
          const teacherRequestDoc = await getDoc(teacherRequestDocRef);
          
          if (teacherRequestDoc.exists()) {
            const teacherRequestData = teacherRequestDoc.data();
            if (teacherRequestData.profilePhoto) {
              setTeacherProfileImage(teacherRequestData.profilePhoto);
              return;
            }
          }
        }
      } catch (error) {
        console.error("Error fetching teacher profile image:", error);
      }
    };

    fetchTeacherProfile();
  }, [auth.currentUser, db]);

  const toggleDropdown = () => {
    setShowDropdown(!showDropdown);
  };

  const toggleNavbar = () => {
    setIsCollapsed(!isCollapsed);
  };

  const handleSignOut = async () => {
    try {
      const user = auth.currentUser;
      if (user) {
        // Fetch the teacher's data from the teachers collection
        const userDocRef = doc(db, "teachers", user.uid);
        const userDoc = await getDoc(userDocRef);
        let teacherName = "Unnamed Teacher";

        if (userDoc.exists()) {
          const data = userDoc.data();
          console.log("Teacher data for logout:", data);
          teacherName = `${data.firstName || ""} ${data.lastName || ""}`.trim();
          if (!teacherName) {
            // Only fall back to username if name fields are truly empty
            teacherName =
              data.username || user.email.split("@")[0] || "Unnamed Teacher";
            console.log("Name fields missing, using fallback:", teacherName);
          }
        } else {
          console.error("Teacher document not found for UID:", user.uid);
          teacherName = user.email.split("@")[0] || "Unnamed Teacher";
        }

        // Log the sign-out event to Firestore
        await setDoc(doc(db, "logs", `${user.uid}_${Date.now()}`), {
          teacherName: teacherName,
          activityDescription: "Logged out",
          createdAt: serverTimestamp(),
        });
      } else {
        console.error("No authenticated user found during sign-out");
      }
      await signOut(auth);
      setShowDropdown(false);
    } catch (error) {
      console.error("Error during sign-out or logging to Firestore:", error);
    }
  };

  return (
    <nav className={`navbar navbar-expand-lg navbar-light ${isCollapsed ? 'navbar-collapsed' : ''}`}>
      <div className="container-fluid">
        {/* Toggle Button - Always shows hamburger icon */}
        <button
          className="navbar-toggle-btn"
          onClick={toggleNavbar}
          aria-label="Toggle navigation"
        >
          <i className="fas fa-bars"></i>
        </button>

        {/* Brand - Only show when not collapsed */}
        {!isCollapsed && (
          <NavLink to="/reports" className="navbar-brand">
            <i className="fas fa-graduation-cap me-2"></i>
            EasyMind
          </NavLink>
        )}

        {/* Navigation Menu - Only show when not collapsed */}
        {!isCollapsed && (
          <div className="navbar-collapse-content">
            <ul className="navbar-nav mx-auto">
              <li className="nav-item">
                <NavLink
                  className={({ isActive }) =>
                    isActive ? "nav-link active" : "nav-link"
                  }
                  to="/reports"
                >
                  <i className="fas fa-chart-bar me-1"></i>
                  Reports
                </NavLink>
              </li>
              <li className="nav-item">
                <NavLink
                  className={({ isActive }) =>
                    isActive ? "nav-link active" : "nav-link"
                  }
                  to="/student-list"
                >
                  <i className="fas fa-users me-1"></i>
                  Students
                </NavLink>
              </li>
              <li className="nav-item">
                <NavLink
                  className={({ isActive }) =>
                    isActive ? "nav-link active" : "nav-link"
                  }
                  to="/contents"
                >
                  <i className="fas fa-book me-1"></i>
                  Contents
                </NavLink>
              </li>
              <li className="nav-item">
                <NavLink
                  className={({ isActive }) =>
                    isActive ? "nav-link active" : "nav-link"
                  }
                  to="/assessments"
                >
                  <i className="fas fa-clipboard-check me-1"></i>
                  Assessments
                </NavLink>
              </li>
            </ul>

            {/* User Profile Dropdown */}
            <div className="d-flex align-items-center position-relative">
              {teacherProfileImage ? (
                <img
                  src={teacherProfileImage}
                  alt="Teacher Profile"
                  className="user-profile-img rounded-circle me-2"
                  style={{ cursor: "pointer" }}
                  onClick={toggleDropdown}
                />
              ) : (
                <div
                  className="user-profile-img rounded-circle me-2 d-flex align-items-center justify-content-center"
                  style={{ 
                    cursor: "pointer",
                    backgroundColor: "#6c757d",
                    color: "white",
                    fontSize: "1.2rem"
                  }}
                  onClick={toggleDropdown}
                >
                  <i className="fas fa-user"></i>
                </div>
              )}
              {showDropdown && (
                <div className="dropdown-menu show user-dropdown">
                  <NavLink
                    to="/profile"
                    className="dropdown-item"
                    onClick={() => setShowDropdown(false)}
                  >
                    <i className="fas fa-user me-2"></i>
                    Profile
                  </NavLink>
                  <NavLink to="/" className="dropdown-item" onClick={handleSignOut}>
                    <i className="fas fa-sign-out-alt me-2"></i>
                    Sign Out
                  </NavLink>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};

// Main App Component
function App() {
  const location = useLocation();
  const [isCollapsed, setIsCollapsed] = useState(false);

  return (
    <div>
      {location.pathname !== "/" && location.pathname !== "/profile" && (
        <Navbar isCollapsed={isCollapsed} setIsCollapsed={setIsCollapsed} />
      )}
      <Routes>
        <Route path="/" element={<TeacherLogin />} />
        <Route path="/teacher-dashboard" element={<Reports />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="/student-details/:studentId" element={<StudentDetails />} />
        <Route path="/student-list" element={<StudentList />} />
        <Route path="/students" element={<StudentList />} />
        <Route path="/contents" element={<Contents />} />
        <Route path="/built-in-modules" element={<BuiltInModules />} />
        <Route path="/assessments" element={<Assessments />} />
        <Route path="/edit-content/:id" element={<EditContent />} />
        <Route path="/profile" element={<UserProfile />} />
      </Routes>
    </div>
  );
}

// Wrap App with Router
export default function AppWrapper() {
  return (
    <Router>
      <App />
    </Router>
  );
}