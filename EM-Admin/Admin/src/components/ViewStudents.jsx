import React, { useEffect, useState } from "react";
import { db } from "../firebase";
import {
  collection,
  query,
  getDocs,
  doc,
  getDoc,
  where,
} from "firebase/firestore";
import "../styles/ViewStudents.css";

const ViewStudents = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [progressFilter, setProgressFilter] = useState("All");
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [activeTab, setActiveTab] = useState("overview");

  // NEW: States for Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const recordsPerPage = 10; // Set records per page to 10

  const [activityData, setActivityData] = useState({
    assessments: {},
    lessons: {},
    games: {},
  });

  // --- Utility function to calculate detailed progress (Accurate Logic) ---
  const calculateDetailedProgress = (
    studentData,
    userStatsData,
    assessmentResults,
    lessonData,
    gameData,
  ) => {
    const stats = userStatsData[studentData.nickname] || {};
    const assessments = assessmentResults[studentData.nickname] || [];
    const lessons = lessonData[studentData.nickname] || [];
    const games = gameData[studentData.nickname] || [];

    // Calculate average performance based on all assessments
    const avgPerformance =
      assessments.length > 0
        ? assessments.reduce((sum, a) => sum + (a.performance || 0), 0) /
          assessments.length
        : 0;

    // Get most recent assessment type
    const recentAssessment =
      assessments.length > 0
        ? assessments.sort(
            (a, b) =>
              (b.timestamp?.toDate() || new Date(0)) -
              (a.timestamp?.toDate() || new Date(0)),
          )[0]
        : null;

    const progressPercentage = Math.round(avgPerformance * 100);

    return {
      progressPercentage,
      progressDisplay: `${progressPercentage}%`, // Keep for display consistency
      lastLogin: studentData.lastLogin
        ? studentData.lastLogin.toDate().toLocaleString()
        : "Never",
      assignedTeacher: "Unknown",
      recentAssessment:
        recentAssessment?.assessmentType || "No assessments yet",
      totalAttempts: assessments.length,
      detailedStats: {
        totalXP: stats.totalXP || 0,
        level: stats.currentLevel || 1,
        streakDays: stats.streakDays || 0,
        lessonsCompleted: lessons.length,
        gamesPlayed: games.length,
        totalActivities: assessments.length + lessons.length + games.length,
        averageScore: progressPercentage,
      },
    };
  };

  // Utility to format date for modal tabs
  const formatActivityDate = (timestamp) => {
    if (!timestamp) return "N/A";
    try {
      const date = timestamp?.toDate?.() || new Date(timestamp);
      return date.toLocaleString();
    } catch (e) {
      return "Invalid Date";
    }
  };

  // --- Main data fetching logic ---
  useEffect(() => {
    const fetchAllData = async () => {
      setLoading(true);
      try {
        // --- 1. Fetch auxiliary data needed for calculations ---
        const [
          studentsSnapshot,
          userStatsSnapshot,
          assessmentSnapshot,
          lessonSnapshot,
          gameVisitSnapshot,
        ] = await Promise.all([
          getDocs(collection(db, "students")),
          getDocs(collection(db, "userStats")),
          getDocs(collection(db, "adaptiveAssessmentResults")),
          getDocs(collection(db, "lessonRetention")),
          getDocs(
            query(
              collection(db, "visitTracking"),
              where("itemType", "==", "game"),
            ),
          ),
        ]);

        // Map auxiliary data for easy lookup and store raw data for modal
        const userStatsData = userStatsSnapshot.docs.reduce((acc, doc) => {
          const data = doc.data();
          if (data.nickname) acc[data.nickname] = data;
          return acc;
        }, {});

        const assessmentResults = {};
        const rawAssessments = {}; // To store raw chronological data for modal
        assessmentSnapshot.forEach((doc) => {
          const data = doc.data();
          if (data.nickname) {
            if (!assessmentResults[data.nickname])
              assessmentResults[data.nickname] = [];
            assessmentResults[data.nickname].push(data);

            if (!rawAssessments[data.nickname])
              rawAssessments[data.nickname] = [];
            rawAssessments[data.nickname].push(data);
          }
        });

        const rawLessons = {}; // To store raw chronological data for modal
        const lessonData = lessonSnapshot.docs.reduce((acc, doc) => {
          const data = doc.data();
          if (data.nickname) {
            if (!acc[data.nickname]) acc[data.nickname] = [];
            acc[data.nickname].push(data);

            if (!rawLessons[data.nickname]) rawLessons[data.nickname] = [];
            rawLessons[data.nickname].push(data);
          }
          return acc;
        }, {});

        const rawGames = {}; // To store raw chronological data for modal
        const gameData = gameVisitSnapshot.docs.reduce((acc, doc) => {
          const data = doc.data();
          if (data.nickname) {
            if (!acc[data.nickname]) acc[data.nickname] = [];
            acc[data.nickname].push(data);

            if (!rawGames[data.nickname]) rawGames[data.nickname] = [];
            rawGames[data.nickname].push(data);
          }
          return acc;
        }, {});

        setActivityData({
          assessments: rawAssessments,
          lessons: rawLessons,
          games: rawGames,
        });

        // --- 2. Process and enrich student data ---
        const studentData = studentsSnapshot.docs.map((docSnapshot) => ({
          id: docSnapshot.id,
          ...docSnapshot.data(),
        }));

        const enrichedStudents = await Promise.all(
          studentData.map(async (data) => {
            // Calculate progress using the new accurate function
            const progress = calculateDetailedProgress(
              data,
              userStatsData,
              assessmentResults,
              lessonData,
              gameData,
            );

            // Fetch assigned teacher name and status
            let assignedTeacher = "Unknown";
            let teacherLoggedInRecently = false;
            if (data.createdBy) {
              try {
                const teacherDoc = await getDoc(
                  doc(db, "teacherRequests", data.createdBy),
                );
                if (teacherDoc.exists()) {
                  const teacherData = teacherDoc.data();
                  assignedTeacher =
                    `${teacherData.firstName || ""} ${
                      teacherData.lastName || ""
                    }`.trim() || "Unknown";

                  // Check if teacher logged in the last 7 days
                  const lastLoginTime = teacherData.lastLogin
                    ?.toDate?.()
                    ?.getTime();
                  if (lastLoginTime) {
                    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
                    teacherLoggedInRecently = lastLoginTime > sevenDaysAgo;
                  }
                }
              } catch (e) {
                console.error("Error fetching teacher:", e);
              }
            }

            return {
              id: data.id,
              nickname: data.nickname || "N/A",
              assignedTeacher: assignedTeacher,
              teacherLoggedInRecently: teacherLoggedInRecently, // Indicator for table
              progress: progress.progressDisplay,
              progressPercentage: progress.progressPercentage,
              details: {
                surname: data.surname || "N/A",
                firstName: data.firstName || "N/A",
                middleName: data.middleName || "N/A",
                supportNeeds: data.supportNeeds || [],
                lastLogin: progress.lastLogin,
                ...progress.detailedStats,
              },
              recentAssessment: progress.recentAssessment,
              totalAttempts: progress.totalAttempts,
            };
          }),
        );

        setStudents(enrichedStudents);
        setLoading(false);
      } catch (error) {
        console.error("Error fetching or processing student data:", error);
        setLoading(false);
      }
    };

    fetchAllData();
  }, []);

  const filteredStudents = students.filter((student) => {
    const matchesSearch = student.nickname
      .toLowerCase()
      .includes(searchTerm.toLowerCase());

    // Filter logic based on progress categories
    const matchesProgress =
      progressFilter === "All" ||
      (progressFilter === "Low" && student.progressPercentage <= 50) ||
      (progressFilter === "Medium" &&
        student.progressPercentage > 50 &&
        student.progressPercentage <= 80) ||
      (progressFilter === "High" && student.progressPercentage > 80);

    return matchesSearch && matchesProgress;
  });

  // NEW: Pagination calculations
  const totalPages = Math.ceil(filteredStudents.length / recordsPerPage);
  const indexOfLastRecord = currentPage * recordsPerPage;
  const indexOfFirstRecord = indexOfLastRecord - recordsPerPage;
  const currentRecords = filteredStudents.slice(
    indexOfFirstRecord,
    indexOfLastRecord,
  );

  const paginate = (pageNumber) => {
    // Only update if the page number is valid
    if (pageNumber >= 1 && pageNumber <= totalPages) {
      setCurrentPage(pageNumber);
    }
  };

  const openModal = (student) => {
    setSelectedStudent({
      ...student,
      // Append all activity data for the selected student, sorted descending (most recent first)
      rawAssessments: (activityData.assessments[student.nickname] || []).sort(
        (a, b) =>
          (b.timestamp?.toDate() || new Date(0)) -
          (a.timestamp?.toDate() || new Date(0)),
      ),
      rawLessons: (activityData.lessons[student.nickname] || []).sort(
        (a, b) =>
          (b.timestamp?.toDate() || new Date(0)) -
          (a.timestamp?.toDate() || new Date(0)),
      ),
      rawGames: (activityData.games[student.nickname] || []).sort(
        (a, b) =>
          (b.timestamp?.toDate() || new Date(0)) -
          (a.timestamp?.toDate() || new Date(0)),
      ),
    });
    setActiveTab("overview"); // Reset to overview tab on open
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setSelectedStudent(null);
  };

  // NEW: Pagination Control Component (Copied from Manage Teacher style)
  const PaginationControls = () => {
    const pageNumbers = [];
    // Only show page numbers up to 5 on either side of the current page
    const maxPagesToShow = 7;
    let startPage = Math.max(1, currentPage - Math.floor(maxPagesToShow / 2));
    let endPage = Math.min(totalPages, startPage + maxPagesToShow - 1);

    if (endPage - startPage + 1 < maxPagesToShow) {
      startPage = Math.max(1, endPage - maxPagesToShow + 1);
    }

    for (let i = startPage; i <= endPage; i++) {
      pageNumbers.push(i);
    }

    if (totalPages <= 1) return null; // Hide controls if 1 or 0 pages

    return (
      <div className="vs-pagination-controls">
        <button
          onClick={() => paginate(1)}
          disabled={currentPage === 1}
          className="vs-page-btn arrow"
          title="First Page"
        >
          &laquo;
        </button>
        <button
          onClick={() => paginate(currentPage - 1)}
          disabled={currentPage === 1}
          className="vs-page-btn arrow"
          title="Previous Page"
        >
          &lsaquo;
        </button>

        {startPage > 1 && <span className="vs-page-dots">...</span>}

        <div className="vs-page-numbers">
          {pageNumbers.map((number) => (
            <button
              key={number}
              onClick={() => paginate(number)}
              className={`vs-page-btn number ${
                currentPage === number ? "active" : ""
              }`}
            >
              {number}
            </button>
          ))}
        </div>

        {endPage < totalPages && <span className="vs-page-dots">...</span>}

        <button
          onClick={() => paginate(currentPage + 1)}
          disabled={currentPage === totalPages}
          className="vs-page-btn arrow"
          title="Next Page"
        >
          &rsaquo;
        </button>
        <button
          onClick={() => paginate(totalPages)}
          disabled={currentPage === totalPages}
          className="vs-page-btn arrow"
          title="Last Page"
        >
          &raquo;
        </button>
        <div className="vs-page-info">
          Page {currentPage} of {totalPages}
        </div>
      </div>
    );
  };

  // Helper: progress class
  const progressClass = (pct) =>
    pct > 80 ? "high" : pct > 50 ? "medium" : "low";

  return (
    <div className="vs-container">
      {/* ── Page Header ── */}
      <div className="vs-page-header">
        <h1 className="vs-title">Student List</h1>
        <p className="vs-subtitle">
          Total Registered Students&nbsp;
          <span className="vs-subtitle-badge">{students.length}</span>
        </p>
      </div>

      {/* ── Controls ── */}
      <div className="vs-controls">
        <div className="vs-controls-left">
          <div className="vs-search-wrapper">
            <span className="vs-search-icon"></span>
            <input
              className="vs-search"
              type="text"
              placeholder="Search by nickname…"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
            />
          </div>
          <div className="vs-select-wrapper">
            <select
              className="vs-select"
              value={progressFilter}
              onChange={(e) => {
                setProgressFilter(e.target.value);
                setCurrentPage(1);
              }}
            >
              <option value="All">All Progress</option>
              <option value="Low">Low (0–50%)</option>
              <option value="Medium">Medium (51–80%)</option>
              <option value="High">High (81–100%)</option>
            </select>
          </div>
        </div>
      </div>

      {/* ── Table Container ── */}
      <div className="vs-table-container">
        {loading ? (
          <div className="vs-state-message">
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            >
              <circle cx="12" cy="12" r="10" />
              <path d="M12 6v6l4 2" />
            </svg>
            Loading students and progress data…
          </div>
        ) : (
          <>
            {/* ── Desktop Table ── */}
            <div className="vs-table-wrapper">
              <table className="vs-table">
                <thead>
                  <tr>
                    <th>Nickname</th>
                    <th>Assigned Teacher</th>
                    <th>Recent Assessment</th>
                    <th>Attempts</th>
                    <th>Avg. Progress</th>
                    <th>Details</th>
                  </tr>
                </thead>
                <tbody>
                  {currentRecords.map((student) => (
                    <tr key={student.id}>
                      <td style={{ fontWeight: 600 }}>{student.nickname}</td>
                      <td>
                        <div className="vs-teacher-cell">
                          {student.assignedTeacher}
                          <span
                            className={`status-indicator ${student.teacherLoggedInRecently ? "online" : "offline"}`}
                            title={
                              student.teacherLoggedInRecently
                                ? "Teacher active (last 7 days)"
                                : "Teacher inactive (7+ days)"
                            }
                          />
                        </div>
                      </td>
                      <td>{student.recentAssessment}</td>
                      <td>{student.totalAttempts}</td>
                      <td>
                        <span
                          className={`stat-value vs-progress-${progressClass(student.progressPercentage)}`}
                        >
                          {student.progress}
                        </span>
                      </td>
                      <td>
                        <button
                          className="vs-more-btn"
                          onClick={() => openModal(student)}
                        >
                          View Details
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* ── Mobile Card List ── */}
            <div className="vs-card-list">
              {currentRecords.map((student) => (
                <div key={student.id} className="vs-student-card">
                  <div className="vs-card-header">
                    <span className="vs-card-nickname">{student.nickname}</span>
                    <span
                      className={`stat-value vs-progress-${progressClass(student.progressPercentage)}`}
                    >
                      {student.progress}
                    </span>
                  </div>
                  <div className="vs-card-row">
                    <span className="vs-card-label">Teacher</span>
                    <span
                      className="vs-card-value"
                      style={{ display: "flex", alignItems: "center", gap: 6 }}
                    >
                      {student.assignedTeacher}
                      <span
                        className={`status-indicator ${student.teacherLoggedInRecently ? "online" : "offline"}`}
                      />
                    </span>
                  </div>
                  <div className="vs-card-row">
                    <span className="vs-card-label">Recent Assessment</span>
                    <span className="vs-card-value">
                      {student.recentAssessment}
                    </span>
                  </div>
                  <div className="vs-card-row">
                    <span className="vs-card-label">Attempts</span>
                    <span className="vs-card-value">
                      {student.totalAttempts}
                    </span>
                  </div>
                  <div className="vs-card-footer">
                    <button
                      className="vs-more-btn"
                      onClick={() => openModal(student)}
                    >
                      View Details
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {filteredStudents.length === 0 && (
              <div className="vs-state-message">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.5"
                >
                  <circle cx="11" cy="11" r="8" />
                  <path d="M21 21l-4.35-4.35" />
                </svg>
                No students match the current criteria.
              </div>
            )}

            <PaginationControls />
          </>
        )}
      </div>
      {/* --- Modal Component --- */}
      {isModalOpen && selectedStudent && (
        <div className="vs-modal" onClick={closeModal}>
          <div
            className="vs-modal-content"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="vs-modal-header">
              <h2>👤 {selectedStudent.nickname}'s Details</h2>
              <span
                className="vs-close-icon"
                onClick={closeModal}
                title="Close"
              >
                ×
              </span>
            </div>

            {/* Tab Bar */}
            <div className="vs-tab-bar">
              <button
                className={`vs-tab ${activeTab === "overview" ? "active" : ""}`}
                onClick={() => setActiveTab("overview")}
              >
                Overview
              </button>
              <button
                className={`vs-tab ${
                  activeTab === "assessments" ? "active" : ""
                }`}
                onClick={() => setActiveTab("assessments")}
              >
                Assessment History ({selectedStudent.rawAssessments.length})
              </button>
              <button
                className={`vs-tab ${activeTab === "activity" ? "active" : ""}`}
                onClick={() => setActiveTab("activity")}
              >
                Activity Log
              </button>
            </div>

            {/* Modal Body - Tab Content */}
            <div className="vs-modal-body">
              {/* 1. Overview Tab */}
              {activeTab === "overview" && (
                <div className="vs-tab-content overview-content">
                  <h3>General Information</h3>
                  <p>
                    <strong>Full Name:</strong>
                    {`${selectedStudent.details.firstName} ${
                      selectedStudent.details.middleName !== "N/A"
                        ? selectedStudent.details.middleName + " "
                        : ""
                    }${selectedStudent.details.surname}`}
                  </p>
                  <p>
                    <strong>Support Needs:</strong>
                    {selectedStudent.details.supportNeeds.length > 0
                      ? selectedStudent.details.supportNeeds.join(", ")
                      : "None"}
                  </p>
                  <p>
                    <strong>Assigned Teacher:</strong>
                    {selectedStudent.assignedTeacher}
                    <span
                      className={`status-indicator inline ${
                        selectedStudent.teacherLoggedInRecently
                          ? "online"
                          : "offline"
                      }`}
                      title={
                        selectedStudent.teacherLoggedInRecently
                          ? "Teacher Active"
                          : "Teacher Inactive"
                      }
                    ></span>
                  </p>
                  <p>
                    <strong>Last Student Login:</strong>{" "}
                    {selectedStudent.details.lastLogin || "Never"}
                  </p>

                  <hr />

                  <h3>Overall Performance</h3>
                  <div className="vs-stats-grid">
                    <p>
                      <strong>Average Score</strong>
                      <span
                        className={`stat-value vs-progress-${
                          selectedStudent.progressPercentage > 80
                            ? "high"
                            : selectedStudent.progressPercentage > 50
                              ? "medium"
                              : "low"
                        }`}
                      >
                        {selectedStudent.details.averageScore}%
                      </span>
                    </p>
                    <p>
                      <strong>Total Attempts</strong>
                      <span className="stat-value">
                        {selectedStudent.totalAttempts}
                      </span>
                    </p>
                    <p>
                      <strong>XP</strong>
                      <span className="stat-value">
                        {selectedStudent.details.totalXP}
                      </span>
                    </p>
                    <p>
                      <strong>Level</strong>
                      <span className="stat-value">
                        {selectedStudent.details.level}
                      </span>
                    </p>
                    <p>
                      <strong>Streak Days</strong>
                      <span className="stat-value">
                        {selectedStudent.details.streakDays}
                      </span>
                    </p>
                    <p>
                      <strong>Lessons Completed</strong>
                      <span className="stat-value">
                        {selectedStudent.details.lessonsCompleted}
                      </span>
                    </p>
                    <p>
                      <strong>Games Played</strong>
                      <span className="stat-value">
                        {selectedStudent.details.gamesPlayed}
                      </span>
                    </p>
                    <p>
                      <strong>Total Activities</strong>
                      <span className="stat-value">
                        {selectedStudent.details.totalActivities}
                      </span>
                    </p>
                  </div>
                </div>
              )}

              {/* 2. Assessment History Tab */}
              {activeTab === "assessments" && (
                <div className="vs-tab-content assessment-history-content">
                  {selectedStudent.rawAssessments.length > 0 ? (
                    <div className="history-table-container">
                      <table className="history-table">
                        <thead>
                          <tr>
                            <th>Date</th>
                            <th>Type</th>
                            <th>Performance</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selectedStudent.rawAssessments.map((a, index) => (
                            <tr key={index}>
                              <td>{formatActivityDate(a.timestamp)}</td>
                              <td>{a.assessmentType || "General"}</td>
                              <td>
                                <span
                                  className={`score-pill vs-progress-${
                                    a.performance * 100 > 80
                                      ? "high"
                                      : a.performance * 100 > 50
                                        ? "medium"
                                        : "low"
                                  }`}
                                >
                                  {Math.round(a.performance * 100)}%
                                </span>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <p className="no-history">
                      No assessment history recorded for this student.
                    </p>
                  )}
                </div>
              )}

              {/* 3. Activity Log Tab */}
              {activeTab === "activity" && (
                <div className="vs-tab-content activity-log-content">
                  <h3>Recent Activities (Last 10 Lessons & Games)</h3>
                  <div className="activity-history-table-container">
                    <table className="history-table">
                      <thead>
                        <tr>
                          <th>Date</th>
                          <th>Type</th>
                          <th>Details</th>
                        </tr>
                      </thead>
                      <tbody>
                        {[
                          ...selectedStudent.rawLessons.map((l) => ({
                            timestamp: l.completedAt || l.timestamp,
                            type: "Lesson",
                            detail: l.lessonName || "Lesson Completed",
                          })),
                          ...selectedStudent.rawGames.map((g) => ({
                            timestamp: g.visitedAt || g.timestamp,
                            type: "Game",
                            detail: g.itemName || "Game Played",
                          })),
                        ]
                          .sort(
                            (a, b) =>
                              (b.timestamp?.toDate() || new Date(0)) -
                              (a.timestamp?.toDate() || new Date(0)),
                          )
                          .slice(0, 10) // Only last 10 activities
                          .map((activity, index) => (
                            <tr key={index}>
                              <td>{formatActivityDate(activity.timestamp)}</td>
                              <td>
                                <span
                                  className={`activity-type-pill ${activity.type.toLowerCase()}`}
                                >
                                  {activity.type}
                                </span>
                              </td>
                              <td>{activity.detail}</td>
                            </tr>
                          )).length > 0 ? (
                          [
                            ...selectedStudent.rawLessons.map((l) => ({
                              timestamp: l.completedAt || l.timestamp,
                              type: "Lesson",
                              detail: l.lessonName || "Lesson Completed",
                            })),
                            ...selectedStudent.rawGames.map((g) => ({
                              timestamp: g.visitedAt || g.timestamp,
                              type: "Game",
                              detail: g.itemName || "Game Played",
                            })),
                          ]
                            .sort(
                              (a, b) =>
                                (b.timestamp?.toDate() || new Date(0)) -
                                (a.timestamp?.toDate() || new Date(0)),
                            )
                            .slice(0, 10) // Only last 10 activities
                            .map((activity, index) => (
                              <tr key={index}>
                                <td>
                                  {formatActivityDate(activity.timestamp)}
                                </td>
                                <td>
                                  <span
                                    className={`activity-type-pill ${activity.type.toLowerCase()}`}
                                  >
                                    {activity.type}
                                  </span>
                                </td>
                                <td>{activity.detail}</td>
                              </tr>
                            ))
                        ) : (
                          <tr>
                            <td colSpan="3" className="no-history">
                              No recent lesson or game activity recorded.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>

            <div className="vs-modal-footer">
              <button className="vs-close-btn" onClick={closeModal}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ViewStudents;
