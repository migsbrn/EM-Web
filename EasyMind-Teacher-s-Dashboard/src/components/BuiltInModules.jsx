import React from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/BuiltInModules.css';

const BuiltInModules = () => {
  const navigate = useNavigate();

  const modules = [
    {
      category: "Functional Academics",
      icon: "🎯",
      color: "#e6f0e8",
      modules: [
        { name: "Learn The Alphabets", description: "Interactive alphabet learning with letters A-Z", students: "All students" },
        { name: "Rhyme and Read", description: "Reading and rhyming activities", students: "All students" },
        { name: "Learn Colors", description: "Color recognition (Red, Blue, Green, Yellow, Purple, Orange, Pink)", students: "All students" },
        { name: "Learn Shapes", description: "Shape identification (Circle, Square, Triangle, Rectangle, Star)", students: "All students" },
        { name: "Learn My Family", description: "Family relationships and members", students: "All students" }
      ]
    },
    {
      category: "Communication Skills",
      icon: "💬",
      color: "#f0e8e8",
      modules: [
        { name: "Picture Story Reading", description: "Story comprehension through images", students: "All students" },
        { name: "Soft & Loud Sounds", description: "Sound recognition and volume differentiation", students: "All students" },
        { name: "Text to Speech Learning", description: "Speech-to-text and text-to-speech activities", students: "All students" }
      ]
    },
    {
      category: "Pre-Vocational Skills",
      icon: "🔧",
      color: "#d6e8ed",
      modules: [
        { name: "Basic Vocational Skills", description: "Work preparation fundamentals", students: "All students" },
        { name: "Work Preparation", description: "Job readiness activities", students: "All students" }
      ]
    },
    {
      category: "Social Skills",
      icon: "👥",
      color: "#e8e9f5",
      modules: [
        { name: "Social Interaction", description: "Communication and social behavior", students: "All students" },
        { name: "Communication Skills", description: "Verbal and non-verbal communication", students: "All students" }
      ]
    },
    {
      category: "Number Skills",
      icon: "🧮",
      color: "#fde6ff",
      modules: [
        { name: "Number Recognition", description: "Learning numbers 1-10", students: "All students" },
        { name: "Basic Math", description: "Simple addition and subtraction", students: "All students" }
      ]
    },
    {
      category: "Self Help",
      icon: "🛠️",
      color: "#f0f3f6",
      modules: [
        { name: "Daily Living Skills", description: "Personal care and daily routines", students: "All students" }
      ]
    }
  ];

  const totalModules = modules.reduce((total, category) => total + category.modules.length, 0);

  return (
    <div className="built-in-modules-page">
      <div className="page-header">
        <button 
          className="back-button"
          onClick={() => navigate('/teacher-dashboard')}
        >
          ← Back to Dashboard
        </button>
        <h1>📚 Built-in Learning Modules</h1>
        <p className="page-subtitle">
          These {totalModules} pre-built modules are available to all students in the mobile app
        </p>
      </div>

      <div className="modules-overview">
        <div className="overview-card">
          <h3>📊 Overview</h3>
          <div className="overview-stats">
            <div className="stat-item">
              <span className="stat-number">{totalModules}</span>
              <span className="stat-label">Total Modules</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">{modules.length}</span>
              <span className="stat-label">Categories</span>
            </div>
            <div className="stat-item">
              <span className="stat-number">100%</span>
              <span className="stat-label">Student Access</span>
            </div>
          </div>
        </div>
      </div>

      <div className="modules-grid">
        {modules.map((category, index) => (
          <div key={index} className="category-card" style={{ borderLeftColor: category.color }}>
            <div className="category-header">
              <span className="category-icon">{category.icon}</span>
              <h3 className="category-title">{category.category}</h3>
              <span className="module-count">{category.modules.length} modules</span>
            </div>
            
            <div className="modules-list">
              {category.modules.map((module, moduleIndex) => (
                <div key={moduleIndex} className="module-item">
                  <div className="module-info">
                    <h4 className="module-name">{module.name}</h4>
                    <p className="module-description">{module.description}</p>
                  </div>
                  <div className="module-status">
                    <span className="status-badge available">✓ Available</span>
                    <span className="student-access">{module.students}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <div className="info-section">
        <div className="info-card">
          <h3>ℹ️ Important Information</h3>
          <ul>
            <li>These modules are <strong>built into the student mobile app</strong></li>
            <li>Students can access them through <strong>"Learning Materials"</strong> section</li>
            <li>No teacher uploads or configuration required</li>
            <li>All modules include <strong>interactive features</strong> and <strong>progress tracking</strong></li>
            <li>Modules are designed for <strong>special needs education</strong></li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default BuiltInModules;
