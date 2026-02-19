import React, { useEffect, useState } from "react";
import {
  collection,
  getDocs,
  query,
  where,
  doc,
  updateDoc,
  serverTimestamp,
  addDoc,
} from "firebase/firestore";
import { db, auth } from "../firebase";
import { onAuthStateChanged } from "firebase/auth";
import "../styles/ManageTeacher.css";

// Updated Status Constant
const STATUSES = ["All", "Active", "Inactive"];
const INITIAL_STATUS_COUNTS = {
  All: 0,
  Active: 0,
  Inactive: 0,
};

const ManageTeacher = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [filter, setFilter] = useState("All");
  const [teachers, setTeachers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTeacher, setSelectedTeacher] = useState(null);
  const [error, setError] = useState(null);
  const [adminEmail, setAdminEmail] = useState("");
  const [statusCounts, setStatusCounts] = useState(INITIAL_STATUS_COUNTS);

  // Pagination State
  const [currentPage, setCurrentPage] = useState(1);
  const teachersPerPage = 10;

  // Confirmation modal state
  const [statusChangePending, setStatusChangePending] = useState(null);
  const [showStatusModal, setShowStatusModal] = useState(false);

  const fetchTeachers = async () => {
    setLoading(true);
    try {
      // Query only Active and Inactive teachers
      const q = query(
        collection(db, "teacherRequests"),
        where("status", "in", ["Active", "Inactive"]),
      );

      const querySnapshot = await getDocs(q);
      const fetchedTeachers = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        // Mock Last Login Date for demonstration
        lastLogin:
          doc.data().lastLogin ||
          (doc.data().status === "Active"
            ? new Date(Date.now() - Math.random() * 86400000 * 30).toISOString()
            : null),
      }));

      // Calculate status counts for filter chips
      const newCounts = { ...INITIAL_STATUS_COUNTS };
      newCounts.All = fetchedTeachers.length;
      fetchedTeachers.forEach((t) => {
        if (newCounts.hasOwnProperty(t.status)) {
          newCounts[t.status]++;
        }
      });
      setStatusCounts(newCounts);
      setTeachers(fetchedTeachers);
    } catch (error) {
      console.error("Error fetching teachers:", error);
      setError("Failed to load teachers. Please try again.");
    } finally {
      setLoading(false);
    }
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
              setError("You do not have admin privileges to manage teachers.");
              setTeachers([]);
              setLoading(false);
              return;
            }
            fetchTeachers();
          })
          .catch((err) => {
            console.error("Error fetching token result:", err);
            setError("Failed to verify admin privileges.");
            setLoading(false);
          });
      } else {
        setError("Please sign in as an admin to manage teachers.");
        setTeachers([]);
        setLoading(false);
      }
    });

    return () => unsubscribeAuth();
  }, [filter]);

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

  const handleStatusChange = (id, newStatus, actionType) => {
    const teacher = teachers.find((t) => t.id === id);
    if (!teacher) return;

    const teacherName = getFullName(teacher);

    if (actionType === "status") {
      // Only allow status change between Active and Inactive
      if (newStatus === "Active" || newStatus === "Inactive") {
        setStatusChangePending({ id, newStatus, teacherName });
        setShowStatusModal(true);
      }
    }
  };

  const confirmStatusChange = async () => {
    if (!statusChangePending) return;

    const { id, newStatus, teacherName } = statusChangePending;
    try {
      const teacherRef = doc(db, "teacherRequests", id);
      await updateDoc(teacherRef, {
        status: newStatus,
        updatedAt: serverTimestamp(),
      });

      // Update local state to reflect change and recalculate counts
      await fetchTeachers(); // Rerun fetch to update counts accurately and refresh data

      await logAdminAction(
        newStatus === "Active" ? "Activated" : "Deactivated",
        teacherName,
        newStatus.toLowerCase(),
      );
    } catch (error) {
      console.error("Error updating status:", error);
      alert("Failed to update status. Try again.");
    } finally {
      setStatusChangePending(null);
      setShowStatusModal(false);
    }
  };

  const cancelStatusChange = () => {
    setStatusChangePending(null);
    setShowStatusModal(false);
  };

  const formatDate = (dateValue) => {
    if (!dateValue) return "N/A";
    try {
      const date = dateValue?.toDate?.() || new Date(dateValue);
      // For mock 'lastLogin' ISO string, date objects, or simple string dates like DOB
      if (
        typeof dateValue === "string" &&
        (dateValue.includes("T") || dateValue.match(/^\d{4}-\d{2}-\d{2}$/))
      ) {
        return new Date(dateValue).toLocaleDateString();
      }
      return date.toLocaleDateString();
    } catch (error) {
      return "Invalid Date";
    }
  };

  const getFullName = (teacher) =>
    `${teacher.firstName || ""} ${teacher.lastName || ""}`.trim() || "No Name";

  const handleMoreClick = (teacher) => setSelectedTeacher(teacher);
  const closeModal = () => setSelectedTeacher(null);

  const handleFilterChange = (e) => {
    setFilter(e.target.value);
    setCurrentPage(1); // Reset to first page on filter change
  };

  const filteredTeachers = teachers
    .filter((t) => {
      const fullName = getFullName(t).toLowerCase().trim();
      const qualification = t.qualification?.toLowerCase()?.trim() || "";
      const lowerSearchTerm = searchTerm.toLowerCase();

      const matchesSearch =
        fullName.includes(lowerSearchTerm) ||
        (t.email?.toLowerCase()?.includes(lowerSearchTerm) ?? false) ||
        (t.contactNo?.includes(lowerSearchTerm) ?? false) ||
        qualification.includes(lowerSearchTerm);

      const matchesFilter = filter === "All" || t.status === filter;

      return matchesFilter && matchesSearch;
    })
    .sort((a, b) => {
      // Sort by registration date descending
      const aDate = a.createdAt?.toDate?.() || new Date(a.createdAt || 0);
      const bDate = b.createdAt?.toDate?.() || new Date(b.createdAt || 0);
      return bDate - aDate;
    });

  // Pagination Logic
  const indexOfLastTeacher = currentPage * teachersPerPage;
  const indexOfFirstTeacher = indexOfLastTeacher - teachersPerPage;
  const currentTeachers = filteredTeachers.slice(
    indexOfFirstTeacher,
    indexOfLastTeacher,
  );
  const totalPages = Math.ceil(filteredTeachers.length / teachersPerPage);

  const paginate = (pageNumber) => setCurrentPage(pageNumber);
  const prevPage = () => setCurrentPage((prev) => Math.max(1, prev - 1));
  const nextPage = () =>
    setCurrentPage((prev) => Math.min(totalPages, prev + 1));
  // End Pagination Logic

  return (
    <div className="main-teacher-management">
      <div className="main-content">
        <div className="page-header">
          <h1 className="teacher-management-title">Manage Teachers</h1>
          <p className="teacher-management-subtitle">
            View, filter, and manage teacher account statuses.
          </p>
        </div>
        {error && <p className="error">{error}</p>}
        <div className="teacher-controls-manage">
          <input
            type="text"
            placeholder="Search Name, Email, Contact, or Qualification..."
            value={searchTerm}
            onChange={(e) => {
              setSearchTerm(e.target.value);
              setCurrentPage(1); // Reset to first page on search
            }}
            className="teacher-approval-search-bar"
          />
          {/* Filter Dropdown */}
          <select
            value={filter}
            onChange={handleFilterChange}
            className="filter-dropdown"
          >
            {STATUSES.map((status) => (
              <option key={status} value={status}>
                {status} ({statusCounts[status]})
              </option>
            ))}
          </select>
        </div>

        <div className="teacher-table-container" data-filter={filter}>
          {loading ? (
            <p>Loading teachers...</p>
          ) : filteredTeachers.length === 0 ? (
            <p>
              No {filter !== "All" ? filter.toLowerCase() : "matching"} teachers
              found.
            </p>
          ) : (
            <>
              <table className="teacher-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Last Login</th>
                    <th>Status</th>
                    <th>Actions</th>
                    <th>Details</th>
                  </tr>
                </thead>
                <tbody>
                  {currentTeachers.map((teacher) => (
                    <tr key={teacher.id}>
                      <td>{getFullName(teacher)}</td>
                      <td>{teacher.email || "N/A"}</td>
                      <td>
                        {teacher.lastLogin
                          ? formatDate(teacher.lastLogin)
                          : "N/A"}
                      </td>
                      <td>
                        {/* Status Pill */}
                        <span
                          className={`status-pill ${teacher.status.toLowerCase()}`}
                        >
                          {teacher.status || "N/A"}
                        </span>
                      </td>
                      <td>
                        {/* Actions Dropdown (Only Active/Inactive) */}
                        <select
                          value=""
                          onChange={(e) =>
                            handleStatusChange(
                              teacher.id,
                              e.target.value,
                              e.target.options[e.target.selectedIndex].dataset
                                .action,
                            )
                          }
                          className="teacher-actions-select"
                        >
                          <option value="" disabled>
                            Change Status
                          </option>
                          {/* Status Change Options - Exclude current status */}
                          {teacher.status !== "Active" && (
                            <option value="Active" data-action="status">
                              Change to Active
                            </option>
                          )}
                          {teacher.status !== "Inactive" && (
                            <option value="Inactive" data-action="status">
                              Change to Inactive
                            </option>
                          )}
                        </select>
                      </td>
                      <td>
                        <button
                          className="more-button"
                          onClick={() => handleMoreClick(teacher)}
                        >
                          Details
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Desktop Pagination Controls */}
              <div className="pagination-controls">
                <span>
                  Showing {indexOfFirstTeacher + 1} to{" "}
                  {Math.min(indexOfLastTeacher, filteredTeachers.length)} of{" "}
                  {filteredTeachers.length} teachers
                </span>
                <button onClick={prevPage} disabled={currentPage === 1}>
                  Previous
                </button>
                {[...Array(totalPages).keys()].map((number) => (
                  <button
                    key={number + 1}
                    onClick={() => paginate(number + 1)}
                    className={currentPage === number + 1 ? "active-page" : ""}
                  >
                    {number + 1}
                  </button>
                ))}
                <button
                  onClick={nextPage}
                  disabled={currentPage === totalPages}
                >
                  Next
                </button>
              </div>

              {/* Mobile Card List (≤640px) */}
              <div className="teacher-card-list">
                {currentTeachers.map((teacher) => (
                  <div key={teacher.id} className="teacher-card">
                    <div className="teacher-card-top">
                      <div>
                        <div className="teacher-card-name">
                          {getFullName(teacher)}
                        </div>
                        <div className="teacher-card-meta">
                          <span>
                            <span className="meta-label">Email</span>{" "}
                            {teacher.email || "N/A"}
                          </span>
                          <span>
                            <span className="meta-label">Last Login</span>{" "}
                            {teacher.lastLogin
                              ? formatDate(teacher.lastLogin)
                              : "N/A"}
                          </span>
                        </div>
                      </div>
                      <span
                        className={`status-pill ${teacher.status.toLowerCase()}`}
                      >
                        {teacher.status}
                      </span>
                    </div>
                    <div className="teacher-card-actions">
                      <select
                        value=""
                        onChange={(e) =>
                          handleStatusChange(
                            teacher.id,
                            e.target.value,
                            e.target.options[e.target.selectedIndex].dataset
                              .action,
                          )
                        }
                        className="teacher-actions-select"
                      >
                        <option value="" disabled>
                          Change Status
                        </option>
                        {teacher.status !== "Active" && (
                          <option value="Active" data-action="status">
                            Change to Active
                          </option>
                        )}
                        {teacher.status !== "Inactive" && (
                          <option value="Inactive" data-action="status">
                            Change to Inactive
                          </option>
                        )}
                      </select>
                      <button
                        className="more-button"
                        onClick={() => handleMoreClick(teacher)}
                      >
                        <i className="fas fa-info-circle"></i> Details
                      </button>
                    </div>
                  </div>
                ))}
                {/* Mobile Pagination */}
                <div className="teacher-card-pagination">
                  <span>
                    Showing {indexOfFirstTeacher + 1}–
                    {Math.min(indexOfLastTeacher, filteredTeachers.length)} of{" "}
                    {filteredTeachers.length}
                  </span>
                  <button onClick={prevPage} disabled={currentPage === 1}>
                    Previous
                  </button>
                  {[...Array(totalPages).keys()].map((number) => (
                    <button
                      key={number + 1}
                      onClick={() => paginate(number + 1)}
                      className={
                        currentPage === number + 1 ? "active-page" : ""
                      }
                    >
                      {number + 1}
                    </button>
                  ))}
                  <button
                    onClick={nextPage}
                    disabled={currentPage === totalPages}
                  >
                    Next
                  </button>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Teacher Details Modal (UPDATED CARD UI) */}
        {selectedTeacher && (
          <div className="modal" onClick={closeModal}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>Teacher Details - {getFullName(selectedTeacher)}</h2>
                <span className="close-icon" onClick={closeModal}>
                  ×
                </span>
              </div>
              <div className="modal-body">
                {/* NEW CARD-BASED DETAIL STRUCTURE */}
                <div className="teacher-info-grid">
                  {/* Card 1: Personal Information */}
                  <div className="info-card">
                    <h3 className="card-header">
                      <i className="fas fa-user-circle"></i> Personal
                      Information
                    </h3>
                    <div className="card-content">
                      <div className="card-item">
                        <span className="item-label">Full Name:</span>
                        <span className="item-value highlight">
                          {getFullName(selectedTeacher)}
                        </span>
                      </div>
                      <div className="card-item">
                        <span className="item-label">Gender:</span>
                        <span className="item-value">
                          {selectedTeacher.gender || "N/A"}
                        </span>
                      </div>
                      <div className="card-item">
                        <span className="item-label">Date of Birth:</span>
                        <span className="item-value">
                          {formatDate(selectedTeacher.dob) || "N/A"}
                        </span>
                      </div>
                      <div className="card-item">
                        <span className="item-label">Address:</span>
                        <span className="item-value">
                          {selectedTeacher.address || "N/A"}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Card 2: Contact Details */}
                  <div className="info-card">
                    <h3 className="card-header">
                      <i className="fas fa-phone-alt"></i> Contact Details
                    </h3>
                    <div className="card-content">
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
                      <div className="card-item">
                        <span className="item-label">Emergency Contact:</span>
                        <span className="item-value">
                          {selectedTeacher.emergencyContact || "N/A"}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Card 3: Professional Details */}
                  <div className="info-card">
                    <h3 className="card-header">
                      <i className="fas fa-graduation-cap"></i> Professional
                      Details
                    </h3>
                    <div className="card-content">
                      <div className="card-item">
                        <span className="item-label">Qualification:</span>
                        <span className="item-value">
                          {selectedTeacher.qualification || "N/A"}
                        </span>
                      </div>
                      <div className="card-item">
                        <span className="item-label">Experience (Years):</span>
                        <span className="item-value">
                          {selectedTeacher.experienceYears || "N/A"}
                        </span>
                      </div>
                      <div className="card-item">
                        <span className="item-label">Specialization:</span>
                        <span className="item-value">
                          {selectedTeacher.specialization || "N/A"}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Card 4: System and Status Info */}
                  <div className="info-card system-info-card">
                    <h3 className="card-header">
                      <i className="fas fa-server"></i> System Status
                    </h3>
                    <div className="card-content">
                      <div className="card-item">
                        <span className="item-label">Account Status:</span>
                        <span className="item-value">
                          {selectedTeacher.status || "N/A"}
                        </span>
                      </div>
                      <div className="card-item">
                        <span className="item-label">Registration Date:</span>
                        <span className="item-value">
                          {formatDate(selectedTeacher.createdAt) || "N/A"}
                        </span>
                      </div>
                      <div className="card-item">
                        <span className="item-label">Last Login:</span>
                        <span className="item-value">
                          {selectedTeacher.lastLogin
                            ? formatDate(selectedTeacher.lastLogin)
                            : "N/A"}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Status Confirmation Modal */}
        {showStatusModal && statusChangePending && (
          <div className="modal" onClick={cancelStatusChange}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>Confirm Status Change</h2>
                <span className="close-icon" onClick={cancelStatusChange}>
                  ×
                </span>
              </div>
              <div className="modal-body">
                <p>
                  Are you sure you want to{" "}
                  {statusChangePending.newStatus === "Active"
                    ? "activate"
                    : "deactivate"}{" "}
                  {statusChangePending.teacherName}'s account?
                </p>
                <div className="confirmation-buttons">
                  <button className="cancel-btn" onClick={cancelStatusChange}>
                    Cancel
                  </button>
                  <button className="confirm-btn" onClick={confirmStatusChange}>
                    Confirm
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ManageTeacher;
