import { useState, useEffect } from "react";
import "../styles/Assessments.css";
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import "bootstrap/dist/css/bootstrap.min.css";

// Import the specific components for each category
import FunctionalR from './FunctionalR';
import ComS from './ComS';
import SocialS from './SocialS';
import Prevoc from './Prevoc';

const Assessments = () => {
  // State to manage which component to render
  const [activeScreen, setActiveScreen] = useState("categories"); // 'categories', 'functionalR', 'communicationS', 'prevoc', 'socialS'

  useEffect(() => {
    // Load Font Awesome CDN
    const fontAwesome = document.createElement("link");
    fontAwesome.rel = "stylesheet";
    fontAwesome.href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css";
    document.head.appendChild(fontAwesome);

    // Override browser back button to always return to assessments page
    const handlePopState = () => {
      setActiveScreen("categories"); // Force back to assessments page
    };

    window.addEventListener("popstate", handlePopState);

    // Cleanup
    return () => {
      document.head.removeChild(fontAwesome);
      window.removeEventListener("popstate", handlePopState);
    };
  }, []);

  const navigateTo = (screen) => {
    setActiveScreen(screen);
  };

  const renderScreen = () => {
    switch (activeScreen) {
      case "functionalR":
        return <FunctionalR onBack={() => setActiveScreen("categories")} />;
      case "communicationS":
        return <ComS onBack={() => setActiveScreen("categories")} />;
      case "prevoc":
        return <Prevoc onBack={() => setActiveScreen("categories")} />;
      case "socialS":
        return <SocialS onBack={() => setActiveScreen("categories")} />;
      case "categories":
      default:
        return (
          <div className="assessments-main-container">
            {/* Professional Header Section */}
            <div className="assessments-header">
              <div className="assessments-header-content">
                <div className="assessments-title-section">
                  <h1 className="assessments-main-title">
                    <i className="fas fa-clipboard-check me-3"></i>
                    Assessment Management
                  </h1>
                  <p className="assessments-subtitle">
                    Monitor and analyze student performance across different learning domains
                  </p>
                </div>
                <div className="assessments-stats">
                  <div className="stat-item">
                    <div className="stat-number">4</div>
                    <div className="stat-label">Categories</div>
                  </div>
                  <div className="stat-item">
                    <div className="stat-number">13</div>
                    <div className="stat-label">Assessment Types</div>
                  </div>
                  <div className="stat-item">
                    <div className="stat-number">100%</div>
                    <div className="stat-label">Real-time Data</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Assessment Categories Grid */}
            <div className="assessments-categories-section">
              <div className="assessments-section-header">
                <h2 className="assessments-section-title">
                  <i className="fas fa-layer-group me-2"></i>
                  Assessment Categories
                </h2>
                <p className="assessments-section-description">
                  Select a category to view detailed assessment results and student performance
                </p>
              </div>
              
              <div className="row g-4">
                {categories.map((category, index) => (
                  <div key={category.name} className="col-12 col-md-6 col-lg-3">
                    <div
                      className="assessment-category-card"
                      style={{ 
                        '--card-color': category.color,
                        '--card-hover-color': category.hoverColor,
                        '--card-index': index
                      }}
                      onClick={() => navigateTo(category.screen)}
                    >
                      <div className="category-card-header">
                        <div className="category-icon-wrapper">
                          <i className={`category-icon ${category.icon}`}></i>
                        </div>
                        <div className="category-badge">
                          <span className="badge-text">View Results</span>
                          <i className="fas fa-arrow-right"></i>
                        </div>
                      </div>
                      
                      <div className="category-card-body">
                        <h3 className="category-title">{category.name}</h3>
                        <p className="category-description">{category.description}</p>
                        
                        <div className="category-features">
                          <div className="feature-item">
                            <i className="fas fa-chart-line"></i>
                            <span>Performance Analytics</span>
                          </div>
                          <div className="feature-item">
                            <i className="fas fa-users"></i>
                            <span>Student Progress</span>
                          </div>
                          <div className="feature-item">
                            <i className="fas fa-clock"></i>
                            <span>Real-time Updates</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

          </div>
        );
    }
  };

  const categories = [
    {
      name: "Functional Academics",
      icon: "fas fa-book",
      description: "Assess reading, writing, and practical math skills including alphabet, colors, shapes, and numbers.",
      screen: "functionalR",
      color: "#10b981",
      hoverColor: "#059669"
    },
    {
      name: "Communication Skills",
      icon: "fas fa-comment",
      description: "Evaluate verbal, non-verbal, and comprehension abilities including picture stories and daily tasks.",
      screen: "communicationS",
      color: "#8b5cf6",
      hoverColor: "#7c3aed"
    },
    {
      name: "Pre-vocational Skills",
      icon: "fas fa-briefcase",
      description: "Measure foundational work readiness and job skills for career preparation.",
      screen: "prevoc",
      color: "#f59e0b",
      hoverColor: "#d97706"
    },
    {
      name: "Social Skills",
      icon: "fas fa-handshake",
      description: "Analyze interaction, empathy, and group participation skills.",
      screen: "socialS",
      color: "#06b6d4",
      hoverColor: "#0891b2"
    },
  ];

  return (
    <div className="container-fluid assessments-container">
      {renderScreen()}
    </div>
  );
};

export default Assessments;