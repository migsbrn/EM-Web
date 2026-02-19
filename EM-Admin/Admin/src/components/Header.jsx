import React, { useState, useEffect } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { getAuth, signOut, onAuthStateChanged } from "firebase/auth";
import { getFirestore, doc, onSnapshot } from "firebase/firestore";
import { auth } from "../firebase";
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import "../styles/Header.css";

const db = getFirestore();

const Header = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [activeLink, setActiveLink] = useState(location.pathname);
  const [currentPhoto, setCurrentPhoto] = useState(null);
  const [showConfirmModal, setShowConfirmModal] = useState(false);

  useEffect(() => {
    setActiveLink(location.pathname);
  }, [location.pathname]);

  useEffect(() => {
    const authInstance = getAuth();
    let snapshotUnsubscribe = () => {};

    const userUnsubscribe = onAuthStateChanged(authInstance, (currentUser) => {
      if (currentUser) {
        const adminDocRef = doc(db, "admins", currentUser.uid);

        snapshotUnsubscribe = onSnapshot(
          adminDocRef,
          (docSnapshot) => {
            if (docSnapshot.exists() && docSnapshot.data().profilePhotoBase64) {
              setCurrentPhoto(docSnapshot.data().profilePhotoBase64);
            } else {
              setCurrentPhoto(currentUser.photoURL || null);
            }
          },
          () => setCurrentPhoto(currentUser.photoURL || null),
        );
      } else {
        setCurrentPhoto(null);
        snapshotUnsubscribe();
      }
    });

    return () => {
      userUnsubscribe();
      snapshotUnsubscribe();
    };
  }, []);

  const handleLogoutClick = () => setShowConfirmModal(true);
  const confirmLogout = async () => {
    setShowConfirmModal(false);
    try {
      await signOut(auth);
      navigate("/login");
    } catch (error) {
      console.error("Logout error:", error);
    }
  };
  const cancelLogout = () => setShowConfirmModal(false);

  const DefaultPlaceholder = () => (
    <div className="profile-placeholder-header">
      <i className="fas fa-user"></i>
    </div>
  );

  const ConfirmationModal = () => (
    <div className="modal-backdrop">
      <div className="confirmation-modal">
        <h3>Confirm Sign Out</h3>
        <p>Are you sure you want to sign out of your admin account?</p>
        <div className="modal-actions">
          <button className="cancel-btn" onClick={cancelLogout}>
            Cancel
          </button>
          <button className="confirm-btn" onClick={confirmLogout}>
            Sign Out
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <>
      {/* Light Navbar (White Header) */}
      <nav className="navbar navbar-expand-lg navbar-light bg-light fixed-top shadow-sm p-3">
        <div className="container-fluid">
          {/* Added me-4 (margin-right: 4) for spacing */}
          <Link className="navbar-brand fw-bold me-5" to="/">
            Admin
          </Link>
          <button
            className="navbar-toggler border-0"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#navbarNav"
          >
            <span className="navbar-toggler-icon"></span>
          </button>

          <div className="collapse navbar-collapse" id="navbarNav">
            {/* The ms-auto on the ul will push the links to the right if they are not full width.
                Using me-auto keeps the links grouped together. */}
            <ul className="navbar-nav mx-auto mb-2 mb-lg-0">
              <li className="nav-item">
                <Link
                  to="/dashboard"
                  className={`nav-link ${
                    activeLink === "/dashboard" ? "active" : ""
                  }`}
                >
                  Dashboard
                </Link>
              </li>
              <li className="nav-item">
                <Link
                  to="/teacher-approval"
                  className={`nav-link ${
                    activeLink === "/teacher-approval" ? "active" : ""
                  }`}
                >
                  Teacher Account Approval
                </Link>
              </li>
              <li className="nav-item">
                <Link
                  to="/manage-teacher"
                  className={`nav-link ${
                    activeLink === "/manage-teacher" ? "active" : ""
                  }`}
                >
                  Manage Teacher
                </Link>
              </li>
              <li className="nav-item">
                <Link
                  to="/view-students"
                  className={`nav-link ${
                    activeLink === "/view-students" ? "active" : ""
                  }`}
                >
                  View Students
                </Link>
              </li>
              <li className="nav-item">
                <Link
                  to="/reports-logs"
                  className={`nav-link ${
                    activeLink === "/reports-logs" ? "active" : ""
                  }`}
                >
                  Reports/Logs
                </Link>
              </li>
              <li className="nav-item">
                <Link
                  to="/settings"
                  className={`nav-link ${
                    activeLink === "/settings" ? "active" : ""
                  }`}
                >
                  Settings
                </Link>
              </li>
            </ul>

            {/* Profile dropdown */}
            <div className="dropdown">
              <button
                className="btn btn-light d-flex align-items-center"
                type="button"
                id="profileDropdown"
                data-bs-toggle="dropdown"
              >
                {currentPhoto ? (
                  <img
                    src={currentPhoto}
                    className="profile-image"
                    alt="Admin Profile"
                  />
                ) : (
                  <DefaultPlaceholder />
                )}
              </button>
              <ul
                className="dropdown-menu dropdown-menu-end"
                aria-labelledby="profileDropdown"
              >
                <li>
                  <button
                    className="dropdown-item text-danger"
                    onClick={handleLogoutClick}
                  >
                    Sign Out
                  </button>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </nav>

      {showConfirmModal && <ConfirmationModal />}
    </>
  );
};

export default Header;
