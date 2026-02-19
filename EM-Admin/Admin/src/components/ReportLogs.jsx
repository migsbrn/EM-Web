import React, { useState, useEffect, useMemo } from "react";
import { db } from "../firebase";
import { collection, query, orderBy, onSnapshot } from "firebase/firestore";
import { useAuthState } from "react-firebase-hooks/auth";
import { auth } from "../firebase";
import "../styles/ReportLogs.css";

import { FiPrinter, FiSearch } from "react-icons/fi";
import {
  FaSignInAlt,
  FaSignOutAlt,
  FaPlusCircle,
  FaTrashAlt,
  FaEdit,
  FaUsers,
  FaClipboardList,
  FaFilter,
  FaRegCalendarCheck,
} from "react-icons/fa";

const getRelativeTime = (timestamp) => {
  if (!timestamp) return "N/A";
  try {
    const date = timestamp.toDate();
    const now = new Date();
    const diffMs = now - date;
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHr = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHr / 24);
    const diffWeek = Math.floor(diffDay / 7);
    const diffMonth = Math.floor(diffDay / 30);
    const diffYear = Math.floor(diffDay / 365);

    if (diffSec < 60) return `${diffSec} sec${diffSec !== 1 ? "s" : ""} ago`;
    if (diffMin < 60) return `${diffMin} min${diffMin !== 1 ? "s" : ""} ago`;
    if (diffHr < 24) return `${diffHr} hour${diffHr !== 1 ? "s" : ""} ago`;
    if (diffDay < 7) return `${diffDay} day${diffDay !== 1 ? "s" : ""} ago`;
    if (diffWeek < 4) return `${diffWeek} week${diffWeek !== 1 ? "s" : ""} ago`;
    if (diffMonth < 12)
      return `${diffMonth} month${diffMonth !== 1 ? "s" : ""} ago`;
    return `${diffYear} year${diffYear !== 1 ? "s" : ""} ago`;
  } catch {
    return "Invalid Date";
  }
};

const formatAbsoluteDate = (timestamp) => {
  if (!timestamp) return "N/A";
  try {
    return timestamp.toDate().toLocaleString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
    });
  } catch {
    return "Invalid Date";
  }
};

