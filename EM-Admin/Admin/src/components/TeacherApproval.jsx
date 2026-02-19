import React, { useEffect, useState } from "react";
import {
  collection,
  query,
  where,
  onSnapshot,
  updateDoc,
  doc,
  serverTimestamp,
  addDoc,
} from "firebase/firestore";
import { auth, db } from "../firebase";
import { onAuthStateChanged } from "firebase/auth";
import "../styles/TeacherApproval.css";

// Assuming you have a way to call a cloud function or API endpoint for sending email.
const CALL_EMAIL_API = async (email, name, status) => {
  console.log(`[API Call] Attempting to send ${status} email to: ${email}`);
  // IMPORTANT: Replace this placeholder with your actual Cloud Function/API call!
  return new Promise((resolve) => setTimeout(resolve, 1000));
};

const TeacherApproval = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [updatingStatusIds, setUpdatingStatusIds] = useState([]);
  const [selectedTeacher, setSelectedTeacher] = useState(null);
  const [error, setError] = useState(null);
  const [showHistory, setShowHistory] = useState(false);
  const [historyTeachers, setHistoryTeachers] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [adminEmail, setAdminEmail] = useState("");
  const [notification, setNotification] = useState({
    message: null,
    type: null,
  });

  // NEW STATE: For bulk selection
  const [selectedTeacherIds, setSelectedTeacherIds] = useState([]);

  // NEW STATE: For approve/reject confirmation modal
  const [confirmModal, setConfirmModal] = useState({
    show: false,
    action: null, // "Approved" | "Rejected"
    teacherId: null, // single id or array of ids
    teacherName: "",
    isBulk: false,
  });

  const collectionName = "teacherRequests";

  // Utility to display notifications
  const showNotification = (message, type = "success") => {
    setNotification({ message, type });
    setTimeout(() => {
      setNotification({ message: null, type: null });
    }, 5000); // Hide after 5 seconds
  };

  useEffect(() => {
    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      if (user) {
        setAdminEmail(user.email || "Admin");
        user
          .getIdTokenResult(true)
          .then((idTokenResult) => {
            const role = idTokenResult.claims?.role || null;

            if (role !== "admin") {
              setError(
                "You do not have admin privileges to view teacher requests.",
              );
              setTeachers([]);
              setLoading(false);
              return;
            }

            setLoading(true);
            setError(null);
            const q = query(
              collection(db, collectionName),
              where("status", "==", "Pending"),
            );
            const unsubscribe = onSnapshot(
              q,
              (querySnapshot) => {
                const fetchedTeachers = querySnapshot.docs.map((doc) => ({
                  id: doc.id,
                  ...doc.data(),
                }));
                setTeachers(fetchedTeachers);
                setLoading(false);
              },
              (error) => {
                console.error("Error listening to teachers:", error);
                setError("Failed to load teachers. Please try again.");
                setLoading(false);
              },
            );
            return () => unsubscribe();
          })
          .catch((err) => {
            console.error("Error fetching token result:", err);
            setError("Failed to verify admin privileges.");
            setLoading(false);
          });
      } else {
        setError("Please sign in as an admin to view teacher requests.");
        setTeachers([]);
        setLoading(false);
      }
    });

    return () => unsubscribeAuth();
  }, []);

  const fetchHistoryTeachers = () => {
    setHistoryLoading(true);
    const q = query(
      collection(db, collectionName),
      where("status", "in", ["Approved", "Rejected", "Active"]),
    );
    const unsubscribe = onSnapshot(
      q,
      (querySnapshot) => {
        const fetchedHistoryTeachers = querySnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setHistoryTeachers(fetchedHistoryTeachers);
        setHistoryLoading(false);
      },
      (error) => {
        console.error("Error listening to history teachers:", error);
        showNotification("Failed to load history. Please try again.", "error");
        setHistoryLoading(false);
      },
    );
    return () => unsubscribe();
  };

  const formatDate = (dateValue) => {
    if (!dateValue) return "N/A";
    try {
      const date = dateValue?.toDate?.() || new Date(dateValue);
      return date.toLocaleDateString();
    } catch (error) {
      console.error("Error formatting date:", error, "Date value:", dateValue);
      return "Invalid Date";
    }
  };

  const getFullName = (teacher) => {
    return (
      `${teacher.firstName || ""} ${teacher.lastName || ""}`.trim() || "No Name"
    );
  };

  const logAdminAction = async (action, teacherName, type) => {
    try {
      await addDoc(collection(db, "adminActions"), {
        action: `${action} teacher ${teacherName}`,
        teacherName,
        adminEmail: adminEmail || "Admin",
        timestamp: serverTimestamp(),
        type: type.toLowerCase(),
      });
    } catch (error) {
      console.error("Error logging admin action:", error);
    }
  };

  const sendApprovalEmail = async (email, name) => {
    try {
      await CALL_EMAIL_API(email, name, "Approved");
      showNotification(
        `Approval email sent successfully to ${name}.`,
        "success",
      );
    } catch (error) {
      console.error("Error sending approval email:", error);
      showNotification(
        `Failed to send email to ${name}. Status updated, but notification failed.`,
        "error",
      );
    }
  };

  // NEW: Handle selection of a single teacher
  const handleSelectTeacher = (id) => {
    setSelectedTeacherIds((prev) =>
      prev.includes(id) ? prev.filter((tid) => tid !== id) : [...prev, id],
    );
  };

  // NEW: Handle selection of all visible teachers
  const handleSelectAll = () => {
    const allIds = sortedTeachers.map((t) => t.id);
    if (selectedTeacherIds.length === allIds.length && allIds.length > 0) {
      setSelectedTeacherIds([]); // Deselect all
    } else {
      setSelectedTeacherIds(allIds); // Select all
    }
  };

  // NEW: Bulk/Single status change handler
  const handleStatusChange = async (ids, newStatus) => {
    const idsToUpdate = Array.isArray(ids) ? ids : [ids];

    // Set loading state for all IDs being processed
    setUpdatingStatusIds((prev) => [...new Set([...prev, ...idsToUpdate])]);

    // Clear bulk selection bar if items are processed
    if (Array.isArray(ids)) {
      setSelectedTeacherIds([]);
    }

    let successfulUpdates = 0;
    let successfulEmails = 0;

    for (const id of idsToUpdate) {
      const teacher = teachers.find((t) => t.id === id);
      if (!teacher) continue;

      const teacherRef = doc(db, collectionName, id);
      const teacherName = getFullName(teacher);

      try {
        // Step 1: Update status to Approved/Rejected
        await updateDoc(teacherRef, {
          status: newStatus,
          updatedAt: serverTimestamp(),
        });
        await logAdminAction(newStatus, teacherName, newStatus.toLowerCase());

        // If Approved, transition immediately to Active
        if (newStatus === "Approved") {
          await updateDoc(teacherRef, {
            status: "Active",
            updatedAt: serverTimestamp(),
          });
          await logAdminAction("Activated", teacherName, "active");

          // Send Email Notification
          if (teacher.email) {
            await CALL_EMAIL_API(teacher.email, teacherName, "Approved");
            successfulEmails++;
          }
        }
        successfulUpdates++;
      } catch (error) {
        console.error(`Error updating status for ${teacherName}:`, error);
      } finally {
        // Remove from individual loading state
        setUpdatingStatusIds((prev) => prev.filter((tid) => tid !== id));
      }
    }

    if (successfulUpdates > 0) {
      const actionText =
        newStatus === "Approved" ? "Approved and Activated" : newStatus;
      showNotification(
        `${successfulUpdates} teacher(s) successfully ${actionText}. ${
          successfulEmails > 0 ? `(${successfulEmails} email(s) sent)` : ""
        }`,
        successfulUpdates === idsToUpdate.length ? "success" : "warning",
      );
    } else {
      showNotification(`Failed to process any requests.`, "error");
    }
  };

  // Open confirmation modal for single or bulk action
  const requestConfirm = (ids, action) => {
    const isBulk = Array.isArray(ids);
    const teacherName = isBulk
      ? `${ids.length} selected teacher${ids.length > 1 ? "s" : ""}`
      : getFullName(teachers.find((t) => t.id === ids) || {});

    setConfirmModal({
      show: true,
      action,
      teacherId: ids,
      teacherName,
      isBulk,
    });
  };

  const closeConfirmModal = () => {
    setConfirmModal({
      show: false,
      action: null,
      teacherId: null,
      teacherName: "",
      isBulk: false,
    });
  };

  const proceedWithAction = () => {
    handleStatusChange(confirmModal.teacherId, confirmModal.action);
    closeConfirmModal();
  };

  const handleMoreClick = (teacher) => {
    setSelectedTeacher(teacher);
  };

  const closeModal = () => {
    setSelectedTeacher(null);
  };

  const openHistoryModal = () => {
    setShowHistory(true);
    fetchHistoryTeachers();
  };

  const closeHistoryModal = () => {
    setShowHistory(false);
    setHistoryTeachers([]);
  };

  const filteredTeachers = teachers.filter((teacher) => {
    const fullName = getFullName(teacher).toLowerCase();
    const matchesSearch =
      fullName.includes(searchTerm.toLowerCase()) ||
      (teacher.email?.toLowerCase()?.includes(searchTerm.toLowerCase()) ??
        false) ||
      (teacher.contactNo?.includes(searchTerm) ?? false);
    return matchesSearch;
  });

  const sortedTeachers = [...filteredTeachers].sort((a, b) => {
    const aDate = a.createdAt?.toDate?.() || new Date(a.createdAt || 0);
    const bDate = b.createdAt?.toDate?.() || new Date(b.createdAt || 0);
    return bDate - aDate;
  });

  const sortedHistoryTeachers = [...historyTeachers].sort((a, b) => {
    const aDate = a.createdAt?.toDate?.() || new Date(a.createdAt || 0);
    const bDate = b.createdAt?.toDate?.() || new Date(b.createdAt || 0);
    return bDate - aDate;
  });

  const allSelected =
    selectedTeacherIds.length > 0 &&
    selectedTeacherIds.length === sortedTeachers.length;

  return (
    <div className="teacher-approval-container">
      <div className="teacher-approval-main">
        <div className="teacher-approval-content">
          <div className="teacher-approval-header-box">
            <h1 className="teacher-approval-header-main">
              Teacher Account Approval
            </h1>
            <p className="teacher-approval-header-sub">
              Pending applications requiring admin review.
            </p>
          </div>

          {notification.message && (
            <p className={`notification ${notification.type}`}>
              {notification.type === "error"
                ? "❌"
                : notification.type === "warning"
                  ? "⚠️"
                  : "✅"}{" "}
              {notification.message}
            </p>
          )}

          {error && <p className="error">{error}</p>}

          <div className="teacher-approval-controls">
            <input
              type="text"
              placeholder="Search by Name, Email, or Contact..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="teacher-approval-search-bar"
            />
            <button className="history-button" onClick={openHistoryModal}>
              <i className="fas fa-history"></i> History
            </button>
          </div>

          <div className="teacher-approval-table-container">
            {/* FLOATING BULK ACTION BAR */}
            {selectedTeacherIds.length > 0 && (
              <div className="bulk-action-bar">
                <span className="bulk-action-count">
                  {selectedTeacherIds.length} Selected
                </span>
                <button
                  className="bulk-action-approve"
                  onClick={() => requestConfirm(selectedTeacherIds, "Approved")}
                  disabled={updatingStatusIds.length > 0}
                >
                  <i className="fas fa-check"></i> Approve Selected
                </button>
                <button
                  className="bulk-action-reject"
                  onClick={() => requestConfirm(selectedTeacherIds, "Rejected")}
                  disabled={updatingStatusIds.length > 0}
                >
                  <i className="fas fa-times"></i> Reject Selected
                </button>
              </div>
            )}

            {loading ? (
              <p>Loading teachers...</p>
            ) : sortedTeachers.length > 0 ? (
              <>
                {/* ── Desktop table (hidden on mobile via CSS) ── */}
                <div className="teacher-approval-table-wrapper">
                  <table className="teacher-approval-table">
                    <thead>
                      <tr>
                        <th>
                          <input
                            type="checkbox"
                            checked={allSelected}
                            onChange={handleSelectAll}
                            disabled={sortedTeachers.length === 0}
                          />
                        </th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Registration Date</th>
                        <th>Action</th>
                        <th>Details</th>
                      </tr>
                    </thead>
                    <tbody>
                      {sortedTeachers.map((teacher) => {
                        const isSelected = selectedTeacherIds.includes(
                          teacher.id,
                        );
                        const isUpdating = updatingStatusIds.includes(
                          teacher.id,
                        );
                        return (
                          <tr
                            key={teacher.id}
                            className={
                              isUpdating
                                ? "is-updating"
                                : isSelected
                                  ? "is-selected"
                                  : ""
                            }
                          >
                            <td>
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => handleSelectTeacher(teacher.id)}
                                disabled={isUpdating}
                              />
                            </td>
                            <td>{getFullName(teacher)}</td>
                            <td>{teacher.email || "N/A"}</td>
                            <td>{formatDate(teacher.createdAt)}</td>
                            <td>
                              <div className="action-buttons">
                                <button
                                  className="action-approve-btn"
                                  onClick={() =>
                                    requestConfirm(teacher.id, "Approved")
                                  }
                                  disabled={isUpdating}
                                >
                                  {isUpdating ? (
                                    "Processing..."
                                  ) : (
                                    <>
                                      <i className="fas fa-check"></i> Approve
                                    </>
                                  )}
                                </button>
                                <button
                                  className="action-reject-btn"
                                  onClick={() =>
                                    requestConfirm(teacher.id, "Rejected")
                                  }
                                  disabled={isUpdating}
                                >
                                  {isUpdating ? (
                                    "Processing..."
                                  ) : (
                                    <>
                                      <i className="fas fa-times"></i> Reject
                                    </>
                                  )}
                                </button>
                              </div>
                            </td>
                            <td>
                              <button
                                className="more-button"
                                onClick={() => handleMoreClick(teacher)}
                              >
                                <i className="fas fa-info-circle"></i> More
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>

                {/* ── Mobile card list (hidden on desktop via CSS) ── */}
                <div className="ta-card-list">
                  {sortedTeachers.map((teacher) => {
                    const isSelected = selectedTeacherIds.includes(teacher.id);
                    const isUpdating = updatingStatusIds.includes(teacher.id);
                    return (
                      <div
                        key={teacher.id}
                        className={`ta-card${isSelected ? " is-selected" : ""}${isUpdating ? " is-updating" : ""}`}
                      >
                        <div className="ta-card-top">
                          <input
                            type="checkbox"
                            className="ta-card-checkbox"
                            checked={isSelected}
                            onChange={() => handleSelectTeacher(teacher.id)}
                            disabled={isUpdating}
                          />
                          <span className="ta-card-name">
                            {getFullName(teacher)}
                          </span>
                          <span className="ta-card-date">
                            {formatDate(teacher.createdAt)}
                          </span>
                        </div>

                        <div className="ta-card-row">
                          <span className="ta-card-label">Email</span>
                          <span className="ta-card-value">
                            {teacher.email || "N/A"}
                          </span>
                        </div>

                        <div className="ta-card-actions">
                          <button
                            className="action-approve-btn"
                            onClick={() =>
                              requestConfirm(teacher.id, "Approved")
                            }
                            disabled={isUpdating}
                          >
                            {isUpdating ? (
                              "Processing..."
                            ) : (
                              <>
                                <i className="fas fa-check"></i> Approve
                              </>
                            )}
                          </button>
                          <button
                            className="action-reject-btn"
                            onClick={() =>
                              requestConfirm(teacher.id, "Rejected")
                            }
                            disabled={isUpdating}
                          >
                            {isUpdating ? (
                              "Processing..."
                            ) : (
                              <>
                                <i className="fas fa-times"></i> Reject
                              </>
                            )}
                          </button>
                          <button
                            className="more-button"
                            onClick={() => handleMoreClick(teacher)}
                          >
                            <i className="fas fa-info-circle"></i> More
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </>
            ) : (
              <p>No pending teachers found.</p>
            )}
          </div>

          {selectedTeacher && (
            <div className="modal" onClick={closeModal}>
              <div
                className="modal-content"
                onClick={(e) => e.stopPropagation()}
              >
                <div className="modal-header">
                  <h2>Teacher Details - {getFullName(selectedTeacher)}</h2>
                  <span className="close-icon" onClick={closeModal}>
                    ×
                  </span>
                </div>
                <div className="modal-body">
                  <div className="teacher-info-grid">
                    {/* General Information Card */}
                    <div className="info-card">
                      <h3 className="card-header">
                        <i className="fas fa-id-badge card-icon"></i>
                        Personal Information
                      </h3>
                      <div className="card-content">
                        <div className="card-item">
                          <span className="item-label">Full Name:</span>
                          <span className="item-value highlight">
                            {getFullName(selectedTeacher)}
                          </span>
                        </div>
                        <div className="card-item">
                          <span className="item-label">Email:</span>
                          <span className="item-value">
                            {selectedTeacher.email || "N/A"}
                          </span>
                        </div>
                        <div className="card-item">
                          <span className="item-label">Contact No:</span>
                          <span className="item-value">
                            {selectedTeacher.contactNo || "N/A"}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Professional Details Card (Renamed/Restyled) */}
                    <div className="info-card">
                      <h3 className="card-header">
                        <i className="fas fa-chalkboard-teacher card-icon"></i>
                        Professional Details
                      </h3>
                      <div className="card-content">
                        <div className="card-item">
                          <span className="item-label">Qualification:</span>
                          <span className="item-value">
                            {selectedTeacher.qualification || "N/A"}
                          </span>
                        </div>
                        {/* REMOVED: School/Institution Row as per user request */}
                        {/* REMOVED: Subject Row as per user request */}
                      </div>
                    </div>

                    {/* System Info Card */}
                    <div className="info-card system-info-card">
                      <h3 className="card-header">
                        <i className="fas fa-microchip card-icon"></i>
                        System Info
                      </h3>
                      <div className="card-content">
                        <div className="card-item">
                          <span className="item-label">Registered At:</span>
                          <span className="item-value">
                            {formatDate(selectedTeacher.createdAt)}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {showHistory && (
            <div className="modal" onClick={closeHistoryModal}>
              <div
                className="modal-content history-modal-content"
                onClick={(e) => e.stopPropagation()}
              >
                <div className="modal-header">
                  <h2>History</h2>
                  <span className="close-icon" onClick={closeHistoryModal}>
                    ×
                  </span>
                </div>
                <div className="modal-body">
                  {historyLoading ? (
                    <p>Loading history...</p>
                  ) : sortedHistoryTeachers.length > 0 ? (
                    <div className="history-table-wrapper">
                      <table className="teacher-approval-table">
                        <thead>
                          <tr>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Status</th>
                            <th>Date</th>
                          </tr>
                        </thead>
                        <tbody>
                          {sortedHistoryTeachers.map((teacher) => (
                            <tr key={teacher.id}>
                              <td>{getFullName(teacher)}</td>
                              <td>{teacher.email || "N/A"}</td>
                              <td>{teacher.status || "N/A"}</td>
                              <td>
                                {formatDate(
                                  teacher.updatedAt || teacher.createdAt,
                                )}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <p>No history found.</p>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ── Approve / Reject Confirmation Modal ── */}
      {confirmModal.show && (
        <div className="confirm-modal" onClick={closeConfirmModal}>
          <div
            className="confirm-modal-content"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="confirm-modal-icon">
              <div
                className={`confirm-modal-icon-circle ${confirmModal.action === "Approved" ? "approve" : "reject"}`}
              >
                {confirmModal.action === "Approved" ? "✅" : "❌"}
              </div>
            </div>

            <div className="confirm-modal-body">
              <h3>
                {confirmModal.action === "Approved"
                  ? "Approve Teacher Account"
                  : "Reject Teacher Account"}
              </h3>
              <p>
                Are you sure you want to{" "}
                <strong>
                  {confirmModal.action === "Approved" ? "approve" : "reject"}
                </strong>{" "}
                the account of{" "}
                <span className="confirm-teacher-name">
                  {confirmModal.teacherName}
                </span>
                ?
                {confirmModal.action === "Approved" && (
                  <> The teacher will be notified and granted access.</>
                )}
                {confirmModal.action === "Rejected" && (
                  <> This action cannot be easily undone.</>
                )}
              </p>
            </div>

            <div className="confirm-modal-footer">
              <button
                className="confirm-cancel-btn"
                onClick={closeConfirmModal}
              >
                Cancel
              </button>
              <button
                className={
                  confirmModal.action === "Approved"
                    ? "confirm-proceed-approve"
                    : "confirm-proceed-reject"
                }
                onClick={proceedWithAction}
              >
                {confirmModal.action === "Approved"
                  ? "Yes, Approve"
                  : " Yes, Reject"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TeacherApproval;
