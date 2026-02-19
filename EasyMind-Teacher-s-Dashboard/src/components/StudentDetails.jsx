import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { db } from "../firebase";
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

function StudentDetails() {
  const { studentId } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [studentDetails, setStudentDetails] = useState(null);
  const [generatingPDF, setGeneratingPDF] = useState(false);
  const [showExportMessage, setShowExportMessage] = useState(false);

  useEffect(() => {
    if (studentId) {
      fetchStudentDetails();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [studentId]);

  const fetchStudentDetails = async () => {
    try {
      setLoading(true);

      // Fetch student data
      const studentsQuery = query(collection(db, "students"));
      const studentsSnapshot = await getDocs(studentsQuery);

      let studentData = null;
      studentsSnapshot.forEach((doc) => {
        if (doc.id === studentId) {
          studentData = { id: doc.id, ...doc.data() };
        }
      });

      if (!studentData) {
        console.error("Student not found");
        navigate("/reports");
        return;
      }

      // Fetch student progress data (same as Reports component)
      const userStatsQuery = query(collection(db, "userStats"));
      const userStatsSnapshot = await getDocs(userStatsQuery);

      let userStatsData = null;
      userStatsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.nickname === studentData.nickname) {
          userStatsData = data;
        }
      });

      // Fetch assessment results (same as Reports component)
      const assessmentQuery = query(
        collection(db, "adaptiveAssessmentResults")
      );
      const assessmentSnapshot = await getDocs(assessmentQuery);

      const allAssessments = [];
      assessmentSnapshot.forEach((doc) => {
        const assessmentData = doc.data();
        if (assessmentData.nickname === studentData.nickname) {
          allAssessments.push({
            id: doc.id,
            ...assessmentData,
            timestamp: assessmentData.timestamp,
          });
        }
      });

      // Fetch lesson retention data - count actual completed lessons
      const lessonQuery = query(
        collection(db, "lessonRetention"),
        where("nickname", "==", studentData.nickname)
      );
      const lessonSnapshot = await getDocs(lessonQuery);
      const lessonsCompleted = lessonSnapshot.docs.length;

      // Fetch game visits - count actual game plays
      const gameVisitQuery = query(
        collection(db, "visitTracking"),
        where("nickname", "==", studentData.nickname),
        where("itemType", "==", "game")
      );
      const gameVisitSnapshot = await getDocs(gameVisitQuery);
      const gamesPlayed = gameVisitSnapshot.docs.length;

      // Calculate assessment details
      const assessmentDetails = calculateAssessmentDetails(allAssessments);

      // Create student details object with consistent data structure
      const details = {
        ...studentData,
        ...userStatsData, // Include user stats data
        assessmentDetails,
        // Generate name consistently with Reports component
        name:
          `${studentData.firstName || ""} ${
            studentData.surname || ""
          }`.trim() || studentData.nickname,
        avatar: studentData.nickname?.substring(0, 2).toUpperCase() || "ST",
        // Use correct field names and values
        level: userStatsData?.currentLevel || 1,
        // --- FIX IMPLEMENTED HERE ---
        totalXP: userStatsData?.totalXP || 0,
        streakDays: userStatsData?.streakDays || 0,
        // ---------------------------
        lessonsCompleted: lessonsCompleted,
        gamesPlayed: gamesPlayed,
        isImproved: assessmentDetails.averageScore >= 70,
      };

      // Debug logging
      console.log("Student Details Data:", {
        studentData,
        userStatsData,
        lessonsCompleted,
        gamesPlayed,
        allAssessments,
        assessmentDetails,
        finalDetails: details,
      });

      setStudentDetails(details);
    } catch (error) {
      console.error("Error fetching student details:", error);
    } finally {
      setLoading(false);
    }
  };

  const calculateAssessmentDetails = (assessments) => {
    if (assessments.length === 0) {
      return {
        averageScore: 0,
        bestScore: 0,
        totalAttempts: 0,
        overallImprovement: 0,
        allAssessments: [],
      };
    }

    // Sort assessments by timestamp to ensure proper order
    const sortedAssessments = assessments.sort((a, b) => {
      const timeA = a.timestamp?.toDate?.() || new Date(0);
      const timeB = b.timestamp?.toDate?.() || new Date(0);
      return timeA - timeB;
    });

    const scores = sortedAssessments.map((a) => {
      // Use performance field if available, otherwise calculate from questions
      if (a.performance !== undefined) {
        return a.performance * 100;
      }
      // Fallback calculation
      const totalQuestions =
        a.totalQuestions || a.attemptedQuestions?.length || 1;
      const correctAnswers =
        a.correctAnswers || a.correctQuestions?.length || 0;
      return (correctAnswers / totalQuestions) * 100;
    });

    const averageScore =
      scores.reduce((sum, score) => sum + score, 0) / scores.length;
    const bestScore = Math.max(...scores);

    // Calculate improvement (comparing first half vs second half)
    const midPoint = Math.floor(sortedAssessments.length / 2);
    const firstHalfAvg =
      midPoint > 0
        ? scores.slice(0, midPoint).reduce((sum, score) => sum + score, 0) /
          midPoint
        : 0;
    const secondHalfAvg =
      midPoint < sortedAssessments.length
        ? scores.slice(midPoint).reduce((sum, score) => sum + score, 0) /
          (sortedAssessments.length - midPoint)
        : 0;

    const overallImprovement = secondHalfAvg - firstHalfAvg;

    // Add performance calculation to each assessment
    const assessmentsWithPerformance = sortedAssessments.map((assessment) => {
      // Use existing performance if available, otherwise calculate
      let performance = assessment.performance;
      if (performance === undefined) {
        const totalQuestions =
          assessment.totalQuestions ||
          assessment.attemptedQuestions?.length ||
          1;
        const correctAnswers =
          assessment.correctAnswers || assessment.correctQuestions?.length || 0;
        performance = correctAnswers / totalQuestions;
      }

      return {
        ...assessment,
        performance,
        assessmentType:
          assessment.assessmentType || assessment.contentType || "Unknown",
        difficultyLevel: assessment.difficultyLevel || "beginner",
        // Ensure we have the fields needed for display
        totalQuestions:
          assessment.totalQuestions ||
          assessment.attemptedQuestions?.length ||
          1,
        correctAnswers:
          assessment.correctAnswers || assessment.correctQuestions?.length || 0,
      };
    });

    return {
      averageScore: Math.round(averageScore),
      bestScore: Math.round(bestScore),
      totalAttempts: sortedAssessments.length,
      overallImprovement: Math.round(overallImprovement),
      allAssessments: assessmentsWithPerformance,
    };
  };

  const generatePDF = async () => {
    if (!studentDetails) return;

    try {
      setGeneratingPDF(true);

      const pdf = new jsPDF("p", "mm", "a4");
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = pdf.internal.pageSize.getHeight();
      const margin = 20;
      const contentWidth = pageWidth - margin * 2;
      let yPosition = margin;

      // Helper function to check space
      const checkSpace = (requiredSpace) => {
        if (yPosition + requiredSpace > pageHeight - 20) {
          pdf.addPage();
          yPosition = margin;
          return true;
        }
        return false;
      };

      // ========== HEADER ==========
      pdf.setFillColor(79, 70, 229);
      pdf.rect(0, 0, pageWidth, 40, "F");

      pdf.setTextColor(255, 255, 255);
      pdf.setFontSize(24);
      pdf.setFont("helvetica", "bold");
      pdf.text("EasyMind", pageWidth / 2, 15, { align: "center" });

      pdf.setFontSize(14);
      pdf.setFont("helvetica", "normal");
      pdf.text("Student Progress Report", pageWidth / 2, 25, {
        align: "center",
      });

      pdf.setFontSize(10);
      pdf.text(
        `Generated: ${new Date().toLocaleDateString("en-US")}`,
        pageWidth / 2,
        32,
        { align: "center" }
      );

      pdf.setTextColor(0, 0, 0);
      yPosition = 50;

      // ========== STUDENT INFO ==========
      pdf.setFillColor(248, 249, 250);
      pdf.roundedRect(margin, yPosition, contentWidth, 45, 3, 3, "F");

      yPosition += 10;
      pdf.setFontSize(16);
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(79, 70, 229);
      pdf.text(`Student: ${studentDetails.name}`, margin + 5, yPosition);

      yPosition += 10;
      pdf.setFontSize(10);
      pdf.setFont("helvetica", "normal");
      pdf.setTextColor(60, 60, 60);
      pdf.text(`Level: ${studentDetails.level || 1}`, margin + 5, yPosition);
      pdf.text(`XP: ${studentDetails.totalXP || 0}`, margin + 50, yPosition);
      pdf.text(
        `Streak: ${studentDetails.streakDays || 0} days`,
        margin + 90,
        yPosition
      );

      // Status badge
      yPosition += 10;
      if (studentDetails.isImproved) {
        pdf.setFillColor(220, 252, 231);
        pdf.roundedRect(margin + 5, yPosition - 5, 30, 8, 1, 1, "F");
        pdf.setTextColor(22, 101, 52);
        pdf.setFont("helvetica", "bold");
        pdf.text("Improved", margin + 20, yPosition, { align: "center" });
      } else {
        pdf.setFillColor(254, 226, 226);
        pdf.roundedRect(margin + 5, yPosition - 5, 30, 8, 1, 1, "F");
        pdf.setTextColor(153, 27, 27);
        pdf.setFont("helvetica", "bold");
        pdf.text("At Risk", margin + 20, yPosition, { align: "center" });
      }

      pdf.setTextColor(0, 0, 0);
      yPosition += 15;

      // ========== PERFORMANCE SUMMARY ==========
      checkSpace(60);

      pdf.setFontSize(16);
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(79, 70, 229);
      pdf.text("Performance Summary", margin, yPosition);
      yPosition += 10;

      // Performance boxes
      const boxWidth = (contentWidth - 15) / 4;
      const stats = [
        {
          label: "Average",
          value: `${studentDetails.assessmentDetails.averageScore}%`,
          color: [34, 197, 94],
        },
        {
          label: "Best",
          value: `${studentDetails.assessmentDetails.bestScore}%`,
          color: [59, 130, 246],
        },
        {
          label: "Attempts",
          value: studentDetails.assessmentDetails.totalAttempts,
          color: [249, 115, 22],
        },
        {
          label: "Improvement",
          value: `${
            studentDetails.assessmentDetails.overallImprovement > 0 ? "+" : ""
          }${studentDetails.assessmentDetails.overallImprovement}%`,
          color:
            studentDetails.assessmentDetails.overallImprovement >= 0
              ? [34, 197, 94]
              : [239, 68, 68],
        },
      ];

      stats.forEach((stat, index) => {
        const x = margin + index * (boxWidth + 5);

        pdf.setFillColor(255, 255, 255);
        pdf.roundedRect(x, yPosition, boxWidth, 35, 2, 2, "F");

        pdf.setFillColor(...stat.color);
        pdf.rect(x, yPosition, 3, 35, "F");

        pdf.setFontSize(18);
        pdf.setFont("helvetica", "bold");
        pdf.setTextColor(...stat.color);
        pdf.text(String(stat.value), x + boxWidth / 2, yPosition + 15, {
          align: "center",
        });

        pdf.setFontSize(8);
        pdf.setFont("helvetica", "normal");
        pdf.setTextColor(100, 100, 100);
        pdf.text(stat.label, x + boxWidth / 2, yPosition + 25, {
          align: "center",
        });
      });

      pdf.setTextColor(0, 0, 0);
      yPosition += 45;

      // ========== ASSESSMENT PERFORMANCE ANALYSIS ==========
      checkSpace(50);

      // Add new page before assessment section for better layout
      pdf.addPage();
      yPosition = margin;

      pdf.setFontSize(16);
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(79, 70, 229);
      pdf.text("Detailed Assessment Performance", margin, yPosition);
      yPosition += 10;

      // Group assessments by type for THIS STUDENT ONLY
      // Get all unique assessment types from the student's actual assessments
      const uniqueTypes = [
        ...new Set(
          studentDetails.assessmentDetails.allAssessments.map(
            (a) => a.assessmentType
          )
        ),
      ];
      const assessmentStats = [];

      uniqueTypes.forEach((type) => {
        // Filter assessments for this type from THIS STUDENT
        const typeAssessments =
          studentDetails.assessmentDetails.allAssessments.filter(
            (a) => a.assessmentType === type
          );

        if (typeAssessments.length === 0) return;

        // Sort by timestamp
        const sortedByTime = typeAssessments.sort(
          (a, b) =>
            (a.timestamp?.toDate() || new Date(0)) -
            (b.timestamp?.toDate() || new Date(0))
        );

        // Calculate statistics
        const scores = sortedByTime.map((a) =>
          Math.round((a.performance || 0) * 100)
        );
        const avgScore = Math.round(
          scores.reduce((sum, s) => sum + s, 0) / scores.length
        );
        const minScore = Math.min(...scores);
        const maxScore = Math.max(...scores);
        const totalAttempts = typeAssessments.length;

        // Calculate trend: first attempt vs latest attempt
        let trend = 0;
        if (sortedByTime.length > 1) {
          const firstScore = Math.round(
            (sortedByTime[0].performance || 0) * 100
          );
          const latestScore = Math.round(
            (sortedByTime[sortedByTime.length - 1].performance || 0) * 100
          );
          trend = latestScore - firstScore;
        }

        assessmentStats.push({
          name: type.charAt(0).toUpperCase() + type.slice(1).replace("_", " "),
          avgScore,
          minScore,
          maxScore,
          totalAttempts,
          trend,
          attempts: sortedByTime, // Store all attempts for detailed breakdown
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
          checkSpace(40);

          // Assessment Type Header Box
          pdf.setFillColor(79, 70, 229);
          pdf.roundedRect(margin, yPosition, contentWidth, 10, 2, 2, "F");

          pdf.setFontSize(12);
          pdf.setFont("helvetica", "bold");
          pdf.setTextColor(255, 255, 255);
          pdf.text(stat.name, margin + 5, yPosition + 7);

          // Trend indicator on the right
          const indicatorX = margin + contentWidth - 35;
          if (stat.trend > 5) {
            pdf.setFillColor(34, 197, 94);
            pdf.roundedRect(indicatorX, yPosition + 2, 30, 6, 1, 1, "F");
            pdf.setTextColor(255, 255, 255);
            pdf.setFont("helvetica", "bold");
            pdf.setFontSize(8);
            pdf.text(`+${stat.trend}%`, indicatorX + 15, yPosition + 6, {
              align: "center",
            });
          } else if (stat.trend < -5) {
            pdf.setFillColor(239, 68, 68);
            pdf.roundedRect(indicatorX, yPosition + 2, 30, 6, 1, 1, "F");
            pdf.setTextColor(255, 255, 255);
            pdf.setFont("helvetica", "bold");
            pdf.setFontSize(8);
            pdf.text(`${stat.trend}%`, indicatorX + 15, yPosition + 6, {
              align: "center",
            });
          } else {
            pdf.setFillColor(156, 163, 175);
            pdf.roundedRect(indicatorX, yPosition + 2, 30, 6, 1, 1, "F");
            pdf.setTextColor(255, 255, 255);
            pdf.setFont("helvetica", "normal");
            pdf.setFontSize(8);
            pdf.text(`Stable`, indicatorX + 15, yPosition + 6, {
              align: "center",
            });
          }

          yPosition += 12;

          // Summary Stats Box
          pdf.setFillColor(248, 249, 250);
          pdf.roundedRect(margin, yPosition, contentWidth, 12, 2, 2, "F");

          pdf.setFontSize(9);
          pdf.setFont("helvetica", "normal");
          pdf.setTextColor(60, 60, 60);

          const statsX = margin + 5;
          pdf.text(`Average: `, statsX, yPosition + 8);
          pdf.setFont("helvetica", "bold");
          pdf.text(`${stat.avgScore}%`, statsX + 22, yPosition + 8);

          pdf.setFont("helvetica", "normal");
          pdf.text(`Range: `, statsX + 45, yPosition + 8);
          pdf.setFont("helvetica", "bold");
          pdf.text(
            `${stat.minScore}%-${stat.maxScore}%`,
            statsX + 60,
            yPosition + 8
          );

          pdf.setFont("helvetica", "normal");
          pdf.text(`Total Attempts: `, statsX + 95, yPosition + 8);
          pdf.setFont("helvetica", "bold");
          pdf.text(`${stat.totalAttempts}`, statsX + 125, yPosition + 8);

          yPosition += 15;

          // Attempt History Header
          pdf.setFontSize(10);
          pdf.setFont("helvetica", "bold");
          pdf.setTextColor(79, 70, 229);
          pdf.text("Attempt History:", margin + 5, yPosition);
          yPosition += 7;

          // Check if we need a new page for the table
          const estimatedTableHeight = stat.attempts.length * 7 + 20;
          if (checkSpace(estimatedTableHeight)) {
            // If new page was added, reprint the assessment header
            pdf.setFillColor(79, 70, 229);
            pdf.roundedRect(margin, yPosition, contentWidth, 10, 2, 2, "F");
            pdf.setFontSize(12);
            pdf.setFont("helvetica", "bold");
            pdf.setTextColor(255, 255, 255);
            pdf.text(`${stat.name} (continued)`, margin + 5, yPosition + 7);
            yPosition += 15;
          }

          // Table header
          pdf.setFillColor(240, 240, 255);
          pdf.rect(margin + 5, yPosition, contentWidth - 10, 8, "F");

          pdf.setFontSize(8);
          pdf.setFont("helvetica", "bold");
          pdf.setTextColor(60, 60, 60);

          let colX = margin + 8;
          pdf.text("#", colX, yPosition + 5);
          colX += 12;
          pdf.text("Date", colX, yPosition + 5);
          colX += 35;
          pdf.text("Score", colX, yPosition + 5);
          colX += 30;
          pdf.text("Correct/Total", colX, yPosition + 5);
          colX += 35;
          pdf.text("Performance", colX, yPosition + 5);
          colX += 30;
          pdf.text("vs Previous", colX, yPosition + 5);

          yPosition += 10;

          // Attempt rows
          stat.attempts.forEach((attempt, index) => {
            checkSpace(10);

            // Alternating row background
            if (index % 2 === 0) {
              pdf.setFillColor(252, 252, 254);
              pdf.rect(margin + 5, yPosition - 2, contentWidth - 10, 7, "F");
            }

            pdf.setFontSize(8);
            pdf.setFont("helvetica", "normal");
            pdf.setTextColor(60, 60, 60);

            colX = margin + 8;

            // Attempt number
            pdf.text(`${index + 1}`, colX, yPosition + 3);
            colX += 12;

            // Date
            const attemptDate = attempt.timestamp?.toDate?.();
            const dateStr = attemptDate
              ? attemptDate.toLocaleDateString("en-US", {
                  month: "short",
                  day: "numeric",
                  year: "2-digit",
                })
              : "N/A";
            pdf.text(dateStr, colX, yPosition + 3);
            colX += 35;

            // Score
            const attemptScore = Math.round((attempt.performance || 0) * 100);
            if (attemptScore >= 80) {
              pdf.setTextColor(34, 197, 94);
            } else if (attemptScore >= 60) {
              pdf.setTextColor(234, 179, 8);
            } else {
              pdf.setTextColor(239, 68, 68);
            }
            pdf.setFont("helvetica", "bold");
            pdf.text(`${attemptScore}%`, colX, yPosition + 3);
            colX += 30;

            // Correct/Total
            pdf.setFont("helvetica", "normal");
            pdf.setTextColor(60, 60, 60);
            pdf.text(
              `${attempt.correctAnswers || 0}/${attempt.totalQuestions || 0}`,
              colX,
              yPosition + 3
            );
            colX += 35;

            // Performance indicator
            if (attemptScore >= 70) {
              pdf.setFillColor(220, 252, 231);
              pdf.roundedRect(colX, yPosition - 1, 20, 5, 1, 1, "F");
              pdf.setTextColor(22, 101, 52);
              pdf.setFontSize(7);
              pdf.text("Good", colX + 10, yPosition + 3, { align: "center" });
            } else {
              pdf.setFillColor(254, 226, 226);
              pdf.roundedRect(colX, yPosition - 1, 20, 5, 1, 1, "F");
              pdf.setTextColor(153, 27, 27);
              pdf.setFontSize(7);
              pdf.text("Review", colX + 10, yPosition + 3, { align: "center" });
            }
            colX += 30;

            // vs Previous
            if (index > 0) {
              const prevScore = Math.round(
                (stat.attempts[index - 1].performance || 0) * 100
              );
              const diff = attemptScore - prevScore;

              pdf.setFontSize(8);
              if (diff > 0) {
                pdf.setTextColor(34, 197, 94);
                pdf.text(`+${diff}%`, colX, yPosition + 3);
              } else if (diff < 0) {
                pdf.setTextColor(239, 68, 68);
                pdf.text(`${diff}%`, colX, yPosition + 3);
              } else {
                pdf.setTextColor(107, 114, 128);
                pdf.text(`0%`, colX, yPosition + 3);
              }
            } else {
              pdf.setTextColor(107, 114, 128);
              pdf.setFontSize(8);
              pdf.text("-", colX, yPosition + 3);
            }

            pdf.setTextColor(0, 0, 0);
            yPosition += 7;
          });

          yPosition += 12;
        });

        // Add explanation
        yPosition += 5;
        checkSpace(25);

        pdf.setFillColor(255, 251, 235);
        pdf.roundedRect(margin, yPosition, contentWidth, 20, 2, 2, "F");

        pdf.setFontSize(9);
        pdf.setFont("helvetica", "bold");
        pdf.setTextColor(146, 64, 14);
        pdf.text("Reading the Report:", margin + 5, yPosition + 7);

        pdf.setFont("helvetica", "normal");
        pdf.setTextColor(80, 80, 80);
        pdf.setFontSize(8);
        const explanation =
          'Each assessment type shows all attempts chronologically. "Good" indicates 70%+ performance. ' +
          'The trend compares first vs latest attempt. "vs Previous" shows improvement between consecutive attempts.';
        const splitExplanation = pdf.splitTextToSize(
          explanation,
          contentWidth - 10
        );
        pdf.text(splitExplanation, margin + 5, yPosition + 13);

        yPosition += 25;
      }

      // ========== FOOTER ==========
      const totalPages = pdf.internal.getNumberOfPages();
      for (let i = 1; i <= totalPages; i++) {
        pdf.setPage(i);

        pdf.setDrawColor(200, 200, 200);
        pdf.setLineWidth(0.5);
        pdf.line(margin, pageHeight - 15, pageWidth - margin, pageHeight - 15);

        pdf.setFontSize(8);
        pdf.setTextColor(120, 120, 120);
        pdf.text(
          `EasyMind | Page ${i} of ${totalPages}`,
          pageWidth / 2,
          pageHeight - 10,
          { align: "center" }
        );
      }

      // Save PDF
      const fileName = `Student_Report_${studentDetails.name}_${
        new Date().toISOString().split("T")[0]
      }.pdf`;
      pdf.save(fileName);

      setShowExportMessage(true);
      setTimeout(() => setShowExportMessage(false), 3000);
    } catch (error) {
      console.error("Error generating PDF:", error);
      alert("Error generating PDF. Please try again.");
    } finally {
      setGeneratingPDF(false);
    }
  };

  if (loading) {
    return (
      <div className="container-fluid bg-light-gray py-4">
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="mt-3">Loading student details...</p>
        </div>
      </div>
    );
  }

  if (!studentDetails) {
    return (
      <div className="container-fluid bg-light-gray py-4">
        <div className="text-center py-5">
          <h3>Student not found</h3>
          <button
            className="btn btn-primary mt-3"
            onClick={() => navigate("/reports")}
          >
            Back to Reports
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container-fluid bg-light-gray py-4">
      <style jsx>{`
        /* Student Details Page Styles */

        .performance-overview {
          background: white;
          border-radius: 16px;
          padding: 2rem;
          margin-bottom: 2rem;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        }

        .performance-card {
          background: white;
          border-radius: 12px;
          border: 1px solid #e9ecef;
          transition: all 0.3s ease;
          min-height: 120px;
          display: flex;
          flex-direction: column;
          justify-content: center;
          text-align: center;
          padding: 1.5rem;
        }

        .performance-card:hover {
          transform: translateY(-4px);
          box-shadow: 0 12px 40px rgba(0, 0, 0, 0.1);
          border-color: #dee2e6;
        }

        .performance-icon {
          font-size: 2rem;
          opacity: 0.8;
          margin-bottom: 1rem;
        }

        .performance-value {
          font-size: 2rem;
          font-weight: 700;
          line-height: 1;
          margin-bottom: 0.5rem;
        }

        .performance-label {
          font-size: 0.9rem;
          font-weight: 500;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          opacity: 0.7;
        }

        .student-info-card {
          background: white;
          border-radius: 16px;
          border: 1px solid #e9ecef;
          overflow: hidden;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        }

        .card-header {
          background: #f8f9fa;
          border-bottom: 1px solid #e9ecef;
          padding: 1rem 1.5rem;
        }

        .card-title {
          font-size: 1.1rem;
          font-weight: 600;
          color: #495057;
          margin: 0;
        }

        .card-body {
          padding: 1.5rem;
        }

        .status-badge {
          display: inline-block;
          padding: 0.5rem 1rem;
          border-radius: 20px;
          font-size: 0.8rem;
          font-weight: 600;
        }

        .status-badge.improved {
          background: linear-gradient(135deg, #d4edda, #c3e6cb);
          color: #155724;
        }

        .status-badge.needs-improvement {
          background: linear-gradient(135deg, #f8d7da, #f5c6cb);
          color: #721c24;
        }

        .student-details {
          background: #f8f9fa;
          border-radius: 12px;
          padding: 1rem;
        }

        .detail-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 0.75rem 0;
          border-bottom: 1px solid #e9ecef;
        }

        .detail-item:last-child {
          border-bottom: none;
        }

        .detail-label {
          font-size: 0.9rem;
          color: #6c757d;
          font-weight: 500;
        }

        .detail-value {
          font-size: 0.9rem;
          font-weight: 600;
          color: #495057;
        }

        .improvement-indicator {
          display: inline-block;
          padding: 0.5rem 1rem;
          border-radius: 20px;
          font-size: 0.8rem;
          font-weight: 600;
        }

        .improvement-indicator.positive {
          background: linear-gradient(135deg, #d4edda, #c3e6cb);
          color: #155724;
        }

        .improvement-indicator.negative {
          background: linear-gradient(135deg, #f8d7da, #f5c6cb);
          color: #721c24;
        }

        .assessment-history-card {
          background: white;
          border-radius: 16px;
          border: 1px solid #e9ecef;
          overflow: hidden;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        }

        .attempts-badge {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 0.375rem 0.75rem;
          border-radius: 12px;
          font-size: 0.8rem;
          font-weight: 600;
        }

        .assessment-list {
          max-height: 500px;
          overflow-y: auto;
        }

        .assessment-item {
          display: flex;
          align-items: center;
          padding: 1rem 1.5rem;
          border-bottom: 1px solid #f1f3f4;
          transition: background-color 0.2s ease;
        }

        .assessment-item:hover {
          background-color: #f8f9fa;
        }

        .assessment-item:last-child {
          border-bottom: none;
        }

        .assessment-number {
          width: 40px;
          height: 40px;
          border-radius: 10px;
          background: #e9ecef;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 0.9rem;
          font-weight: 600;
          color: #6c757d;
          margin-right: 1rem;
        }

        .assessment-content {
          flex: 1;
          margin-right: 1rem;
        }

        .assessment-type {
          font-size: 1rem;
          font-weight: 600;
          color: #495057;
          margin-bottom: 0.25rem;
        }

        .assessment-score {
          font-size: 0.9rem;
          color: #6c757d;
        }

        .assessment-performance {
          display: flex;
          align-items: center;
          gap: 1rem;
        }

        .performance-bar {
          width: 80px;
          height: 8px;
          background: #e9ecef;
          border-radius: 4px;
          overflow: hidden;
        }

        .performance-fill {
          height: 100%;
          border-radius: 4px;
          transition: width 0.3s ease;
        }

        .performance-fill.success {
          background: linear-gradient(90deg, #28a745, #20c997);
        }

        .performance-fill.danger {
          background: linear-gradient(90deg, #dc3545, #fd7e14);
        }

        .performance-badge {
          font-size: 0.9rem;
          font-weight: 600;
          padding: 0.25rem 0.5rem;
          border-radius: 8px;
        }

        .performance-badge.success {
          background: #d4edda;
          color: #155724;
        }

        .performance-badge.danger {
          background: #f8d7da;
          color: #721c24;
        }

        .assessment-status {
          width: 16px;
          height: 16px;
          border-radius: 50%;
        }

        .status-dot.success {
          background: #28a745;
        }

        .status-dot.danger {
          background: #dc3545;
        }

        .empty-state {
          padding: 3rem 2rem;
          text-align: center;
        }

        /* Responsive Design */
        @media (max-width: 768px) {
          .performance-overview {
            padding: 1rem;
            margin-bottom: 1rem;
          }

          .performance-card {
            min-height: 100px;
            padding: 1rem;
          }

          .performance-value {
            font-size: 1.5rem;
          }

          .assessment-item {
            padding: 0.75rem 1rem;
          }

          .assessment-performance {
            flex-direction: column;
            gap: 0.5rem;
            align-items: flex-end;
          }

          .performance-bar {
            width: 60px;
          }
        }
      `}</style>

      {/* Header with Back Button and Export */}
      <div className="d-flex justify-content-between align-items-center mb-4">
        <button
          className="btn btn-outline-primary"
          onClick={() => navigate("/reports")}
        >
          <i className="bi bi-arrow-left me-2"></i>Back to Reports
        </button>
        <button
          className="btn btn-success"
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
              <i className="bi bi-file-pdf me-2"></i>Export to PDF
            </>
          )}
        </button>
      </div>

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

      {/* Performance Overview */}
      <div className="performance-overview">
        <h3 className="mb-4 text-center">Performance Overview</h3>
        <div className="row g-4">
          <div className="col-md-3">
            <div className="performance-card">
              <div className="performance-icon text-success">
                <i className="bi bi-graph-up"></i>
              </div>
              <div className="performance-value text-success">
                {studentDetails.assessmentDetails.averageScore}%
              </div>
              <div className="performance-label text-muted">Average Score</div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="performance-card">
              <div className="performance-icon text-primary">
                <i className="bi bi-trophy"></i>
              </div>
              <div className="performance-value text-primary">
                {studentDetails.assessmentDetails.bestScore}%
              </div>
              <div className="performance-label text-muted">Best Score</div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="performance-card">
              <div className="performance-icon text-warning">
                <i className="bi bi-clock-history"></i>
              </div>
              <div className="performance-value text-warning">
                {studentDetails.assessmentDetails.totalAttempts}
              </div>
              <div className="performance-label text-muted">Total Attempts</div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="performance-card">
              <div className="performance-icon text-info">
                <i className="bi bi-star"></i>
              </div>
              <div className="performance-value text-info">
                {studentDetails.totalXP || 0}
              </div>
              <div className="performance-label text-muted">Total XP</div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="row g-4">
        {/* Student Information */}
        <div className="col-lg-4">
          <div className="student-info-card">
            <div className="card-header">
              <h5 className="card-title">
                <i className="bi bi-person-circle me-2 text-primary"></i>Student
                Information
              </h5>
            </div>
            <div className="card-body">
              <div className="text-center mb-4">
                <span
                  className={`status-badge ${
                    studentDetails.isImproved ? "improved" : "needs-improvement"
                  }`}
                >
                  {studentDetails.isImproved
                    ? "✓ Improved Student"
                    : "⚠ Needs Improvement"}
                </span>
              </div>

              <div className="student-details">
                <div className="detail-item">
                  <span className="detail-label">Current Level</span>
                  <span className="detail-value">
                    {studentDetails.level || 1}
                  </span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Streak Days</span>
                  <span className="detail-value">
                    {studentDetails.streakDays || 0}
                  </span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Lessons Completed</span>
                  <span className="detail-value">
                    {studentDetails.lessonsCompleted || 0}
                  </span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Games Played</span>
                  <span className="detail-value">
                    {studentDetails.gamesPlayed || 0}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Assessment History */}
        <div className="col-lg-8">
          <div className="assessment-history-card">
            <div className="card-header d-flex justify-content-between align-items-center">
              <h5 className="card-title">
                <i className="bi bi-clipboard-data me-2 text-primary"></i>
                Assessment History
              </h5>
              <span className="attempts-badge">
                {studentDetails.assessmentDetails.totalAttempts} attempts
              </span>
            </div>
            <div className="card-body p-0">
              {studentDetails.assessmentDetails.allAssessments?.length > 0 ? (
                <div className="assessment-list">
                  {studentDetails.assessmentDetails.allAssessments.map(
                    (assessment, index) => (
                      <div key={index} className="assessment-item">
                        <div className="assessment-number">{index + 1}</div>
                        <div className="assessment-content">
                          <div className="assessment-type">
                            {assessment.assessmentType || "Unknown"}
                          </div>
                          <div className="assessment-score">
                            Score: {assessment.correctAnswers || 0}/
                            {assessment.totalQuestions || 0}
                          </div>
                        </div>
                        <div className="assessment-performance">
                          <div className="performance-bar">
                            <div
                              className={`performance-fill ${
                                assessment.performance >= 0.7
                                  ? "success"
                                  : "danger"
                              }`}
                              style={{
                                width: `${assessment.performance * 100}%`,
                              }}
                            ></div>
                          </div>
                          <span
                            className={`performance-badge ${
                              assessment.performance >= 0.7
                                ? "success"
                                : "danger"
                            }`}
                          >
                            {Math.round(assessment.performance * 100)}%
                          </span>
                        </div>
                        <div className="assessment-status">
                          <span
                            className={`status-dot ${
                              assessment.performance >= 0.7
                                ? "success"
                                : "danger"
                            }`}
                          ></span>
                        </div>
                      </div>
                    )
                  )}
                </div>
              ) : (
                <div className="empty-state">
                  <i className="bi bi-clipboard-data fs-1 text-muted mb-3"></i>
                  <h6 className="text-muted">No Assessment Data</h6>
                  <p className="text-muted small mb-0">
                    This student hasn't completed any assessments yet.
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default StudentDetails;