const ReportLogs = () => {
  const [user] = useAuthState(auth);
  const [logs, setLogs] = useState([]);
  const [filteredLogs, setFilteredLogs] = useState([]);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedMonth, setSelectedMonth] = useState("");
  const [selectedDay, setSelectedDay] = useState("");

  const [currentPage, setCurrentPage] = useState(1);
  const rowsPerPage = 10;
  const [isPrinting, setIsPrinting] = useState(false);

  useEffect(() => {
    if (!user) {
      setError("Please log in to view logs.");
      return;
    }
    const q = query(collection(db, "logs"), orderBy("createdAt", "desc"));

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const logData = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setLogs(logData);
        setFilteredLogs(logData);
        setError(null);
      },
      (err) => {
        console.error("Error fetching logs:", err);
        setError("Failed to load logs: " + err.message);
      },
    );

    return () => unsubscribe();
  }, [user]);

  useEffect(() => {
    let filtered = logs;

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(
        (log) =>
          (log.teacherName || "").toLowerCase().includes(term) ||
          (log.activityDescription || "").toLowerCase().includes(term),
      );
    }

    if (selectedMonth) {
      filtered = filtered.filter((log) => {
        if (!log.createdAt) return false;
        const d = log.createdAt.toDate();
        return d.getMonth() + 1 === parseInt(selectedMonth);
      });
    }

    if (selectedDay) {
      filtered = filtered.filter((log) => {
        if (!log.createdAt) return false;
        const d = log.createdAt.toDate();
        return d.getDate() === parseInt(selectedDay);
      });
    }

    setFilteredLogs(filtered);
    setCurrentPage(1);
  }, [searchTerm, selectedMonth, selectedDay, logs]);

  const handlePrint = () => {
    setIsPrinting(true);
    setTimeout(() => {
      window.print();
      setIsPrinting(false);
    }, 0);
  };

  const months = useMemo(
    () =>
      Array.from({ length: 12 }, (_, i) => ({
        value: (i + 1).toString(),
        label: new Date(0, i).toLocaleString("en-US", { month: "long" }),
      })),
    [],
  );

  const days = useMemo(
    () =>
      Array.from({ length: 31 }, (_, i) => ({
        value: (i + 1).toString(),
        label: (i + 1).toString(),
      })),
    [],
  );

  const totalActivities = logs.length;

  const todaysLogsCount = useMemo(() => {
    const today = new Date();
    return logs.filter((l) => {
      if (!l.createdAt) return false;
      const d = l.createdAt.toDate();
      return (
        d.getDate() === today.getDate() &&
        d.getMonth() === today.getMonth() &&
        d.getFullYear() === today.getFullYear()
      );
    }).length;
  }, [logs]);

  const detectBadgeClass = (activity = "") => {
    const act = activity.toLowerCase();
    if (act.includes("logged in") || act.includes("login")) return "log-in";
    if (act.includes("logged out") || act.includes("logout")) return "log-out";
    if (act.includes("add") || act.includes("created")) return "log-assessment";
    if (act.includes("update") || act.includes("edited")) return "log-update";
    if (act.includes("delete") || act.includes("removed")) return "log-delete";
    return "log-default";
  };

  const iconForActivity = (activity = "") => {
    const act = activity.toLowerCase();
    if (act.includes("logged in") || act.includes("login"))
      return <FaSignInAlt />;
    if (act.includes("logged out") || act.includes("logout"))
      return <FaSignOutAlt />;
    if (act.includes("add") || act.includes("created")) return <FaPlusCircle />;
    if (act.includes("update") || act.includes("edited")) return <FaEdit />;
    if (act.includes("delete") || act.includes("removed"))
      return <FaTrashAlt />;
    return <FaUsers />;
  };

  const totalPages = Math.ceil(filteredLogs.length / rowsPerPage);

  const logsToDisplay = isPrinting
    ? filteredLogs
    : filteredLogs.slice(
        (currentPage - 1) * rowsPerPage,
        currentPage * rowsPerPage,
      );

  // ── KPI Card Component ──
  const ReportKPICard = ({ title, value, icon, iconClass, valueColor }) => (
    <div className="kpi-card">
      <div className="card-content">
        <div className="card-label">{title}</div>
        <div className="card-value" style={{ color: valueColor }}>
          {value}
        </div>
      </div>
      <div className={`card-icon ${iconClass}`}>{icon}</div>
    </div>
  );

  // ── Pagination Component ──
  const PaginationControls = () => {
    if (totalPages <= 1) return null;
    return (
      <div className="pagination no-print">
        <span>
          Page {currentPage} of {totalPages}
        </span>
        <button
          disabled={currentPage === 1}
          onClick={() => setCurrentPage((p) => p - 1)}
        >
          ‹ Prev
        </button>
        <button
          disabled={currentPage === totalPages}
          onClick={() => setCurrentPage((p) => p + 1)}
        >
          Next ›
        </button>
      </div>
    );
  };

  return (
    <div className="report-logs-root">
      <div className="report-logs-container">
        {/* ── HERO ── */}
        <div className="report-hero">
          <div className="report-title">
            <h2 className="report-logs-title no-print">Activity Logs</h2>
            <p className="report-sub">
              View, filter, and export audit logs. Use the controls to narrow
              results.
            </p>
          </div>

          <div className="hero-actions no-print">
            {/* Search */}
            <div className="search-wrap">
              <FiSearch className="search-icon" />
              <input
                className="report-controls-input"
                placeholder="Search teacher or activity…"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            {/* Selects + Export */}
            <div className="select-wrap">
              <select
                value={selectedMonth}
                onChange={(e) => setSelectedMonth(e.target.value)}
                className="report-controls-select"
              >
                <option value="">All Months</option>
                {months.map((m) => (
                  <option key={m.value} value={m.value}>
                    {m.label}
                  </option>
                ))}
              </select>

              <select
                value={selectedDay}
                onChange={(e) => setSelectedDay(e.target.value)}
                className="report-controls-select"
              >
                <option value="">All Days</option>
                {days.map((d) => (
                  <option key={d.value} value={d.value}>
                    {d.label}
                  </option>
                ))}
              </select>

              <button onClick={handlePrint} className="report-controls-button">
                <FiPrinter />
                <span className="btn-text">Export to PDF</span>
              </button>
            </div>
          </div>
        </div>

        {/* ── KPI SUMMARY CARDS ── */}
        <div className="logs-summary-cards no-print">
          <ReportKPICard
            title="Total Activities"
            value={totalActivities}
            icon={<FaClipboardList />}
            iconClass="card-icon-1"
            valueColor="#648ba2"
          />
          <ReportKPICard
            title="Filtered Results"
            value={filteredLogs.length}
            icon={<FaFilter />}
            iconClass="card-icon-2"
            valueColor="#f59e0b"
          />
          <ReportKPICard
            title="Today's Logs"
            value={todaysLogsCount}
            icon={<FaRegCalendarCheck />}
            iconClass="card-icon-4"
            valueColor="#7CA1CC"
          />
        </div>

        {error && <div className="alert no-print">{error}</div>}

        {/* ── TABLE + CARD LIST ── */}
        <div className="report-table-wrapper">
          {/* Print-only header */}
          <div className="print-only-header">
            <h1>Activity Logs Report</h1>
            <p>Generated on: {new Date().toLocaleString()}</p>
          </div>

          <div className="report-table-container">
            {/* ── Desktop Table ── */}
            <table className="report-table">
              <thead>
                <tr>
                  <th className="th-datetime">Date &amp; Time</th>
                  <th className="th-teacher">Teacher Name</th>
                  <th className="th-activity">Activity</th>
                </tr>
              </thead>
              <tbody>
                {logsToDisplay.length === 0 ? (
                  <tr>
                    <td colSpan="3" className="empty-state">
                      <div className="empty-inner">
                        <div className="empty-emoji">😥</div>
                        <div>No logs match the current filters.</div>
                      </div>
                    </td>
                  </tr>
                ) : (
                  logsToDisplay.map((log) => {
                    const badgeClass = detectBadgeClass(
                      log.activityDescription || "",
                    );
                    return (
                      <tr key={log.id} className="report-row">
                        <td className="cell-datetime">
                          <div className="relative-time no-print">
                            {getRelativeTime(log.createdAt)}
                          </div>
                          {log.createdAt && (
                            <div className="absolute-time">
                              {formatAbsoluteDate(log.createdAt)}
                            </div>
                          )}
                        </td>
                        <td className="cell-teacher">
                          {log.teacherName || "Unknown"}
                        </td>
                        <td className="cell-activity">
                          <span className={`activity-badge ${badgeClass}`}>
                            <span className="activity-icon">
                              {iconForActivity(log.activityDescription || "")}
                            </span>
                            <span className="activity-text">
                              {log.activityDescription || "No description"}
                            </span>
                          </span>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>

            {/* ── Mobile Card List (visible only on small screens via CSS) ── */}
            <div className="rl-card-list no-print">
              {logsToDisplay.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-inner">
                    <div className="empty-emoji">😥</div>
                    <div>No logs match the current filters.</div>
                  </div>
                </div>
              ) : (
                logsToDisplay.map((log) => {
                  const badgeClass = detectBadgeClass(
                    log.activityDescription || "",
                  );
                  return (
                    <div key={log.id} className="rl-log-card">
                      <div className="rl-card-top">
                        <span className="rl-card-teacher">
                          {log.teacherName || "Unknown"}
                        </span>
                        <span className="rl-card-time">
                          {getRelativeTime(log.createdAt)}
                          {log.createdAt && (
                            <span className="rl-card-date">
                              {formatAbsoluteDate(log.createdAt)}
                            </span>
                          )}
                        </span>
                      </div>
                      <div className="rl-card-activity">
                        <span className={`activity-badge ${badgeClass}`}>
                          <span className="activity-icon">
                            {iconForActivity(log.activityDescription || "")}
                          </span>
                          <span className="activity-text">
                            {log.activityDescription || "No description"}
                          </span>
                        </span>
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* ── Pagination ── */}
            <PaginationControls />
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReportLogs;
