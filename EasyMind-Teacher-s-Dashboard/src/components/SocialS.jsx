"use client"

import { useState, useEffect } from "react"
import { db, auth } from "../firebase" // Import auth
import { collection, query, where, onSnapshot, getDocs } from "firebase/firestore" // Import getDocs
import "../styles/SharedAssessmentStyles.css"
import "bootstrap/dist/js/bootstrap.bundle.min.js"
import "bootstrap/dist/css/bootstrap.min.css"

const SocialS = ({ onBack }) => {
  const [selectedAssessmentType, setSelectedAssessmentType] = useState(null)
  const [fetchedAttempts, setFetchedAttempts] = useState([])
  const [loadingAttempts, setLoadingAttempts] = useState(false)
  const [attemptsError, setAttemptsError] = useState(null)
  const [studentProgressData, setStudentProgressData] = useState({})
  const [viewMode, setViewMode] = useState("list") // "list" or "details"
  const [selectedStudent, setSelectedStudent] = useState(null)
  const [authorizedNicknames, setAuthorizedNicknames] = useState(null) // New state for authorized student nicknames

  const socialSkillsAssessments = [
    {
      id: "social_interaction",
      name: "SOCIAL INTERACTION ASSESSMENT",
      description: "Assess social skills and communication abilities.",
      imageUrl: "social-interaction-illustration.png",
      bgColor: "#E8F5E8",
      textColor: "#388E3C",
    },
    {
      id: "general",
      name: "GENERAL SOCIAL SKILLS ASSESSMENT",
      description: "Assess overall social and interpersonal abilities.",
      imageUrl: "general-social-illustration.png",
      bgColor: "#E0F7FA",
      textColor: "#006064",
    },
  ]

  // New useEffect to fetch authorized student nicknames
  useEffect(() => {
    const fetchStudents = async () => {
      const teacherId = auth.currentUser?.uid
      if (!teacherId) {
        setAttemptsError("No authenticated teacher found.")
        setAuthorizedNicknames([])
        return
      }

      try {
        const studentQuery = query(
          collection(db, "students"),
          where("createdBy", "==", teacherId)
        )
        const studentSnapshot = await getDocs(studentQuery)
        const nicknames = studentSnapshot.docs
          .map(doc => doc.data().nickname)
          .filter(Boolean) // Filter out any undefined/null nicknames

        if (nicknames.length === 0) {
          setAuthorizedNicknames([]) 
        } else {
          setAuthorizedNicknames(nicknames)
        }
      } catch (error) {
        console.error("Error fetching authorized students:", error)
        setAttemptsError("Failed to load your student list.")
        setAuthorizedNicknames([])
      }
    }

    fetchStudents()
  }, [])

  useEffect(() => {
    if (!selectedAssessmentType || authorizedNicknames === null) {
      setFetchedAttempts([])
      setAttemptsError(authorizedNicknames === null ? null : attemptsError)
      return
    }

    // Only proceed if there are authorized students or if the list has been fetched (even if empty)
    if (authorizedNicknames.length === 0) {
      setFetchedAttempts([])
      setLoadingAttempts(false)
      setAttemptsError("No students added by you, or no results yet.")
      return
    }

    setLoadingAttempts(true)
    setAttemptsError(null)

    try {
      // UPDATED QUERY: Filter by assessmentType AND by nickname (must be in the list)
      const q = query(
        collection(db, "adaptiveAssessmentResults"),
        where("assessmentType", "==", selectedAssessmentType),
        where("nickname", "in", authorizedNicknames) // Filter by authorized nicknames
      )

      const unsubscribe = onSnapshot(
        q,
        (snapshot) => {
          const attemptsData = snapshot.docs
            .map((doc) => {
              const data = doc.data()
              const performance = data.performance || 0
              const percentage = Math.round(performance * 100)

              return {
                id: doc.id,
                nickname: data.nickname || "Unknown",
                score: `${data.correctAnswers || 0}/${data.totalQuestions || 0}`,
                percentage: percentage,
                status: percentage >= 70 ? "Passed" : "Failed",
                timestamp: data.timestamp?.toDate() || new Date(0),
                moduleName: data.moduleName || "Unknown Module",
                difficultyLevel: data.difficultyLevel || "beginner",
                timeSpent: data.timeSpent || 0,
                performance: performance,
                correctAnswers: data.correctAnswers || 0,
                totalQuestions: data.totalQuestions || 0,
                attemptNumber: 1,
              }
            })
            .sort((a, b) => b.timestamp - a.timestamp)

          const groupedAttempts = {}
          attemptsData.forEach((attempt) => {
            if (!groupedAttempts[attempt.nickname]) {
              groupedAttempts[attempt.nickname] = []
            }
            groupedAttempts[attempt.nickname].push(attempt)
          })

          const processedAttempts = []
          Object.keys(groupedAttempts).forEach((nickname) => {
            const studentAttempts = groupedAttempts[nickname].sort((a, b) => a.timestamp - b.timestamp)
            studentAttempts.forEach((attempt, index) => {
              attempt.attemptNumber = index + 1
              attempt.totalAttempts = studentAttempts.length
              attempt.progress = index > 0 ? attempt.percentage - studentAttempts[index - 1].percentage : 0
              processedAttempts.push(attempt)
            })
          })

          setFetchedAttempts(processedAttempts.sort((a, b) => b.timestamp - a.timestamp))
          setStudentProgressData(groupedAttempts)
          setLoadingAttempts(false)
        },
        (error) => {
          console.error("Error fetching assessment attempts:", error)
          setAttemptsError("Failed to load results. Please try again.")
          setLoadingAttempts(false)
        },
      )

      return () => unsubscribe()
    } catch (e) {
      console.error("Error setting up Firestore listener:", e)
      setAttemptsError("Failed to set up data listener.")
      setLoadingAttempts(false)
    }
  }, [selectedAssessmentType, authorizedNicknames, attemptsError]) // Added authorizedNicknames to dependencies

  const handleViewProgress = (nickname) => {
    setSelectedStudent(nickname)
    setViewMode("details")
  }

  const handleBackToList = () => {
    setViewMode("list")
    setSelectedStudent(null)
  }

  // Render Student Progress Details Page
  if (viewMode === "details" && selectedStudent && studentProgressData[selectedStudent]) {
    const studentAttempts = studentProgressData[selectedStudent].sort((a, b) => a.timestamp - b.timestamp)
    const bestScore = Math.max(...studentAttempts.map(a => a.percentage))
    const latestScore = studentAttempts[studentAttempts.length - 1]?.percentage || 0
    const status = latestScore >= 70 ? 'Good Progress' : 'Needs Improvement'

    return (
      <div className="assessment-container">
        <div className="assessment-header">
          <button className="assessment-btn-back" onClick={handleBackToList}>
            <i className="fas fa-arrow-left"></i> Back to Results
          </button>
          <div className="assessment-main-title">
            📊 Progress Report: {selectedStudent}
          </div>
          <div className="assessment-subtitle">
            Detailed performance data for {selectedAssessmentType} assessment
          </div>
        </div>

        {/* Summary Statistics */}
        <div className="progress-summary-grid">
          <div className="progress-stat-card">
            <div className="progress-stat-icon">📝</div>
            <div className="progress-stat-content">
              <div className="progress-stat-label">Total Attempts</div>
              <div className="progress-stat-value">{studentAttempts.length}</div>
            </div>
          </div>
          <div className="progress-stat-card">
            <div className="progress-stat-icon">🏆</div>
            <div className="progress-stat-content">
              <div className="progress-stat-label">Best Score</div>
              <div className="progress-stat-value success">{bestScore}%</div>
            </div>
          </div>
          <div className="progress-stat-card">
            <div className="progress-stat-icon">📈</div>
            <div className="progress-stat-content">
              <div className="progress-stat-label">Latest Score</div>
              <div className="progress-stat-value">{latestScore}%</div>
            </div>
          </div>
          <div className="progress-stat-card">
            <div className="progress-stat-icon">✅</div>
            <div className="progress-stat-content">
              <div className="progress-stat-label">Status</div>
              <div className={`progress-stat-value ${latestScore >= 70 ? 'success' : 'warning'}`}>
                {status}
              </div>
            </div>
          </div>
        </div>

        {/* Score Progression Section */}
        <div className="progress-details-section">
          <div className="progress-section-header">
            <h3 className="progress-section-title">
              <i className="fas fa-chart-line"></i> Score Progression
            </h3>
          </div>
          
          <div className="progress-attempts-list">
            {studentAttempts.map((attempt, index) => (
              <div key={attempt.id} className="progress-attempt-card">
                <div className="progress-attempt-header">
                  <div className="progress-attempt-number">
                    <span className="attempt-badge-large">Attempt #{attempt.attemptNumber}</span>
                  </div>
                  <div className="progress-attempt-date">
                    {attempt.timestamp instanceof Date && !isNaN(attempt.timestamp)
                      ? attempt.timestamp.toLocaleDateString()
                      : 'N/A'}
                  </div>
                </div>
                
                <div className="progress-attempt-score-display">
                  <div className="progress-score-circle">
                    <svg viewBox="0 0 100 100">
                      <circle cx="50" cy="50" r="45" fill="none" stroke="#e2e8f0" strokeWidth="10"/>
                      <circle 
                        cx="50" 
                        cy="50" 
                        r="45" 
                        fill="none" 
                        stroke={attempt.percentage >= 70 ? "#10b981" : "#ef4444"}
                        strokeWidth="10"
                        strokeDasharray={`${attempt.percentage * 2.827} 282.7`}
                        transform="rotate(-90 50 50)"
                        strokeLinecap="round"
                      />
                    </svg>
                    <div className="progress-score-text">
                      <span className="progress-score-number">{attempt.percentage}%</span>
                    </div>
                  </div>
                </div>

                <div className="progress-attempt-details-grid">
                  <div className="progress-detail-item">
                    <i className="fas fa-check-circle"></i>
                    <div>
                      <div className="progress-detail-label">Score</div>
                      <div className="progress-detail-value">{attempt.score}</div>
                    </div>
                  </div>
                  <div className="progress-detail-item">
                    <i className="fas fa-percentage"></i>
                    <div>
                      <div className="progress-detail-label">Percentage</div>
                      <div className="progress-detail-value">{attempt.percentage}%</div>
                    </div>
                  </div>
                  <div className="progress-detail-item">
                    <i className="fas fa-clock"></i>
                    <div>
                      <div className="progress-detail-label">Time Spent</div>
                      <div className="progress-detail-value">{Math.round(attempt.timeSpent / 60)}m</div>
                    </div>
                  </div>
                  <div className="progress-detail-item">
                    <i className="fas fa-signal"></i>
                    <div>
                      <div className="progress-detail-label">Difficulty</div>
                      <div className="progress-detail-value text-capitalize">{attempt.difficultyLevel}</div>
                    </div>
                  </div>
                  {index > 0 && (
                    <div className="progress-detail-item full-width">
                      <i className={`fas ${attempt.progress > 0 ? 'fa-arrow-up' : 'fa-arrow-down'}`}></i>
                      <div>
                        <div className="progress-detail-label">Progress</div>
                        <div className={`progress-detail-value ${attempt.progress > 0 ? 'success' : 'danger'}`}>
                          {attempt.progress > 0 ? '+' : ''}{attempt.progress}%
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="assessment-container">
      <div className="assessment-header">
        <button className="assessment-btn-back" onClick={onBack}>
          <i className="fas fa-arrow-left"></i> Back
        </button>
        <div className="assessment-main-title">Social Skills Assessment</div>
        <div className="assessment-subtitle">Track student progress in social interaction and communication skills</div>
      </div>

      {attemptsError && <div className="alert alert-danger">{attemptsError}</div>}

      {selectedAssessmentType ? (
        <>
          {loadingAttempts ? (
            <div className="assessment-loading">
              <i className="fas fa-spinner fa-spin"></i>
              <p>Loading results...</p>
            </div>
          ) : fetchedAttempts.length > 0 ? (
            <div className="assessment-results-section">
              <div className="assessment-results-header">
                <h3 className="assessment-results-title">Assessment Results</h3>
                <p className="assessment-results-description">Detailed performance data for {selectedAssessmentType}</p>
              </div>
              <table className="assessment-table">
                <thead>
                  <tr>
                    <th>Student Nickname</th>
                    <th>Attempt</th>
                    <th>Score</th>
                    <th>Percentage</th>
                    <th>Progress</th>
                    <th>Status</th>
                    <th>Difficulty</th>
                    <th>Time Spent</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {fetchedAttempts.map((attempt) => (
                    <tr key={attempt.id}>
                      <td>{attempt.nickname}</td>
                      <td>
                        <span className="attempt-badge">
                          {attempt.attemptNumber}/{attempt.totalAttempts}
                        </span>
                      </td>
                      <td>{attempt.score}</td>
                      <td>
                        <span className={`percentage ${attempt.percentage >= 70 ? 'passed' : 'failed'}`}>
                          {attempt.percentage}%
                        </span>
                      </td>
                      <td>
                        {attempt.progress !== 0 && (
                          <span className={`progress-indicator ${attempt.progress > 0 ? 'improved' : 'declined'}`}>
                            {attempt.progress > 0 ? '↗️' : '↘️'} {Math.abs(attempt.progress)}%
                          </span>
                        )}
                      </td>
                      <td>
                        <span className={`status-badge ${attempt.status.toLowerCase()}`}>
                          {attempt.status}
                        </span>
                      </td>
                      <td>
                        <span className="difficulty-badge text-capitalize">
                          {attempt.difficultyLevel}
                        </span>
                      </td>
                      <td>
                        <span className="time-spent">
                          {Math.round(attempt.timeSpent / 60)}m
                        </span>
                      </td>
                      <td>
                        <div className="date-info">
                          {attempt.timestamp instanceof Date && !isNaN(attempt.timestamp)
                            ? attempt.timestamp.toLocaleDateString()
                            : "N/A"}
                        </div>
                      </td>
                      <td>
                        <button
                          className="btn btn-sm btn-primary"
                          onClick={() => handleViewProgress(attempt.nickname)}
                          title="View detailed progress"
                        >
                          <i className="fas fa-chart-line me-1"></i> Progress
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="assessment-empty-state">
              <i className="fas fa-chart-line"></i>
              <h3>No Results Found</h3>
              <p>No assessment results found for this category. Students need to complete assessments to see data here.</p>
            </div>
          )}
        </>
      ) : (
        <div className="assessment-cards-section">
          <div className="assessment-section-header">
            <h3 className="assessment-section-title">Assessment Categories</h3>
            <p className="assessment-section-description">Select an assessment category to view student results</p>
          </div>
          <div className="row justify-content-center">
            {socialSkillsAssessments.map((assessment) => (
              <div key={assessment.id} className="col-12 col-md-6 col-lg-3 mb-4">
                <div
                  className="assessment-card"
                  style={{ backgroundColor: assessment.bgColor }}
                  onClick={() => setSelectedAssessmentType(assessment.id)}
                >
                  <div className="assessment-card-header">
                    <div className="assessment-card-icon-wrapper">
                      <i className={`assessment-card-icon fas ${
                        assessment.id === "social_interaction" ? "fa-handshake" :
                        "fa-users"
                      }`}></i>
                    </div>
                    <div className="assessment-card-badge">
                      <span className="badge-text">Assessment</span>
                    </div>
                  </div>
                  <div className="assessment-card-body">
                    <h4 className="assessment-card-title" style={{ color: assessment.textColor }}>
                      {assessment.name}
                    </h4>
                    <p className="assessment-card-description" style={{ color: assessment.textColor }}>
                      {assessment.description}
                    </p>
                    <div className="assessment-card-features">
                      <div className="assessment-card-feature-item">
                        <i className="fas fa-chart-line"></i>
                        <span>Progress Tracking</span>
                      </div>
                      <div className="assessment-card-feature-item">
                        <i className="fas fa-users"></i>
                        <span>Student Results</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default SocialS