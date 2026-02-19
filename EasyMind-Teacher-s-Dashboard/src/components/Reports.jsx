import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { db, auth } from "../firebase";
import { collection, query, getDocs, where } from "firebase/firestore";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
} from "recharts";
import jsPDF from "jspdf";

function Reports() {
  const navigate = useNavigate();
  const [students, setStudents] = useState([]);
  const [dailyLogInChartData, setDailyLogInChartData] = useState([]);
  const [progressData, setProgressData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = React.useState("improved");
  const [showExportMessage, setShowExportMessage] = React.useState(false);
  const [searchTerm, setSearchTerm] = React.useState("");
  const [generatingPDF, setGeneratingPDF] = React.useState(false);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);

        const teacherId = auth.currentUser?.uid;
        if (!teacherId) {
          console.error("No authenticated teacher found.");
          setLoading(false);
          return;
        }

        const studentsQuery = query(
          collection(db, "students"),
          where("createdBy", "==", teacherId)
        );
        const studentsSnapshot = await getDocs(studentsQuery);
        const studentsData = studentsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

        const authorizedNicknames = studentsData
          .map((s) => s.nickname)
          .filter(Boolean);

        if (authorizedNicknames.length === 0) {
          setStudents([]);
          setDailyLogInChartData([]);
          setProgressData([]);
          setLoading(false);
          return;
        }

        const nicknameFilter = where(
          "nickname",
          "in",
          authorizedNicknames.slice(0, 10)
        );

        const userStatsQuery = query(
          collection(db, "userStats"),
          authorizedNicknames.length <= 10
            ? nicknameFilter
            : where("nickname", "!=", null)
        );
        const userStatsSnapshot = await getDocs(userStatsQuery);
        const userStatsData = {};

        userStatsSnapshot.forEach((doc) => {
          const data = doc.data();
          if (data.nickname && authorizedNicknames.includes(data.nickname)) {
            userStatsData[data.nickname] = data;
          }
        });

        const assessmentQuery = query(
          collection(db, "adaptiveAssessmentResults"),
          authorizedNicknames.length <= 10
            ? nicknameFilter
            : where("nickname", "!=", null)
        );
        const assessmentSnapshot = await getDocs(assessmentQuery);
        const assessmentResults = {};

        assessmentSnapshot.forEach((doc) => {
          const data = doc.data();
          if (data.nickname && authorizedNicknames.includes(data.nickname)) {
            if (!assessmentResults[data.nickname]) {
              assessmentResults[data.nickname] = [];
            }
            const enhancedData = {
              ...data,
              attemptNumber: 1,
              totalAttempts: 1,
              improvement: 0,
              contentId: data.contentId || null,
              attemptedQuestions: data.attemptedQuestions || [],
              correctQuestions: data.correctQuestions || [],
            };
            assessmentResults[data.nickname].push(enhancedData);
          }
        });

        Object.keys(assessmentResults).forEach((nickname) => {
          const studentAssessments = assessmentResults[nickname].sort(
            (a, b) =>
              (a.timestamp?.toDate() || new Date(0)) -
              (b.timestamp?.toDate() || new Date(0))
          );

          studentAssessments.forEach((assessment, index) => {
            assessment.attemptNumber = index + 1;
            assessment.totalAttempts = studentAssessments.length;
            assessment.improvement =
              index > 0
                ? (assessment.performance -
                    studentAssessments[index - 1].performance) *
                  100
                : 0;
          });
        });

        const lessonQuery = query(
          collection(db, "lessonRetention"),
          authorizedNicknames.length <= 10
            ? nicknameFilter
            : where("nickname", "!=", null)
        );
        const lessonSnapshot = await getDocs(lessonQuery);
        const lessonData = {};

        lessonSnapshot.forEach((doc) => {
          const data = doc.data();
          if (data.nickname && authorizedNicknames.includes(data.nickname)) {
            if (!lessonData[data.nickname]) {
              lessonData[data.nickname] = [];
            }
            lessonData[data.nickname].push(data);
          }
        });

        let gameData = {};
        try {
          if (authorizedNicknames.length <= 10) {
            const gameVisitQuery = query(
              collection(db, "visitTracking"),
              where("itemType", "==", "game"),
              nicknameFilter
            );
            const gameVisitSnapshot = await getDocs(gameVisitQuery);

            gameVisitSnapshot.forEach((doc) => {
              const data = doc.data();
              if (
                data.nickname &&
                authorizedNicknames.includes(data.nickname)
              ) {
                if (!gameData[data.nickname]) {
                  gameData[data.nickname] = [];
                }
                gameData[data.nickname].push(data);
              }
            });
          } else {
            const gameVisitQuery = query(
              collection(db, "visitTracking"),
              where("itemType", "==", "game")
            );
            const gameVisitSnapshot = await getDocs(gameVisitQuery);

            gameVisitSnapshot.forEach((doc) => {
              const data = doc.data();
              if (
                data.nickname &&
                authorizedNicknames.includes(data.nickname)
              ) {
                if (!gameData[data.nickname]) {
                  gameData[data.nickname] = [];
                }
                gameData[data.nickname].push(data);
              }
            });
          }
        } catch (gameError) {
          console.log("Game visits not available yet:", gameError);
        }

        const processedStudents = studentsData.map((student) => {
          const stats = userStatsData[student.nickname] || {};
          const assessments = assessmentResults[student.nickname] || [];
          const lessons = lessonData[student.nickname] || [];
          const games = gameData[student.nickname] || [];

          const avgPerformance =
            assessments.length > 0
              ? assessments.reduce((sum, a) => sum + (a.performance || 0), 0) /
                assessments.length
              : 0;

          const recentAssessment =
            assessments.length > 0
              ? assessments.sort(
                  (a, b) =>
                    (b.timestamp?.toDate() || new Date(0)) -
                    (a.timestamp?.toDate() || new Date(0))
                )[0]
              : null;

          const sortedAssessments = assessments.sort(
            (a, b) =>
              (a.timestamp?.toDate() || new Date(0)) -
              (b.timestamp?.toDate() || new Date(0))
          );
          const firstAttempt = sortedAssessments[0];
          const lastAttempt = sortedAssessments[sortedAssessments.length - 1];
          const overallImprovement =
            firstAttempt && lastAttempt
              ? (lastAttempt.performance - firstAttempt.performance) * 100
              : 0;

          const assessmentTypeCounts = {};
          assessments.forEach((assessment) => {
            const type = assessment.assessmentType || "unknown";
            assessmentTypeCounts[type] = (assessmentTypeCounts[type] || 0) + 1;
          });

          return {
            id: student.id,
            nickname: student.nickname,
            name:
              `${student.firstName || ""} ${student.surname || ""}`.trim() ||
              student.nickname,
            specialNeeds:
              (student.supportNeeds || []).join(", ") ||
              "Autism Spectrum Disorder",
            assessment:
              recentAssessment?.assessmentType || "No assessments yet",
            progress: {
              completed: Math.round(avgPerformance * 5),
              total: 5,
              target: 5,
            },
            attempts: assessments.length,
            avatar: student.nickname?.substring(0, 2).toUpperCase() || "ST",
            isImproved: assessments.length > 0 && avgPerformance >= 0.7,
            totalXP: stats.totalXP || 0,
            level: stats.currentLevel || student.currentLevel || 1,
            streakDays: stats.streakDays || student.currentStreak || 0,
            lessonsCompleted: lessons.length,
            gamesPlayed: games.length,
            totalActivities: assessments.length + lessons.length + games.length,
            assessmentDetails: {
              totalAttempts: assessments.length,
              averageScore: Math.round(avgPerformance * 100),
              bestScore:
                assessments.length > 0
                  ? Math.round(
                      Math.max(...assessments.map((a) => a.performance)) * 100
                    )
                  : 0,
              latestScore: recentAssessment
                ? Math.round(recentAssessment.performance * 100)
                : 0,
              overallImprovement: Math.round(overallImprovement),
              assessmentTypeCounts: assessmentTypeCounts,
              recentAssessment: recentAssessment,
              allAssessments: assessments,
            },
          };
        });

        setStudents(processedStudents);

        const fiveWeeksAgo = new Date();
        fiveWeeksAgo.setDate(fiveWeeksAgo.getDate() - 35);

        let progressSnapshot;
        if (authorizedNicknames.length <= 10) {
          const progressQuery = query(
            collection(db, "adaptiveAssessmentResults"),
            where("timestamp", ">=", fiveWeeksAgo),
            nicknameFilter
          );
          progressSnapshot = await getDocs(progressQuery);
        } else {
          const progressQuery = query(
            collection(db, "adaptiveAssessmentResults"),
            where("timestamp", ">=", fiveWeeksAgo)
          );
          progressSnapshot = await getDocs(progressQuery);
        }

        const weeklyStudentPerformance = {};

        progressSnapshot.forEach((doc) => {
          const data = doc.data();
          const timestamp = data.timestamp?.toDate();

          if (
            timestamp &&
            data.nickname &&
            authorizedNicknames.includes(data.nickname)
          ) {
            const weekStart = new Date(timestamp);
            weekStart.setDate(weekStart.getDate() - weekStart.getDay());
            weekStart.setHours(0, 0, 0, 0);
            const weekKey = weekStart.toISOString().split("T")[0];

            if (!weeklyStudentPerformance[weekKey]) {
              weeklyStudentPerformance[weekKey] = {};
            }

            if (!weeklyStudentPerformance[weekKey][data.nickname]) {
              weeklyStudentPerformance[weekKey][data.nickname] = [];
            }

            weeklyStudentPerformance[weekKey][data.nickname].push(
              data.performance || 0
            );
          }
        });

        const currentImproved = processedStudents.filter(
          (s) => s.isImproved
        ).length;
        const currentNeedsImprovement = processedStudents.filter(
          (s) => !s.isImproved
        ).length;

        const weekKeys = Object.keys(weeklyStudentPerformance).sort();

        let progressChartData = [];

        if (weekKeys.length > 0) {
          const recentWeeks = weekKeys.slice(-5);

          while (recentWeeks.length < 5) {
            recentWeeks.unshift(null);
          }

          progressChartData = recentWeeks.map((weekKey, index) => {
            if (!weekKey) {
              return {
                name: `Week ${index + 1}`,
                "Improved Students": 0,
                "Needs Improvement": 0,
              };
            }

            const studentsThisWeek = weeklyStudentPerformance[weekKey];
            let improvedCount = 0;
            let needsImprovementCount = 0;

            Object.keys(studentsThisWeek).forEach((nickname) => {
              const performances = studentsThisWeek[nickname];
              const avgPerformance =
                performances.reduce((sum, p) => sum + p, 0) /
                performances.length;

              if (avgPerformance >= 0.7) {
                improvedCount++;
              } else {
                needsImprovementCount++;
              }
            });

            return {
              name: `Week ${index + 1}`,
              "Improved Students": improvedCount,
              "Needs Improvement": needsImprovementCount,
            };
          });

          const lastWeek = progressChartData[progressChartData.length - 1];
          const totalInLastWeek =
            lastWeek["Improved Students"] + lastWeek["Needs Improvement"];
          const currentTotal = currentImproved + currentNeedsImprovement;

          if (totalInLastWeek < currentTotal) {
            progressChartData[progressChartData.length - 1] = {
              name: `Week 5`,
              "Improved Students": currentImproved,
              "Needs Improvement": currentNeedsImprovement,
            };
          }
        } else {
          progressChartData = Array.from({ length: 5 }, (_, index) => {
            const weekProgress = (index + 1) / 5;
            return {
              name: `Week ${index + 1}`,
              "Improved Students": Math.round(currentImproved * weekProgress),
              "Needs Improvement": Math.round(
                currentNeedsImprovement * weekProgress
              ),
            };
          });

          progressChartData[4] = {
            name: "Week 5",
            "Improved Students": currentImproved,
            "Needs Improvement": currentNeedsImprovement,
          };
        }

        console.log("Progress Chart Data:", progressChartData);
        console.log(
          "Current Improved:",
          currentImproved,
          "Current Needs Improvement:",
          currentNeedsImprovement
        );

        setProgressData(progressChartData);

        const logInData = {};
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const dayOfWeek = today.getDay();
        const daysToSubtract = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
        const monday = new Date(today);
        monday.setDate(today.getDate() - daysToSubtract);
        monday.setHours(0, 0, 0, 0);

        const daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        const dateKeys = [];

        for (let i = 0; i < 7; i++) {
          const d = new Date(monday);
          d.setDate(monday.getDate() + i);
          const dateString = d.toISOString().split("T")[0];
          dateKeys.push(dateString);
          logInData[dateString] = { activeStudents: 0 };
        }

        const sundayEnd = new Date(monday);
        sundayEnd.setDate(monday.getDate() + 7);

        let visitSnapshot;
        if (authorizedNicknames.length <= 10) {
          const visitQuery = query(
            collection(db, "visitTracking"),
            where("timestamp", ">=", monday),
            where("timestamp", "<", sundayEnd),
            nicknameFilter
          );
          visitSnapshot = await getDocs(visitQuery);
        } else {
          const visitQuery = query(
            collection(db, "visitTracking"),
            where("timestamp", ">=", monday),
            where("timestamp", "<", sundayEnd)
          );
          visitSnapshot = await getDocs(visitQuery);
        }

        const studentDailyActivity = {};
        const todayDateString = today.toISOString().split("T")[0];

        visitSnapshot.forEach((doc) => {
          const data = doc.data();
          const timestamp = data.timestamp?.toDate();
          if (
            timestamp &&
            data.nickname &&
            authorizedNicknames.includes(data.nickname)
          ) {
            const dateString = timestamp.toISOString().split("T")[0];

            if (logInData[dateString]) {
              if (!studentDailyActivity[dateString]) {
                studentDailyActivity[dateString] = new Set();
              }
              studentDailyActivity[dateString].add(data.nickname);
            }
          }
        });

        const dailyLogInChartData = dateKeys.map((dateKey, index) => {
          // Only show data for days up to today
          const dayDate = new Date(dateKey);
          const isFutureDay = dayDate > today;

          return {
            name: daysOfWeek[index],
            "Active Students": isFutureDay
              ? 0
              : studentDailyActivity[dateKey]?.size || 0,
          };
        });

        setDailyLogInChartData(dailyLogInChartData);
      } catch (error) {
        console.error("Error fetching reports data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const generatePDF = async () => {
    try {
      setGeneratingPDF(true);

      const studentsToExport = filteredStudents;

      if (!studentsToExport || studentsToExport.length === 0) {
        alert(
          "No student data available to generate report. Please check your filters."
        );
        return;
      }

      const pdf = new jsPDF("p", "mm", "a4");
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = pdf.internal.pageSize.getHeight();
      const margin = 20;
      const contentWidth = pageWidth - margin * 2;
      let yPosition = 0;

      const addNewPage = () => {
        pdf.addPage();
        yPosition = margin;

        pdf.setFillColor(79, 70, 229);
        pdf.rect(0, 0, pageWidth, 15, "F");
        pdf.setTextColor(255, 255, 255);
        pdf.setFontSize(10);
        pdf.setFont("helvetica", "normal");
        pdf.text("EasyMind Student Progress Report", pageWidth / 2, 10, {
          align: "center",
        });
        pdf.setTextColor(0, 0, 0);
        yPosition = 25;
      };

      const checkSpace = (requiredSpace) => {
        if (yPosition + requiredSpace > pageHeight - 20) {
          addNewPage();
          return true;
        }
        return false;
      };

      pdf.setFillColor(79, 70, 229);
      pdf.rect(0, 0, pageWidth, 50, "F");

      pdf.setDrawColor(99, 90, 249);
      for (let i = 0; i < 5; i++) {
        pdf.setLineWidth(0.5);
        pdf.line(0, 10 + i * 8, pageWidth, 10 + i * 8);
      }

      pdf.setTextColor(255, 255, 255);
      pdf.setFontSize(26);
      pdf.setFont("helvetica", "bold");
      pdf.text("EasyMind", pageWidth / 2, 20, { align: "center" });

      pdf.setFontSize(16);
      pdf.setFont("helvetica", "normal");
      pdf.text("Student Progress Report", pageWidth / 2, 30, {
        align: "center",
      });

      pdf.setFontSize(10);
      const currentDate = new Date().toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
      pdf.text(`Generated: ${currentDate}`, pageWidth / 2, 42, {
        align: "center",
      });

      pdf.setTextColor(0, 0, 0);
      yPosition = 60;

      pdf.setFillColor(248, 249, 250);
      pdf.roundedRect(margin, yPosition, contentWidth, 65, 3, 3, "F");

      yPosition += 10;
      pdf.setFontSize(18);
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(79, 70, 229);
      pdf.text("Executive Summary", margin + 5, yPosition);

      yPosition += 12;

      const totalStudents = students.length;
      const improvedStudents = students.filter((s) => s.isImproved).length;
      const needsImprovement = totalStudents - improvedStudents;
      const improvementRate =
        totalStudents > 0
          ? Math.round((improvedStudents / totalStudents) * 100)
          : 0;
      const totalAssessments = students.reduce(
        (sum, s) => sum + (s.attempts || 0),
        0
      );
      const avgScore =
        totalStudents > 0
          ? Math.round(
              students.reduce(
                (sum, s) => sum + (s.assessmentDetails?.averageScore || 0),
                0
              ) / totalStudents
            )
          : 0;

      const statBoxWidth = (contentWidth - 20) / 3;
      const statBoxHeight = 35;
      const statStartX = margin + 5;

      const stats = [
        {
          label: "Total Students",
          value: totalStudents,
          color: [99, 102, 241],
        },
        { label: "Improved", value: improvedStudents, color: [34, 197, 94] },
        { label: "Needs Work", value: needsImprovement, color: [239, 68, 68] },
        {
          label: "Total Assessments",
          value: totalAssessments,
          color: [59, 130, 246],
        },
        {
          label: "Improvement Rate",
          value: `${improvementRate}%`,
          color: [168, 85, 247],
        },
        { label: "Avg Score", value: `${avgScore}%`, color: [249, 115, 22] },
      ];

      stats.forEach((stat, index) => {
        const col = index % 3;
        const row = Math.floor(index / 3);
        const x = statStartX + col * statBoxWidth + col * 5;
        const y = yPosition + row * statBoxHeight + row * 2;

        pdf.setFillColor(255, 255, 255);
        pdf.roundedRect(x, y, statBoxWidth - 5, statBoxHeight - 2, 2, 2, "F");

        pdf.setFillColor(...stat.color);
        pdf.rect(x, y, 3, statBoxHeight - 2, "F");

        pdf.setFontSize(20);
        pdf.setFont("helvetica", "bold");
        pdf.setTextColor(...stat.color);
        pdf.text(String(stat.value), x + statBoxWidth / 2, y + 15, {
          align: "center",
        });

        pdf.setFontSize(9);
        pdf.setFont("helvetica", "normal");
        pdf.setTextColor(100, 100, 100);
        pdf.text(stat.label, x + statBoxWidth / 2, y + 25, { align: "center" });
      });

      pdf.setTextColor(0, 0, 0);
      yPosition += 80;

      checkSpace(40);

      pdf.setFontSize(16);
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(79, 70, 229);
      pdf.text("Key Insights", margin, yPosition);
      yPosition += 10;

      pdf.setFontSize(10);
      pdf.setFont("helvetica", "normal");
      pdf.setTextColor(60, 60, 60);

      const insights = [
        `${improvementRate}% of students show positive progress trends`,
        `Average assessment score across all students is ${avgScore}%`,
        `${totalAssessments} total assessments completed`,
        `${
          students.filter((s) => s.totalXP > 0).length
        } students actively earning XP`,
      ];

      insights.forEach((insight) => {
        pdf.setFillColor(240, 240, 255);
        pdf.circle(margin + 3, yPosition + 2, 1.5, "F");
        pdf.text(insight, margin + 8, yPosition + 3);
        yPosition += 7;
      });

      pdf.setTextColor(0, 0, 0);
      yPosition += 5;

      addNewPage();

      pdf.setFontSize(18);
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(79, 70, 229);
      pdf.text(
        `Detailed Student Performance (${
          activeTab === "improved" ? "Improved" : "Needs Improvement"
        } Students)`,
        margin,
        yPosition
      );
      yPosition += 10;

      const colWidths = {
        name: 45,
        assessment: 35,
        avgScore: 22,
        best: 20,
        xp: 18,
        level: 15,
        status: 25,
      };

      pdf.setFillColor(79, 70, 229);
      pdf.rect(margin, yPosition, contentWidth, 10, "F");

      pdf.setTextColor(255, 255, 255);
      pdf.setFontSize(9);
      pdf.setFont("helvetica", "bold");

      let colX = margin + 2;
      pdf.text("STUDENT NAME", colX, yPosition + 7);
      colX += colWidths.name;
      pdf.text("ASSESSMENT", colX, yPosition + 7);
      colX += colWidths.assessment;
      pdf.text("AVG", colX, yPosition + 7);
      colX += colWidths.avgScore;
      pdf.text("BEST", colX, yPosition + 7);
      colX += colWidths.best;
      pdf.text("XP", colX, yPosition + 7);
      colX += colWidths.xp;
      pdf.text("LVL", colX, yPosition + 7);
      colX += colWidths.level;
      pdf.text("STATUS", colX, yPosition + 7);

      yPosition += 12;
      pdf.setTextColor(0, 0, 0);

      const sortedStudents = [...studentsToExport].sort(
        (a, b) =>
          (b.assessmentDetails?.averageScore || 0) -
          (a.assessmentDetails?.averageScore || 0)
      );

      sortedStudents.forEach((student, index) => {
        checkSpace(12);

        if (index % 2 === 0) {
          pdf.setFillColor(248, 249, 250);
          pdf.rect(margin, yPosition - 3, contentWidth, 10, "F");
        }

        pdf.setFontSize(9);
        pdf.setFont("helvetica", "normal");

        colX = margin + 2;

        const maxNameLength = 28;
        const displayName =
          student.name.length > maxNameLength
            ? student.name.substring(0, maxNameLength - 2) + ".."
            : student.name;
        pdf.text(displayName, colX, yPosition + 4);
        colX += colWidths.name;

        const maxAssessmentLength = 18;
        const displayAssessment =
          student.assessment.length > maxAssessmentLength
            ? student.assessment.substring(0, maxAssessmentLength - 2) + ".."
            : student.assessment;
        pdf.text(displayAssessment, colX, yPosition + 4);
        colX += colWidths.assessment;

        const avgScore = student.assessmentDetails?.averageScore || 0;
        if (avgScore >= 80) {
          pdf.setTextColor(34, 197, 94);
        } else if (avgScore >= 60) {
          pdf.setTextColor(234, 179, 8);
        } else {
          pdf.setTextColor(239, 68, 68);
        }
        pdf.setFont("helvetica", "bold");
        pdf.text(`${avgScore}%`, colX, yPosition + 4);
        colX += colWidths.avgScore;

        pdf.setFont("helvetica", "normal");
        pdf.setTextColor(100, 100, 100);
        pdf.text(
          `${student.assessmentDetails?.bestScore || 0}%`,
          colX,
          yPosition + 4
        );
        colX += colWidths.best;

        pdf.setTextColor(0, 0, 0);
        pdf.text(`${student.totalXP || 0}`, colX, yPosition + 4);
        colX += colWidths.xp;

        pdf.text(`${student.level || 1}`, colX, yPosition + 4);
        colX += colWidths.level;

        pdf.setFontSize(8);
        if (student.isImproved) {
          pdf.setTextColor(22, 101, 52);
          pdf.setFillColor(220, 252, 231);
          pdf.roundedRect(colX - 1, yPosition, 22, 6, 1, 1, "F");
          pdf.text("Improved", colX + 11, yPosition + 4, { align: "center" });
        } else {
          pdf.setTextColor(153, 27, 27);
          pdf.setFillColor(254, 226, 226);
          pdf.roundedRect(colX - 1, yPosition, 22, 6, 1, 1, "F");
          pdf.text("At Risk", colX + 11, yPosition + 4, { align: "center" });
        }

        pdf.setTextColor(0, 0, 0);
        pdf.setFontSize(9);
        yPosition += 10;
      });

      checkSpace(50);
      yPosition += 10;

      pdf.setFontSize(18);
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(79, 70, 229);
      pdf.text("Class Assessment Performance Analysis", margin, yPosition);
      yPosition += 10;

      const assessmentTypes = [
        "alphabet",
        "colors",
        "shapes",
        "numbers",
        "general",
        "pictureStory",
        "dailyTasks",
        "socialInteraction",
        "rhyme",
        "sounds",
        "social_interaction",
      ];
      const uniqueAssessmentTypes = [...new Set(assessmentTypes)];
      const assessmentStats = [];

      uniqueAssessmentTypes.forEach((type) => {
        const studentPerformances = [];

        studentsToExport.forEach((student) => {
          const studentTypeAssessments =
            student.assessmentDetails.allAssessments.filter(
              (a) => a.assessmentType === type
            );

          if (studentTypeAssessments.length > 0) {
            const avgPerformance =
              studentTypeAssessments.reduce(
                (sum, a) => sum + (a.performance || 0),
                0
              ) / studentTypeAssessments.length;
            const latestAttempt = studentTypeAssessments.sort(
              (a, b) =>
                (b.timestamp?.toDate() || new Date(0)) -
                (a.timestamp?.toDate() || new Date(0))
            )[0];

            studentPerformances.push({
              studentName: student.name,
              avgScore: Math.round(avgPerformance * 100),
              latestScore: Math.round((latestAttempt.performance || 0) * 100),
              totalAttempts: studentTypeAssessments.length,
            });
          }
        });

        if (studentPerformances.length === 0) return;

        const allScores = studentPerformances.map((sp) => sp.avgScore);
        const classAvg = Math.round(
          allScores.reduce((sum, s) => sum + s, 0) / allScores.length
        );
        const minScore = Math.min(...allScores);
        const maxScore = Math.max(...allScores);
        const totalStudents = studentPerformances.length;

        const excellent = studentPerformances.filter(
          (sp) => sp.avgScore >= 80
        ).length;
        const good = studentPerformances.filter(
          (sp) => sp.avgScore >= 60 && sp.avgScore < 80
        ).length;
        const needsWork = studentPerformances.filter(
          (sp) => sp.avgScore < 60
        ).length;

        const sortedStudents = [...studentPerformances].sort(
          (a, b) => b.avgScore - a.avgScore
        );
        const topPerformers = sortedStudents.slice(0, 3);
        const needsAttention = sortedStudents.slice(-3).reverse();

        assessmentStats.push({
          name: type.charAt(0).toUpperCase() + type.slice(1).replace("_", " "),
          classAvg,
          minScore,
          maxScore,
          totalStudents,
          excellent,
          good,
          needsWork,
          topPerformers,
          needsAttention,
        });
      });

      if (assessmentStats.length === 0) {
        pdf.setFontSize(10);
        pdf.setFont("helvetica", "italic");
        pdf.setTextColor(100, 100, 100);
        pdf.text(
          "No assessment data available yet.",
          margin + 5,
          yPosition + 5
        );
        yPosition += 15;
      } else {
        assessmentStats.forEach((stat) => {
          checkSpace(45);

          pdf.setFillColor(79, 70, 229);
          pdf.roundedRect(margin, yPosition, contentWidth, 10, 2, 2, "F");

          pdf.setFontSize(12);
          pdf.setFont("helvetica", "bold");
          pdf.setTextColor(255, 255, 255);
          pdf.text(stat.name, margin + 5, yPosition + 7);

          pdf.setFillColor(255, 255, 255);
          pdf.roundedRect(
            margin + contentWidth - 40,
            yPosition + 2,
            35,
            6,
            1,
            1,
            "F"
          );
          pdf.setTextColor(79, 70, 229);
          pdf.setFontSize(8);
          pdf.text(
            `${stat.totalStudents} students`,
            margin + contentWidth - 22.5,
            yPosition + 6,
            { align: "center" }
          );

          yPosition += 12;

          pdf.setFillColor(248, 249, 250);
          pdf.roundedRect(margin, yPosition, contentWidth, 20, 2, 2, "F");

          yPosition += 7;
          pdf.setFontSize(10);
          pdf.setFont("helvetica", "bold");
          pdf.setTextColor(79, 70, 229);
          pdf.text("Class Performance:", margin + 5, yPosition);

          pdf.setFont("helvetica", "normal");
          pdf.setTextColor(60, 60, 60);
          pdf.setFontSize(9);

          const statsX = margin + 45;
          pdf.text(`Average: `, statsX, yPosition);
          pdf.setFont("helvetica", "bold");
          pdf.text(`${stat.classAvg}%`, statsX + 20, yPosition);

          pdf.setFont("helvetica", "normal");
          pdf.text(`Range: `, statsX + 40, yPosition);
          pdf.setFont("helvetica", "bold");
          pdf.text(
            `${stat.minScore}%-${stat.maxScore}%`,
            statsX + 55,
            yPosition
          );

          yPosition += 7;

          pdf.setFont("helvetica", "normal");
          pdf.setTextColor(60, 60, 60);
          pdf.setFontSize(8);

          let distX = margin + 5;

          pdf.setFillColor(220, 252, 231);
          pdf.roundedRect(distX, yPosition - 3, 35, 6, 1, 1, "F");
          pdf.setTextColor(22, 101, 52);
          pdf.text(`Excellent: ${stat.excellent}`, distX + 17.5, yPosition, {
            align: "center",
          });
          distX += 40;

          pdf.setFillColor(254, 243, 199);
          pdf.roundedRect(distX, yPosition - 3, 30, 6, 1, 1, "F");
          pdf.setTextColor(146, 64, 14);
          pdf.text(`Good: ${stat.good}`, distX + 15, yPosition, {
            align: "center",
          });
          distX += 35;

          pdf.setFillColor(254, 226, 226);
          pdf.roundedRect(distX, yPosition - 3, 40, 6, 1, 1, "F");
          pdf.setTextColor(153, 27, 27);
          pdf.text(`Needs Work: ${stat.needsWork}`, distX + 20, yPosition, {
            align: "center",
          });

          yPosition += 10;

          if (stat.topPerformers.length > 0) {
            checkSpace(15);

            pdf.setFontSize(9);
            pdf.setFont("helvetica", "bold");
            pdf.setTextColor(34, 197, 94);
            pdf.text("Top Performers:", margin + 5, yPosition);
            yPosition += 5;

            pdf.setFontSize(8);
            pdf.setFont("helvetica", "normal");
            pdf.setTextColor(60, 60, 60);

            stat.topPerformers.forEach((student, index) => {
              checkSpace(5);
              pdf.text(
                `${index + 1}. ${student.studentName}`,
                margin + 8,
                yPosition
              );
              pdf.setFont("helvetica", "bold");
              pdf.setTextColor(34, 197, 94);
              pdf.text(`${student.avgScore}%`, margin + 80, yPosition);
              pdf.setFont("helvetica", "normal");
              pdf.setTextColor(100, 100, 100);
              pdf.text(
                `(${student.totalAttempts} attempts)`,
                margin + 95,
                yPosition
              );
              pdf.setTextColor(60, 60, 60);
              yPosition += 4;
            });

            yPosition += 3;
          }

          if (
            stat.needsAttention.length > 0 &&
            stat.needsAttention[0].avgScore < 70
          ) {
            checkSpace(15);

            pdf.setFontSize(9);
            pdf.setFont("helvetica", "bold");
            pdf.setTextColor(239, 68, 68);
            pdf.text("Needs Attention:", margin + 5, yPosition);
            yPosition += 5;

            pdf.setFontSize(8);
            pdf.setFont("helvetica", "normal");
            pdf.setTextColor(60, 60, 60);

            stat.needsAttention.forEach((student) => {
              if (student.avgScore < 70) {
                checkSpace(5);
                pdf.text(`• ${student.studentName}`, margin + 8, yPosition);
                pdf.setFont("helvetica", "bold");
                pdf.setTextColor(239, 68, 68);
                pdf.text(`${student.avgScore}%`, margin + 80, yPosition);
                pdf.setFont("helvetica", "normal");
                pdf.setTextColor(100, 100, 100);
                pdf.text(
                  `(${student.totalAttempts} attempts)`,
                  margin + 95,
                  yPosition
                );
                pdf.setTextColor(60, 60, 60);
                yPosition += 4;
              }
            });

            yPosition += 3;
          }

          yPosition += 8;
        });

        yPosition += 5;
        checkSpace(30);

        pdf.setFillColor(255, 251, 235);
        pdf.roundedRect(margin, yPosition, contentWidth, 28, 2, 2, "F");

        pdf.setFontSize(9);
        pdf.setFont("helvetica", "bold");
        pdf.setTextColor(146, 64, 14);
        pdf.text("Understanding the Analysis:", margin + 5, yPosition + 7);

        pdf.setFont("helvetica", "normal");
        pdf.setTextColor(80, 80, 80);
        pdf.setFontSize(8);
        const explanation =
          "This analysis shows class-wide performance for each assessment type. " +
          "Performance levels: Excellent (80%+), Good (60-79%), Needs Work (<60%). " +
          "Top performers and students needing attention are highlighted to help identify where to focus support efforts.";
        const splitExplanation = pdf.splitTextToSize(
          explanation,
          contentWidth - 10
        );
        pdf.text(splitExplanation, margin + 5, yPosition + 13);

        yPosition += 33;
      }

      const totalPages = pdf.internal.getNumberOfPages();
      for (let i = 1; i <= totalPages; i++) {
        pdf.setPage(i);

        pdf.setDrawColor(200, 200, 200);
        pdf.setLineWidth(0.5);
        pdf.line(margin, pageHeight - 15, pageWidth - margin, pageHeight - 15);

        pdf.setFontSize(8);
        pdf.setTextColor(120, 120, 120);
        pdf.text(
          `EasyMind Learning Platform | Page ${i} of ${totalPages}`,
          pageWidth / 2,
          pageHeight - 10,
          { align: "center" }
        );
        pdf.text(
          `Generated: ${new Date().toLocaleDateString("en-US")}`,
          pageWidth - margin,
          pageHeight - 10,
          { align: "right" }
        );
      }

      const fileName = `EasyMind_Report_${
        new Date().toISOString().split("T")[0]
      }.pdf`;
      pdf.save(fileName);

      setShowExportMessage(true);
      setTimeout(() => setShowExportMessage(false), 3000);
    } catch (error) {
      console.error("Error generating PDF:", error);
      alert(`Failed to generate PDF: ${error.message}. Please try again.`);
    } finally {
      setGeneratingPDF(false);
    }
  };

  const filteredStudents = students.filter((student) => {
    const matchesTab =
      activeTab === "improved" ? student.isImproved : !student.isImproved;

    const lowerCaseSearchTerm = searchTerm.toLowerCase();
    const matchesSearch =
      student.name.toLowerCase().includes(lowerCaseSearchTerm) ||
      student.nickname.toLowerCase().includes(lowerCaseSearchTerm);

    return matchesTab && matchesSearch;
  });

  return (
    <div className="container-fluid bg-light-gray py-4" id="reports-content">
      <style jsx>{`
        .metric-value {
          font-size: 1.5rem;
          line-height: 1;
        }

        .metric-label {
          font-size: 0.75rem;
          margin-top: 0.25rem;
        }

        .card {
          transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
        }

        .card:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1) !important;
        }

        .table th {
          font-weight: 600;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .badge {
          font-size: 0.75rem;
          padding: 0.5em 0.75em;
        }

        .export-btn {
          min-width: 120px;
        }

        .compact-btn {
          padding: 0.5rem 1rem;
          font-size: 0.875rem;
        }
      `}</style>
      {loading ? (
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="mt-3">Loading student progress data...</p>
        </div>
      ) : (
        <>
          <header className="d-flex flex-column flex-sm-row justify-content-between align-items-start align-items-sm-center mb-4">
            <h1 className="h3 fw-bold text-dark mb-3 mb-sm-0">
              Student Progress Reports
            </h1>
            <div className="d-flex flex-column flex-sm-row align-items-center gap-2">
              <input
                type="text"
                className="form-control custom-search-input"
                placeholder="Search"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              <button
                className="btn btn-success export-btn"
                onClick={generatePDF}
                disabled={generatingPDF}
              >
                {generatingPDF ? (
                  <>
                    <span className="spinner-border spinner-border-sm me-2"></span>
                    Generating...
                  </>
                ) : (
                  <>
                    <i className="bi bi-file-pdf me-2"></i>Export PDF
                  </>
                )}
              </button>
            </div>
          </header>

          {showExportMessage && (
            <div
              className="alert alert-success alert-dismissible fade show"
              role="alert"
            >
              Report exported successfully!
              <button
                type="button"
                className="btn-close"
                onClick={() => setShowExportMessage(false)}
                aria-label="Close"
              ></button>
            </div>
          )}

          <section className="row g-4 mb-4">
            <div className="col-12 col-sm-6 col-lg-3">
              <div className="card shadow-sm rounded-lg h-100 p-4 d-flex flex-row align-items-center justify-content-between">
                <div>
                  <div className="text-secondary mb-1">Improved Students</div>
                  <div className="h2 fw-bold text-dark">
                    {students.filter((s) => s.isImproved).length}
                  </div>
                  <div className="text-success small d-flex align-items-center">
                    <i className="bi bi-arrow-up-short me-1"></i>
                    {students.length > 0
                      ? Math.round(
                          (students.filter((s) => s.isImproved).length /
                            students.length) *
                            100
                        )
                      : 0}
                    % of total students
                  </div>
                </div>
                <div className="icon-circle bg-success-light">
                  <i className="bi bi-person-fill-up text-success icon-large"></i>
                </div>
              </div>
            </div>

            <div className="col-12 col-sm-6 col-lg-3">
              <div className="card shadow-sm rounded-lg h-100 p-4 d-flex flex-row align-items-center justify-content-between">
                <div>
                  <div className="text-secondary mb-1">Needs Improvement</div>
                  <div className="h2 fw-bold text-dark">
                    {students.filter((s) => !s.isImproved).length}
                  </div>
                  <div className="text-danger small d-flex align-items-center">
                    <i className="bi bi-arrow-down-short me-1"></i>
                    {students.length > 0
                      ? Math.round(
                          (students.filter((s) => !s.isImproved).length /
                            students.length) *
                            100
                        )
                      : 0}
                    % of total students
                  </div>
                </div>
                <div className="icon-circle bg-danger-light">
                  <i className="bi bi-person-fill-down text-danger icon-large"></i>
                </div>
              </div>
            </div>

            <div className="col-12 col-sm-6 col-lg-3">
              <div className="card shadow-sm rounded-lg h-100 p-4 d-flex flex-row align-items-center justify-content-between">
                <div>
                  <div className="text-secondary mb-1">Assessment Attempts</div>
                  <div className="h2 fw-bold text-dark">
                    {students.reduce((sum, s) => sum + s.attempts, 0)}
                  </div>
                  <div className="text-info small d-flex align-items-center">
                    <i className="bi bi-plus-lg me-1"></i>
                    {new Set(students.map((s) => s.assessment)).size} different
                    types
                  </div>
                </div>
                <div className="icon-circle bg-info-light">
                  <i className="bi bi-journal-check text-info icon-large"></i>
                </div>
              </div>
            </div>

            <div className="col-12 col-sm-6 col-lg-3">
              <div className="card shadow-sm rounded-lg h-100 p-4 d-flex flex-row align-items-center justify-content-between">
                <div>
                  <div className="text-secondary mb-1">Total Students</div>
                  <div className="h2 fw-bold text-dark">{students.length}</div>
                  <div className="text-purple small d-flex align-items-center">
                    <i className="bi bi-people-fill me-1"></i>
                  </div>
                </div>
                <div className="icon-circle bg-purple-light">
                  <i className="bi bi-people-fill text-purple icon-large"></i>
                </div>
              </div>
            </div>
          </section>

          <section className="row g-4 mb-4">
            <div className="col-12 col-lg-6">
              <div className="card shadow-sm rounded-lg p-4 h-100">
                <h2 className="h5 fw-semibold text-dark mb-4">
                  Progress Over Time
                </h2>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart
                    data={progressData}
                    margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis
                      dataKey="name"
                      stroke="#64748b"
                      style={{ fontSize: "0.875rem" }}
                    />
                    <YAxis stroke="#64748b" style={{ fontSize: "0.875rem" }} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: "#ffffff",
                        border: "1px solid #e5e7eb",
                        borderRadius: "8px",
                        boxShadow: "0 4px 6px rgba(0, 0, 0, 0.1)",
                      }}
                    />
                    <Legend
                      wrapperStyle={{ paddingTop: "20px" }}
                      iconType="circle"
                    />
                    <Line
                      type="monotone"
                      dataKey="Improved Students"
                      stroke="#10B981"
                      strokeWidth={2}
                      dot={{ fill: "#10B981", r: 4 }}
                      activeDot={{ r: 6 }}
                    />
                    <Line
                      type="monotone"
                      dataKey="Needs Improvement"
                      stroke="#EF4444"
                      strokeWidth={2}
                      dot={{ fill: "#EF4444", r: 4 }}
                      activeDot={{ r: 6 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="col-12 col-lg-6">
              <div className="card shadow-sm rounded-lg p-4 h-100">
                <h2 className="h5 fw-semibold text-dark mb-4">
                  Daily Active Students (Last 7 Days)
                </h2>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart
                    data={dailyLogInChartData}
                    margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis
                      dataKey="name"
                      interval={0}
                      style={{ fontSize: "0.875rem" }}
                    />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="Active Students" fill="#4F46E5" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </section>

          <section className="card shadow-sm reports-student-table-bootstrap">
            <div className="card-body">
              <ul className="nav nav-tabs mb-3">
                <li className="nav-item">
                  <button
                    className={`nav-link ${
                      activeTab === "improved" ? "active" : ""
                    }`}
                    onClick={() => setActiveTab("improved")}
                  >
                    Improved Students (
                    {students.filter((s) => s.isImproved).length})
                  </button>
                </li>
                <li className="nav-item">
                  <button
                    className={`nav-link ${
                      activeTab === "needsImprovement" ? "active" : ""
                    }`}
                    onClick={() => setActiveTab("needsImprovement")}
                  >
                    Needs Improvement (
                    {students.filter((s) => !s.isImproved).length})
                  </button>
                </li>
              </ul>
              <div className="table-responsive">
                <table className="table table-hover align-middle">
                  <thead>
                    <tr>
                      <th scope="col">STUDENT</th>
                      <th scope="col">ASSESSMENT</th>
                      <th scope="col">PROGRESS</th>
                      <th scope="col">ATTEMPTS</th>
                      <th scope="col">ACTIONS</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredStudents.length > 0 ? (
                      filteredStudents.map((student) => (
                        <tr key={student.id}>
                          <td>
                            <div className="d-flex align-items-center">
                              <div className="student-avatar-bootstrap me-3">
                                {student.avatar}
                              </div>
                              <div>
                                <p className="mb-0 fw-bold">{student.name}</p>
                                <p className="mb-0 text-muted small">
                                  {student.specialNeeds}
                                </p>
                              </div>
                            </div>
                          </td>
                          <td>{student.assessment}</td>
                          <td>
                            <div className="d-flex align-items-center gap-2">
                              <span className="text-muted small">
                                {student.assessmentDetails.averageScore}%
                              </span>
                              <div
                                className="progress flex-grow-1"
                                style={{ height: "6px", maxWidth: "100px" }}
                              >
                                <div
                                  className={`progress-bar ${
                                    student.assessmentDetails.averageScore >= 70
                                      ? "bg-success"
                                      : "bg-warning"
                                  }`}
                                  role="progressbar"
                                  style={{
                                    width: `${student.assessmentDetails.averageScore}%`,
                                  }}
                                  aria-valuenow={
                                    student.assessmentDetails.averageScore
                                  }
                                  aria-valuemin="0"
                                  aria-valuemax="100"
                                ></div>
                              </div>
                            </div>
                            <small className="text-muted">
                              Best: {student.assessmentDetails.bestScore}% |
                              Latest: {student.assessmentDetails.latestScore}%
                            </small>
                          </td>
                          <td>
                            <div className="d-flex flex-column gap-1">
                              <span className="badge text-bg-primary rounded-pill attempts-count-bootstrap">
                                {student.attempts} attempts
                              </span>
                              {student.assessmentDetails.overallImprovement !==
                                0 && (
                                <span
                                  className={`badge rounded-pill ${
                                    student.assessmentDetails
                                      .overallImprovement > 0
                                      ? "text-bg-success"
                                      : "text-bg-danger"
                                  }`}
                                >
                                  {student.assessmentDetails
                                    .overallImprovement > 0
                                    ? "↗️"
                                    : "↘️"}{" "}
                                  {Math.abs(
                                    student.assessmentDetails.overallImprovement
                                  )}
                                  %
                                </span>
                              )}
                            </div>
                          </td>
                          <td>
                            <button
                              className="btn btn-link p-0 text-decoration-none view-details-button-bootstrap"
                              onClick={() => {
                                navigate(`/student-details/${student.id}`);
                              }}
                            >
                              📊 View Details
                            </button>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td
                          colSpan="5"
                          className="text-center py-4 text-secondary"
                        >
                          No students match the current filters.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </section>
        </>
      )}
    </div>
  );
}

export default Reports;
