import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import Chart from 'chart.js/auto';
import '../styles/Dashboard.css';
import { collection, query, where, getDocs, orderBy, limit } from 'firebase/firestore';
import { db } from '../firebase'; // Adjust path to your Firebase config
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import "bootstrap/dist/css/bootstrap.min.css";

// StatCard Component
const StatCard = ({ value, label, className, to }) => {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <Link
      to={to}
      style={{ textDecoration: 'none' }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <div
        className={`db-stat-card ${className}`}
        style={{
          backgroundColor: isHovered ? '#E0E0E0' : undefined,
          cursor: 'pointer',
          transition: 'background-color 0.2s',
        }}
      >
        <div>
          <h3>{value}</h3>
          <p>{label}</p>
        </div>
      </div>
    </Link>
  );
};

// ChartCard Component
const ChartCard = ({ title, chartId, chartType, chartData, chartOptions, className, to }) => {
  const [isHovered, setIsHovered] = useState(false);

  useEffect(() => {
    const canvas = document.getElementById(chartId);
    if (!canvas) {
      console.error(`Canvas element with ID ${chartId} not found.`);
      return;
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      console.error(`Failed to get 2D context for canvas with ID ${chartId}.`);
      return;
    }
    const chart = new Chart(ctx, {
      type: chartType,
      data: chartData,
      options: chartOptions
    });

    return () => chart.destroy();
  }, [chartData, chartOptions, chartType, chartId]);

  return (
    <Link
      to={to}
      style={{ textDecoration: 'none' }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <div
        className={`db-chart-card ${className || ''}`}
        style={{
          backgroundColor: isHovered ? '#E0E0E0' : '#FFFFFF',
          cursor: 'pointer',
          transition: 'background-color 0.2s',
        }}
      >
        <h3 style={{ color: '#000000' }}>{title}</h3>
        <canvas id={chartId}></canvas>
      </div>
    </Link>
  );
};

// TopStudentsCard Component
const TopStudentsCard = ({ students }) => {
  const [isHovered, setIsHovered] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('All');

  const handleCategoryChange = (e) => {
    e.stopPropagation();
    setSelectedCategory(e.target.value);
  };

  // Helper function to calculate level from XP (matches student-side logic)
  const calculateLevelFromXP = (xp) => {
    const levelRequirements = {
      1: 0,    // Level 1: Starting level
      2: 100,  // Level 2: 100 XP
      3: 250,  // Level 3: 250 XP
      4: 450,  // Level 4: 450 XP
      5: 700,  // Level 5: 700 XP
      6: 1000, // Level 6: 1000 XP
      7: 1350, // Level 7: 1350 XP
      8: 1750, // Level 8: 1750 XP
      9: 2200, // Level 9: 2200 XP
      10: 2700, // Level 10: 2700 XP
    };
    
    for (let level = 10; level >= 1; level--) {
      if (xp >= levelRequirements[level]) {
        return level;
      }
    }
    return 1;
  };

  // Filter students based on selected category
  const getFilteredStudents = () => {
    if (selectedCategory === 'All') {
      return students;
    }
    
    console.log('Filtering students by category:', selectedCategory);
    console.log('All students:', students);
    
    // Filter based on actual engagement and performance characteristics
    let filtered;
    switch (selectedCategory) {
      case 'High Performers':
        // Students with Level 4+ (450+ XP) - Highly engaged
        filtered = students.filter(student => {
          const xp = parseInt(student.score?.replace(' XP', '') || '0');
          const calculatedLevel = calculateLevelFromXP(xp);
          console.log(`Student ${student.name}: XP=${xp}, Calculated Level=${calculatedLevel}`);
          return calculatedLevel >= 4;
        });
        break;
      case 'Active Learners':
        // Students with Level 2-3 (100-450 XP) - Moderately engaged
        filtered = students.filter(student => {
          const xp = parseInt(student.score?.replace(' XP', '') || '0');
          const calculatedLevel = calculateLevelFromXP(xp);
          return calculatedLevel >= 2 && calculatedLevel < 4;
        });
        break;
      case 'New Students':
        // Students with Level 1-2 (0-250 XP) - Beginners
        filtered = students.filter(student => {
          const xp = parseInt(student.score?.replace(' XP', '') || '0');
          const calculatedLevel = calculateLevelFromXP(xp);
          return calculatedLevel >= 1 && calculatedLevel < 3;
        });
        break;
      case 'Need Support':
        // Students with Level 1 or low streak - Need encouragement
        filtered = students.filter(student => {
          const xp = parseInt(student.score?.replace(' XP', '') || '0');
          const calculatedLevel = calculateLevelFromXP(xp);
          const streak = student.streak || 0;
          const shouldInclude = calculatedLevel === 1 || streak < 2;
          console.log(`Student ${student.name}: XP=${xp}, Calculated Level=${calculatedLevel}, Streak=${streak}, Should Include=${shouldInclude}`);
          return shouldInclude;
        });
        break;
      default:
        filtered = students;
    }
    
    console.log('Filtered students:', filtered);
    return filtered;
  };

  const filteredStudents = getFilteredStudents();

  return (
    <div
      className="db-top-students-card"
      style={{
        backgroundColor: isHovered ? '#E0E0E0' : '#FFFFFF',
        transition: 'background-color 0.2s',
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <div className="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center mb-3">
        <Link 
          to="/student-list" 
          style={{ textDecoration: 'none', color: 'inherit' }}
          onClick={(e) => e.stopPropagation()}
        >
          <h3 style={{ color: '#000000', cursor: 'pointer', marginBottom: '0.5rem' }}>
            Top Students 
            <small style={{ fontSize: '0.8rem', color: '#6c757d', fontWeight: 'normal', display: 'block' }}>
              ({filteredStudents.length} {selectedCategory !== 'All' ? `in ${selectedCategory}` : 'total'})
            </small>
          </h3>
        </Link>
        <select 
          className="dropdown form-select form-select-sm"
          value={selectedCategory}
          onChange={handleCategoryChange}
          onClick={(e) => e.stopPropagation()}
          title={`Filter by engagement level: High Performers (Level 4+), Active Learners (Level 2-3), New Students (Level 1-2), Need Support (Level 1 or Low Streak)`}
          style={{ minWidth: '200px', maxWidth: '100%' }}
        >
          <option value="All">All Students</option>
          <option value="High Performers">High Performers (Level 4+)</option>
          <option value="Active Learners">Active Learners (Level 2-3)</option>
          <option value="New Students">New Students (Level 1-2)</option>
          <option value="Need Support">Need Support (Level 1/Low Streak)</option>
        </select>
      </div>
        <ul className="db-students-list">
          {filteredStudents.length > 0 ? (
            filteredStudents.map((student, index) => (
              <li key={index} className="db-student-item">
                <div className="db-student-avatar">
                  {student.profileImage ? (
                    <img 
                      src={student.profileImage} 
                      alt={student.fullName || student.name} 
                      className="db-top-student-img" 
                    />
                  ) : (
                    <div className="db-student-placeholder">
                      <i className="fas fa-user-circle"></i>
                      <div className="db-text-avatar">
                        {(student.fullName || student.name).charAt(0).toUpperCase()}
                      </div>
                    </div>
                  )}
                </div>
                <Link 
                  to="/student-list" 
                  style={{ textDecoration: 'none', color: 'inherit', flex: 1 }}
                  onClick={(e) => e.stopPropagation()}
                >
                  <div className="db-student-info" style={{ cursor: 'pointer' }}>
                    <span className="db-student-name">{student.fullName || student.name}</span>
                    <div className="db-student-details">
                      <span className="db-student-score">{student.score}</span>
                      <span className="db-student-level">Level {(() => {
                        const xp = parseInt(student.score?.replace(' XP', '') || '0');
                        return calculateLevelFromXP(xp);
                      })()}</span>
                      <span className="db-student-streak">{student.streak} day streak</span>
                    </div>
                  </div>
                </Link>
              </li>
            ))
          ) : (
            <li className="db-no-students" style={{ color: '#757575', textAlign: 'center', padding: '2rem' }}>
              <div className="mb-2">📚</div>
              <div>{selectedCategory === 'All' ? 'No students found' : `No students found in ${selectedCategory}`}</div>
              <small className="text-muted">Students will appear here once they start using the app</small>
            </li>
          )}
        </ul>
    </div>
  );
};

// Dashboard Component
const Dashboard = () => {
  const [stats, setStats] = useState({
    totalStudents: 0,
    improvedStudents: 0,
    needsImprovement: 0,
    teacherMaterials: 0,
    builtInModules: 0,
  });
  const [weeklyProgressData, setWeeklyProgressData] = useState({
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [{
      label: 'Progress',
      data: [0, 0, 0, 0, 0, 0, 0],
      borderColor: '#3B82F6',
      backgroundColor: 'rgba(59, 130, 246, 0.2)',
      fill: true,
      tension: 0.4
    }]
  });
  const [assessmentResultsData, setAssessmentResultsData] = useState({
    labels: ['Passed', 'Failed'],
    datasets: [{
      data: [1, 1], // Minimal default to ensure rendering
      backgroundColor: ['#A7F3D0', '#E5E7EB']
    }]
  });
  const [dailyLoginsData, setDailyLoginsData] = useState({
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [{
      label: 'Logins',
      data: [0, 0, 0, 0, 0, 0, 0],
      backgroundColor: '#93C5FD'
    }]
  });
  const [overallPerformanceData, setOverallPerformanceData] = useState({
    labels: ['Assessments', 'Comprehension', 'Pronunciation'],
    datasets: [{
      data: [1, 1, 1], // Minimal default to ensure rendering
      backgroundColor: ['#A5B4FC', '#FECACA', '#A7F0D0']
    }]
  });
  const [topStudents, setTopStudents] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch stats from actual student data collections
        const studentsQuery = query(collection(db, 'students'));
        const studentsSnapshot = await getDocs(studentsQuery);
        const totalStudents = studentsSnapshot.size;

        // Get improved students from adaptiveAssessmentResults (students with recent good performance)
        const recentAssessmentsQuery = query(
          collection(db, 'adaptiveAssessmentResults'),
          orderBy('timestamp', 'desc')
        );
        const recentAssessmentsSnapshot = await getDocs(recentAssessmentsQuery);
        
        const studentPerformance = {};
        recentAssessmentsSnapshot.forEach(doc => {
          const data = doc.data();
          const nickname = data.nickname;
          const performance = data.performance || 0;
          
          if (!studentPerformance[nickname]) {
            studentPerformance[nickname] = [];
          }
          studentPerformance[nickname].push(performance);
        });

        let improvedStudents = 0;
        let needsImprovement = 0;
        
        Object.keys(studentPerformance).forEach(nickname => {
          const performances = studentPerformance[nickname];
          const avgPerformance = performances.reduce((a, b) => a + b, 0) / performances.length;
          
          if (avgPerformance >= 0.7) {
            improvedStudents++;
          } else if (avgPerformance < 0.5) {
            needsImprovement++;
          }
        });

        // Count teacher-uploaded materials
        const teacherMaterialsQuery = query(
          collection(db, 'contents'), 
          where('type', 'in', ['lesson', 'interactive-lesson', 'material', 'uploaded-material'])
        );
        const teacherMaterialsSnapshot = await getDocs(teacherMaterialsQuery);
        const teacherMaterials = teacherMaterialsSnapshot.size;
        
        // Count built-in learning modules (hardcoded in Flutter app)
        const builtInModules = 15; // Functional Academics(5) + Communication Skills(3) + Pre-Vocational(2) + Social Skills(2) + Number Skills(2) + Self Help(1)
        
        console.log('Teacher materials found:', teacherMaterials);
        console.log('Built-in modules:', builtInModules);

        setStats({
          totalStudents,
          improvedStudents,
          needsImprovement,
          teacherMaterials,
          builtInModules,
        });

        // Fetch weekly progress from lessonRetention (actual student activity)
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);
        
        const progressQuery = query(
          collection(db, 'lessonRetention'),
          where('completedAt', '>=', weekAgo),
          orderBy('completedAt', 'desc')
        );
        const progressSnapshot = await getDocs(progressQuery);
        
        const progressData = Array(7).fill(0);
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        
        progressSnapshot.forEach(doc => {
          const data = doc.data();
          const completedAt = data.completedAt?.toDate();
          if (completedAt) {
            const dayOfWeek = completedAt.getDay();
            const dayIndex = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // Convert Sunday=0 to Sunday=6
            if (dayIndex >= 0 && dayIndex < 7) {
              progressData[dayIndex]++;
            }
          }
        });
        setWeeklyProgressData({
          labels,
          datasets: [{
            label: 'Progress',
            data: progressData,
            borderColor: '#3B82F6',
            backgroundColor: 'rgba(59, 130, 246, 0.2)',
            fill: true,
            tension: 0.4
          }]
        });

        // Fetch assessment results from adaptiveAssessmentResults
        const assessmentResultsQuery = query(collection(db, 'adaptiveAssessmentResults'));
        const assessmentResultsSnapshot = await getDocs(assessmentResultsQuery);
        let passed = 0, failed = 0;
        
        assessmentResultsSnapshot.forEach(doc => {
          const data = doc.data();
          const performance = data.performance || 0;
          if (performance >= 0.7) {
            passed++;
          } else {
            failed++;
          }
        });
        
        setAssessmentResultsData({
          labels: ['Passed', 'Failed'],
          datasets: [{
            data: [passed > 0 || failed > 0 ? passed : 1, passed > 0 || failed > 0 ? failed : 1],
            backgroundColor: ['#A7F3D0', '#E5E7EB']
          }]
        });

        // Fetch daily logins from studentLogins collection (actual data from Flutter app)
        const loginsQuery = query(collection(db, 'studentLogins'), orderBy('loginTime', 'desc'), limit(50));
        const loginsSnapshot = await getDocs(loginsQuery);
        const loginsData = Array(7).fill(0);
        
        // Group logins by day of week for the last 7 days
        const today = new Date();
        
        loginsSnapshot.forEach(doc => {
          const data = doc.data();
          const loginTime = data.loginTime?.toDate();
          if (loginTime) {
            const daysDiff = Math.floor((today - loginTime) / (1000 * 60 * 60 * 24));
            if (daysDiff >= 0 && daysDiff < 7) {
              const dayOfWeek = loginTime.getDay();
              loginsData[dayOfWeek]++;
            }
          }
        });
        setDailyLoginsData({
          labels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          datasets: [{
            label: 'Logins',
            data: loginsData,
            backgroundColor: '#93C5FD'
          }]
        });

        // Fetch overall class performance
        const performanceQuery = query(collection(db, 'students'));
        const performanceSnapshot = await getDocs(performanceQuery);
        let assessments = 0, comprehension = 0, pronunciation = 0;
        performanceSnapshot.forEach(doc => {
          const data = doc.data();
          assessments += data.assessmentScore || 0;
          comprehension += data.comprehensionScore || 0;
          pronunciation += data.pronunciationScore || 0;
        });
        setOverallPerformanceData({
          labels: ['Assessments', 'Comprehension', 'Pronunciation'],
          datasets: [{
            data: [assessments > 0 || comprehension > 0 || pronunciation > 0 ? assessments : 1, 
                   comprehension > 0 || assessments > 0 || pronunciation > 0 ? comprehension : 1, 
                   pronunciation > 0 || assessments > 0 || comprehension > 0 ? pronunciation : 1],
            backgroundColor: ['#A5B4FC', '#FECACA', '#A7F0D0']
          }]
        });

        // Fetch top students from userStats (real student performance data)
        const topStudentsQuery = query(
          collection(db, 'userStats'),
          orderBy('totalXP', 'desc'),
          limit(12)
        );
        const topStudentsSnapshot = await getDocs(topStudentsQuery);
        
        // Also fetch student profile data to get profile images
        const studentProfilesQuery = query(collection(db, 'students'));
        const studentProfilesSnapshot = await getDocs(studentProfilesQuery);
        const studentProfiles = {};
        studentProfilesSnapshot.forEach(doc => {
          const data = doc.data();
          if (data.nickname) {
            studentProfiles[data.nickname] = {
              profileImage: data.profileImage,
              firstName: data.firstName,
              surname: data.surname,
              middleName: data.middleName
            };
          }
        });
        
        const topStudentsData = topStudentsSnapshot.docs.map(doc => {
          const data = doc.data();
          const profileData = studentProfiles[data.nickname] || {};
          const studentData = {
            name: data.nickname || 'Unknown',
            score: data.totalXP ? `${data.totalXP} XP` : '0 XP',
            level: data.currentLevel || 1,
            streak: data.streakDays || 0,
            profileImage: profileData.profileImage || null,
            fullName: profileData.firstName && profileData.surname 
              ? `${profileData.firstName} ${profileData.middleName || ''} ${profileData.surname}`.trim()
              : data.nickname || 'Unknown'
          };
          console.log(`Fetched student data for ${studentData.name}:`, studentData);
          return studentData;
        });
        setTopStudents(topStudentsData.length > 0 ? topStudentsData : []);
        
        // Fetch game session data for additional analytics
        try {
          const gameSessionsQuery = query(collection(db, 'gameSessions'));
          const gameSessionsSnapshot = await getDocs(gameSessionsQuery);
          console.log('Game sessions found:', gameSessionsSnapshot.size);
          
          const flashcardSessionsQuery = query(collection(db, 'flashcardSessions'));
          const flashcardSessionsSnapshot = await getDocs(flashcardSessionsQuery);
          console.log('Flashcard sessions found:', flashcardSessionsSnapshot.size);
          
          const visitTrackingQuery = query(collection(db, 'visitTracking'));
          const visitTrackingSnapshot = await getDocs(visitTrackingQuery);
          console.log('Visit tracking records found:', visitTrackingSnapshot.size);
        } catch (gameError) {
          console.log('Game data not available yet:', gameError);
        }
        
      } catch (error) {
        console.error('Error fetching data:', error);
      }
    };

    fetchData();
  }, []);

  const weeklyProgressOptions = {
    scales: {
      y: {
        beginAtZero: true,
        max: 10
      }
    },
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        enabled: true,
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        titleColor: '#ffffff',
        bodyColor: '#ffffff',
        borderColor: '#3B82F6',
        borderWidth: 1,
        cornerRadius: 8,
        displayColors: false,
        callbacks: {
          title: function(context) {
            return context[0].label;
          },
          label: function(context) {
            return `Progress: ${context.parsed.y}`;
          }
        }
      }
    },
    interaction: {
      intersect: false,
      mode: 'index'
    }
  };

  const assessmentResultsOptions = {
    plugins: {
      legend: {
        position: 'bottom',
        labels: {
          boxWidth: 20,
          padding: 15
        }
      }
    }
  };

  const dailyLoginsOptions = {
    scales: {
      y: {
        beginAtZero: true
      }
    },
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        enabled: true,
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        titleColor: '#ffffff',
        bodyColor: '#ffffff',
        borderColor: '#93C5FD',
        borderWidth: 1,
        cornerRadius: 8,
        displayColors: false,
        callbacks: {
          title: function(context) {
            return context[0].label;
          },
          label: function(context) {
            return `Logins: ${context.parsed.y}`;
          }
        }
      }
    },
    interaction: {
      intersect: false,
      mode: 'index'
    }
  };

  const overallPerformanceOptions = {
    plugins: {
      legend: {
        position: 'right',
        labels: {
          boxWidth: 20,
          padding: 15
        }
      }
    }
  };

  return (
    <div className="container py-5">
      {/* Professional Dashboard Header */}
      <div className="dashboard-header">
        <h1 className="dashboard-title">DASHBOARD</h1>
        <p className="dashboard-subtitle">Comprehensive overview of your teaching environment</p>
      </div>

      {/* Stats Cards - Uniform Grid Layout */}
      <div className="row mb-5 g-4">
        <div className="col-xl-2 col-lg-4 col-md-6 col-sm-12">
          <StatCard
            value={stats.totalStudents}
            label="Total Students"
            className="db-total-students"
            to="/student-list"
          />
        </div>
        <div className="col-xl-2 col-lg-4 col-md-6 col-sm-12">
          <StatCard
            value={stats.improvedStudents}
            label="Improved Students"
            className="db-improved-students"
            to="/reports"
          />
        </div>
        <div className="col-xl-2 col-lg-4 col-md-6 col-sm-12">
          <StatCard
            value={stats.needsImprovement}
            label="Needs Improvement"
            className="db-needs-improvement"
            to="/reports"
          />
        </div>
        <div className="col-xl-3 col-lg-6 col-md-6 col-sm-12">
          <StatCard
            value={stats.teacherMaterials}
            label="Teacher Materials"
            className="db-teacher-materials"
            to="/contents?filter=teacher-materials"
          />
        </div>
        <div className="col-xl-3 col-lg-6 col-md-6 col-sm-12">
          <StatCard
            value={stats.builtInModules}
            label="Built-in Modules"
            className="db-built-in-modules"
            to="/built-in-modules"
          />
        </div>
      </div>

      {/* Charts and Top Students - Equal Layout */}
      <div className="row g-5">
        {/* Left Column: Charts */}
        <div className="col-lg-8">
          <div className="row g-4">
            {/* Weekly Progress */}
            <div className="col-lg-6 col-md-6">
              <ChartCard
                title="Weekly Progress"
                chartId="weeklyProgressChart"
                chartType="line"
                chartData={weeklyProgressData}
                chartOptions={weeklyProgressOptions}
                to="/progress"
              />
            </div>
            
            {/* Daily Logins */}
            <div className="col-lg-6 col-md-6">
              <ChartCard
                title="Daily Logins"
                chartId="dailyLoginsChart"
                chartType="bar"
                chartData={dailyLoginsData}
                chartOptions={dailyLoginsOptions}
                to="/logins"
              />
            </div>
            
            {/* Assessment Results */}
            <div className="col-lg-6 col-md-6">
              <ChartCard
                title="Assessment Results"
                chartId="assessmentResultsChart"
                chartType="pie"
                chartData={assessmentResultsData}
                chartOptions={assessmentResultsOptions}
                to="/assessments"
              />
            </div>
            
            {/* Overall Class Performance */}
            <div className="col-lg-6 col-md-6">
              <ChartCard
                title="Overall Class Performance"
                chartId="overallPerformanceChart"
                chartType="pie"
                chartData={overallPerformanceData}
                chartOptions={overallPerformanceOptions}
                className="db-overall-performance-card"
                to="/performance"
              />
            </div>
          </div>
        </div>

        {/* Right Column: Top Students */}
        <div className="col-lg-4">
          <TopStudentsCard students={topStudents} />
        </div>
      </div>
    </div>
  );
};

export default Dashboard;