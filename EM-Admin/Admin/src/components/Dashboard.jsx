import React, { useEffect, useState, useCallback } from "react";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
} from "recharts";
import { db } from "../firebase";
import {
  collection,
  query,
  where,
  getDocs,
  onSnapshot,
  orderBy,
  limit,
} from "firebase/firestore";
import {
  FaUserPlus,
  FaUsers,
  // FaChartLine, // Removed the unused icon
  FaCheckCircle,
} from "react-icons/fa"; // Icons for KPIs
import "../styles/Dashboard.css";

const Dashboard = () => {
  const [loading, setLoading] = useState(true);
  const [teacherCount, setTeacherCount] = useState(0);
  const [studentCount, setStudentCount] = useState(0);
  const [pendingTeacherCount, setPendingTeacherCount] = useState(0);
  // const [assessmentsToday, setAssessmentsToday] = useState(0); // Removed state
  const [dailyActiveUsers, setDailyActiveUsers] = useState([]);
  const [recentActivities, setRecentActivities] = useState([]);

  // NEW STATE: Stores the nicknames of currently active students for filtering logins
  const [activeNicknames, setActiveNicknames] = useState(new Set());

  // Function to initialize the real-time listeners, memoized with useCallback
  // This function depends on activeNicknames, so we must define it carefully
  const updateLoginData = useCallback(() => {
    // Time boundary setup for the Bar Chart (Past 7 Days)
    const now = new Date();
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);

    const loginCountsByDay = {};
    days.forEach((day) => {
      loginCountsByDay[day] = {
        students: new Set(),
        teachers: new Set(),
      };
    });

    // --- Listener for student logins (BAR CHART FIX) ---
    // We only query the relevant time range to minimize read costs
    const studentLoginQuery = query(
      collection(db, "studentLogins"),
      orderBy("loginTime", "desc"), // Ensure latest data is easily accessible
      where("loginTime", ">=", startOfWeek),
      where("loginTime", "<=", endOfWeek),
    );

    const unsubscribeStudents = onSnapshot(studentLoginQuery, (snapshot) => {
      const studentLoginData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Reset counts for the new snapshot
      days.forEach((day) => loginCountsByDay[day].students.clear());

      studentLoginData.forEach((login) => {
        if (login.loginTime && login.nickname) {
          // >>> CRITICAL FIX: Only count logins from currently active students <<<
          if (activeNicknames.has(login.nickname)) {
            const loginDate = login.loginTime.toDate();
            const loginDay = loginDate.toLocaleDateString("en-US", {
              weekday: "short",
              // It's safer to rely on client timezone handling for "day of the week" charts
            });

            if (days.includes(loginDay)) {
              loginCountsByDay[loginDay].students.add(login.nickname);
            }
          }
        }
      });

      // This is complex because the teacher listener might update teachers right after.
      // For simplicity, we only update the student counts here and let the teacher listener update the teacher counts.
      // A better long-term solution is combining the state updates into one logic block.
      // For now, let's keep the structure but ensure both listeners update the full array.
      setDailyActiveUsers((prevUsers) =>
        prevUsers.map((dayData) => ({
          ...dayData,
          students: loginCountsByDay[dayData.name].students.size || 0,
          teachers: dayData.teachers, // Preserve teachers count from previous state/listener
        })),
      );
    });

    // --- Listener for teacher logins ---
    const teacherLoginQuery = query(
      collection(db, "teacherLogins"),
      orderBy("loginTime", "desc"),
      where("loginTime", ">=", startOfWeek),
      where("loginTime", "<=", endOfWeek),
    );

    const unsubscribeTeachers = onSnapshot(teacherLoginQuery, (snapshot) => {
      const teacherLoginData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Reset counts for the new snapshot
      days.forEach((day) => loginCountsByDay[day].teachers.clear());

      teacherLoginData.forEach((login) => {
        if (login.loginTime && login.teacherId) {
          const loginDate = login.loginTime.toDate();
          const loginDay = loginDate.toLocaleDateString("en-US", {
            weekday: "short",
          });
          if (days.includes(loginDay)) {
            loginCountsByDay[loginDay].teachers.add(login.teacherId);
          }
        }
      });

      // Update with the correct teacher counts
      setDailyActiveUsers((prevUsers) => {
        const baseData =
          prevUsers.length > 0
            ? prevUsers
            : days.map((day) => ({ name: day, students: 0, teachers: 0 }));

        return baseData.map((dayData) => ({
          ...dayData,
          teachers: loginCountsByDay[dayData.name].teachers.size || 0,
        }));
      });
    });

    // ... (Assessment Listener REMOVED) ...
    /*
    // 5. Listener for Assessments Today (REMOVED)
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    const assessmentQuery = query(
      collection(db, "assessments"),
      where("timestamp", ">=", startOfToday),
      where("timestamp", "<=", endOfToday)
    );

    const unsubscribeAssessments = onSnapshot(assessmentQuery, (snapshot) => {
      setAssessmentsToday(snapshot.size);
    });
    */

    // Listener for recent admin actions
    const activityQuery = query(
      collection(db, "adminActions"),
      orderBy("timestamp", "desc"),
      limit(5),
    );
    const unsubscribeActivities = onSnapshot(activityQuery, (snapshot) => {
      const activities = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          action: data.action || "Unknown action",
          type: data.type || "",
          admin: "Admin",
          timestamp: data.timestamp || new Date(),
        };
      });
      setRecentActivities(activities);
    });
    // Cleanup function returns all unsubscribe calls
    return () => {
      unsubscribeStudents();
      unsubscribeTeachers();
      unsubscribeActivities();
      // unsubscribeAssessments(); // REMOVED
    };
  }, [activeNicknames]); // Dependencies for useCallback

  useEffect(() => {
    const fetchStaticData = async () => {
      try {
        setLoading(true);

        // 1. Fetch Active Teacher Count
        const activeTeacherQuery = query(
          collection(db, "teacherRequests"),
          where("status", "==", "Active"),
        );
        const teacherSnapshot = await getDocs(activeTeacherQuery);
        setTeacherCount(teacherSnapshot.size);

        // 2. Fetch Pending Teacher Count
        const pendingTeacherQuery = query(
          collection(db, "teacherRequests"),
          where("status", "==", "Pending"),
        );
        const pendingSnapshot = await getDocs(pendingTeacherQuery);
        setPendingTeacherCount(pendingSnapshot.size);

        // 3. Fetch Total Student Count AND ACTIVE NICKNAMES
        const studentSnapshot = await getDocs(collection(db, "students"));
        setStudentCount(studentSnapshot.size);

        // Populate the active Nicknames Set (CRITICAL for filtering logins)
        const currentNicknames = new Set(
          studentSnapshot.docs.map((doc) => doc.data().nickname),
        );
        setActiveNicknames(currentNicknames);
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    // Fetch static counts and nicknames first
    fetchStaticData();
  }, []); // Static data fetch runs once

  useEffect(() => {
    // Only run the listeners once activeNicknames is populated
    if (activeNicknames.size > 0 || studentCount === 0) {
      // studentCount === 0 handles the case where there are no students, but we still want to set up teacher listeners
      const unsubscribe = updateLoginData();
      return () => unsubscribe();
    }
  }, [activeNicknames, studentCount, updateLoginData]); // Rerun when activeNicknames changes to initialize/re-run listeners

  const pieData = [
    { name: "Teachers", value: teacherCount, color: "#4CAF50" },
    { name: "Students", value: studentCount, color: "#FF9800" },
  ];

  // Helper component for the KPI Cards (remains the same)
  const KPICard = ({ title, value, icon, color }) => (
    <div className="kpi-card">
      <div className="kpi-content">
        <span className="kpi-title">{title}</span>
        <h2 className="kpi-value" style={{ color: color }}>
          {value}
        </h2>
      </div>
      <div className="kpi-icon-container" style={{ backgroundColor: color }}>
        {icon}
      </div>
    </div>
  );

  return (
    <div className="main-content">
      <h1 className="dashboard-title">Dashboard</h1>

      {loading ? (
        <p>Loading data...</p>
      ) : (
        <>
          {/* NEW: Key Performance Indicator (KPI) Cards */}
          <div className="kpi-container">
            <KPICard
              title="Pending Teachers"
              value={pendingTeacherCount}
              icon={<FaUserPlus />}
              color="#648ba2"
            />
            <KPICard
              title="Active Students"
              value={studentCount}
              icon={<FaUsers />}
              color="#FF9800"
            />
            {/* <KPICard // Removed Assessment Card
              title="Assessments Today"
              value={assessmentsToday}
              icon={<FaChartLine />}
              color="#4CAF50"
            /> */}
            <KPICard
              title="Active Teachers"
              value={teacherCount}
              icon={<FaCheckCircle />}
              color="#7CA1CC"
            />
          </div>

          <div className="charts-container">
            <div className="chart-card pie-chart">
              <h3>Total Teachers vs. Students</h3>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie
                    data={pieData}
                    dataKey="value"
                    innerRadius={60}
                    outerRadius={80}
                    startAngle={90}
                    endAngle={-270}
                    paddingAngle={5}
                    cornerRadius={5}
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value) => [`${value} users`, "Count"]} />
                  <Legend
                    layout="vertical"
                    align="right"
                    verticalAlign="middle"
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>

            <div className="chart-card bar-chart">
              <h3>Daily Logins (Past 7 Days)</h3>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={dailyActiveUsers}>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                    stroke="#f0f0f0"
                  />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} />
                  <YAxis axisLine={false} tickLine={false} />
                  <Tooltip />
                  <Bar
                    dataKey="students"
                    stackId="a"
                    fill="#FF9800"
                    name="Students"
                    radius={[4, 4, 0, 0]}
                  />
                  <Bar
                    dataKey="teachers"
                    stackId="a"
                    fill="#4CAF50"
                    name="Teachers"
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="recent-activity recent-activity-card">
            <h3>Recent Activity</h3>

            {/* ── Desktop: traditional table (hidden on mobile via CSS) ── */}
            <div className="recent-activity-table-wrapper">
              <table className="recent-activity-table">
                <thead>
                  <tr>
                    <th style={{ width: "15%" }}>Date</th>
                    <th style={{ width: "70%" }}>Action</th>
                    <th style={{ width: "15%" }}>Admin</th>
                  </tr>
                </thead>
                <tbody>
                  {recentActivities.map((activity) => {
                    const actionIcon =
                      activity.action.includes("Approved") ||
                      activity.action.includes("Activated")
                        ? "✅"
                        : activity.action.includes("Rejected") ||
                            activity.action.includes("Deactivated")
                          ? "❌"
                          : "⭐";
                    return (
                      <tr
                        key={activity.id}
                        className={`activity-row activity-row-${activity.type}`}
                      >
                        <td>
                          {activity.timestamp?.toDate
                            ? new Date(
                                activity.timestamp.toDate(),
                              ).toLocaleDateString()
                            : "N/A"}
                        </td>
                        <td>
                          {actionIcon} {activity.action}
                        </td>
                        <td>{activity.admin}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* ── Mobile: card layout (hidden on desktop via CSS) ── */}
            <div className="ra-card-list">
              {recentActivities.length === 0 ? (
                <p
                  style={{
                    color: "#94a3b8",
                    textAlign: "center",
                    padding: "24px 0",
                    fontSize: "0.9rem",
                  }}
                >
                  No recent activity to display.
                </p>
              ) : (
                recentActivities.map((activity) => {
                  const actionIcon =
                    activity.action.includes("Approved") ||
                    activity.action.includes("Activated")
                      ? "✅"
                      : activity.action.includes("Rejected") ||
                          activity.action.includes("Deactivated")
                        ? "❌"
                        : "⭐";

                  const dateStr = activity.timestamp?.toDate
                    ? new Date(activity.timestamp.toDate()).toLocaleDateString(
                        "en-US",
                        { month: "short", day: "numeric", year: "numeric" },
                      )
                    : "N/A";

                  return (
                    <div
                      key={activity.id}
                      className={`ra-card activity-row-${activity.type}`}
                    >
                      {/* Action text */}
                      <div className="ra-card-action">
                        {actionIcon} {activity.action}
                      </div>

                      {/* Date + Admin row */}
                      <div className="ra-card-meta">
                        <span className="ra-card-date">{dateStr}</span>
                        <span className="ra-card-admin">{activity.admin}</span>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default Dashboard;
