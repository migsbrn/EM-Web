import { useState, useEffect, useCallback } from "react";
import { useLocation } from "react-router-dom";
import { db } from "../firebase";
import {
  collection,
  getDocs,
  addDoc,
  deleteDoc,
  doc,
  updateDoc,
  serverTimestamp,
  query,
  orderBy,
  where,
  getDoc,
} from "firebase/firestore";
import { getAuth, onAuthStateChanged } from "firebase/auth";
import ContentCreation from "./ContentCreation";
import RobustContentCreation from "./RobustContentCreation";
import "../styles/Contents.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import "bootstrap/dist/css/bootstrap.min.css";

const categories = [
  "NUMBER_SKILLS",
  "SELF_HELP",
  "PRE-VOCATIONAL_SKILLS",
  "SOCIAL_SKILLS",
  "FUNCTIONAL_ACADEMICS",
  "COMMUNICATION_SKILLS",
];

const displayCategory = (category) =>
  category && categories.includes(category)
    ? category.toLowerCase().replace(/_/g, " ")
    : "unknown";

const Contents = () => {
  const location = useLocation();
  const auth = getAuth();

  // State for teacher authentication
  const [teacherId, setTeacherId] = useState(null);

  // State for content data
  const [contents, setContents] = useState([]);
  const [timeRange, setTimeRange] = useState("all_time");
  const [dateFilter, setDateFilter] = useState("");
  const [showAssessments, setShowAssessments] = useState(false);
  const [assessmentStatus, setAssessmentStatus] = useState({});
  const [filterType, setFilterType] = useState("all");

  // State for assessment form
  const [showAssessmentForm, setShowAssessmentForm] = useState(false);
  const [assessmentTitle, setAssessmentTitle] = useState("");
  const [assessmentDescription, setAssessmentDescription] = useState("");
  const [assessmentCategory, setAssessmentCategory] = useState(categories[0]);
  const [assessmentQuestions, setAssessmentQuestions] = useState([]);
  const [currentQuestion, setCurrentQuestion] = useState({
    questionText: "",
    options: ["", "", "", ""],
    correctAnswer: "",
    image: null,
  });
  const [editingQuestionIndex, setEditingQuestionIndex] = useState(null);

  // State for delete confirmation
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [itemToDelete, setItemToDelete] = useState(null);

  // State for form exit confirmation
  const [showExitModal, setShowExitModal] = useState(false);
  const [pendingFormAction, setPendingFormAction] = useState(null);

  // State for notification
  const [notification, setNotification] = useState(null);

  // State for content creation modal
  const [showContentCreation, setShowContentCreation] = useState(false);
  const [showRobustContentCreation, setShowRobustContentCreation] =
    useState(false);
  const [contentToEdit, setContentToEdit] = useState(null);

  // State for refresh trigger
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  // State for preview modal
  const [showPreviewModal, setShowPreviewModal] = useState(false);
  const [previewContent, setPreviewContent] = useState(null);
  const [isEditMode, setIsEditMode] = useState(false);
  const [editableQuestions, setEditableQuestions] = useState([]);

  // State for teacher name and loading
  const [teacherName, setTeacherName] = useState("Unknown");

  // Fetch teacher name from Firestore
  const fetchTeacherName = async (userId) => {
    try {
      const teacherDocRef = doc(db, "teacherRequests", userId);
      const teacherDoc = await getDoc(teacherDocRef);
      if (teacherDoc.exists()) {
        const teacherData = teacherDoc.data();
        const fullName =
          `${teacherData.firstName || ""} ${
            teacherData.lastName || ""
          }`.trim() || "Unknown";
        setTeacherName(fullName);
      } else {
        setTeacherName("Unknown");
      }
    } catch (error) {
      console.error("Error fetching teacher name:", error.message);
      setTeacherName("Unknown");
    }
  };

  // Listen for authentication state changes and set teacherId
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        console.log("User authenticated:", user.uid);
        setTeacherId(user.uid);
        await fetchTeacherName(user.uid);
      } else {
        console.log("No user authenticated");
        setTeacherId(null);
        setTeacherName("Unknown");
        setContents([]);
      }
    });

    return () => unsubscribe();
  }, [auth]);

  // Handle URL parameters for filtering
  useEffect(() => {
    const urlParams = new URLSearchParams(location.search);
    const filter = urlParams.get("filter");

    if (filter === "teacher-materials") {
      setFilterType("teacher-materials");
      setShowAssessments(false);
    } else if (filter === "built-in-modules") {
      setFilterType("built-in-modules");
      setShowAssessments(false);
    } else {
      setFilterType("all");
    }
  }, [location.search]);

  // Fetch content from Firestore
  useEffect(() => {
    const fetchData = async () => {
      console.log("=== Fetching content data ===");
      console.log("TeacherId:", teacherId);
      console.log("FilterType:", filterType);
      console.log("ShowAssessments:", showAssessments);

      if (!teacherId || filterType === "built-in-modules") {
        console.log("Skipping fetch - no teacherId or built-in-modules filter");
        setContents([]);
        return;
      }

      try {
        let contentsQuery = collection(db, "contents");
        let queryConstraints = [where("createdBy", "==", teacherId)];

        if (showAssessments) {
          queryConstraints.push(
            where("type", "in", ["assessment", "interactive-assessment"])
          );
        } else {
          queryConstraints.push(
            where("type", "in", [
              "material",
              "uploaded-material",
              "interactive-lesson",
              "game-activity",
              "lesson",
              "game",
              "activity",
              "interactive-colors",
              "interactive-alphabet",
              "interactive-shapes",
              "interactive-numbers",
              "interactive-animals",
              "interactive-emotions",
              "interactive-daily_routines",
              "interactive-vocational",
            ])
          );
        }

        let sortField = "createdAt";
        if (timeRange !== "all_time") {
          const now = new Date();
          let startDate;
          switch (timeRange) {
            case "1_day":
              startDate = new Date(now.setDate(now.getDate() - 1));
              break;
            case "7_days":
              startDate = new Date(now.setDate(now.getDate() - 7));
              break;
            case "30_days":
              startDate = new Date(now.setDate(now.getDate() - 30));
              break;
            default:
              startDate = new Date(0);
          }
          queryConstraints.push(where(sortField, ">=", startDate));
        }

        let contentsData = [];

        if (dateFilter) {
          try {
            const selectedDate = new Date(dateFilter);
            selectedDate.setHours(0, 0, 0, 0);

            const nextDate = new Date(selectedDate);
            nextDate.setDate(nextDate.getDate() + 1);

            queryConstraints.push(where(sortField, ">=", selectedDate));
            queryConstraints.push(where(sortField, "<", nextDate));
          } catch (e) {
            console.error("Invalid date filter:", e);
          }
        }

        queryConstraints.push(orderBy(sortField, "desc"));

        let finalQuery = query(contentsQuery, ...queryConstraints);

        console.log("Executing Firestore query...");
        const contentsSnapshot = await getDocs(finalQuery);
        contentsData = contentsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
          createdAt: doc.data().createdAt?.toDate(),
        }));

        console.log(`Fetched ${contentsData.length} items from Firestore`);
        console.log("Setting contents state with data:", contentsData);
        setContents(contentsData);
      } catch (error) {
        console.error("Error fetching contents:", error.message);
        console.error("Error details:", error);
      }
    };

    fetchData();
  }, [
    timeRange,
    dateFilter,
    showAssessments,
    refreshTrigger,
    filterType,
    teacherId,
  ]);

  const checkAssessmentStatusForAllLessons = useCallback(async () => {
    try {
      // Logic for checking assessment status
    } catch (error) {
      console.error("Error checking assessment status:", error);
    }
  }, [contents, auth]);

  useEffect(() => {
    if (contents.length > 0) {
      checkAssessmentStatusForAllLessons();
    }
  }, [contents, checkAssessmentStatusForAllLessons]);

  const showNotification = (message) => {
    setNotification(message);
    setTimeout(() => setNotification(null), 2000);
  };

  const refreshContent = () => {
    console.log("Triggering content refresh...");
    setRefreshTrigger((prev) => prev + 1);
  };

  const handlePreviewAndEditAssessment = (content) => {
    console.log("Opening assessment for preview/edit:", content);

    setPreviewContent(content);
    setShowPreviewModal(true);
    setIsEditMode(true);

    if (
      content.type === "assessment" ||
      content.type === "interactive-assessment"
    ) {
      const questions =
        content.questions || content.assessmentData?.questions || [];

      console.log("Raw questions data:", questions);

      const editableQuestions = questions.map((question, index) => {
        console.log(`Processing question ${index}:`, question);

        return {
          ...question,
          questionText: question.questionText || question.question || "",
          options:
            Array.isArray(question.options) && question.options.length >= 4
              ? question.options
              : ["", "", "", ""],
          correctAnswer: question.correctAnswer || "",
          image: question.image || question.questionImage || null,
        };
      });

      console.log("Processed editable questions:", editableQuestions);
      setEditableQuestions(editableQuestions);
    }
  };

  const handleSaveEditableAssessment = async () => {
    if (!previewContent) return;

    try {
      console.log("Saving quiz with questions:", editableQuestions);

      const questionsWithImages = editableQuestions.filter((q) => q.image);

      for (let i = 0; i < questionsWithImages.length; i++) {
        const question = questionsWithImages[i];
        if (question.image && question.image.length > 200000) {
          console.warn(
            `Question ${i + 1} image is too large: ${
              question.image.length
            } characters`
          );
          alert(
            `Question ${i + 1} image is too large (${Math.round(
              question.image.length / 1000
            )}KB). Please use a smaller image.`
          );
          return;
        }
      }

      const assessmentRef = doc(db, "contents", previewContent.id);

      const updateData = {
        questions: editableQuestions.map((q) => ({
          ...q,
          question: q.questionText || q.question,
          questionText: q.questionText || q.question,
        })),
        assessmentData: {
          ...previewContent.assessmentData,
          questions: editableQuestions.map((q) => ({
            ...q,
            question: q.questionText || q.question,
            questionText: q.questionText || q.question,
          })),
        },
        updatedAt: serverTimestamp(),
        lastModified: new Date().toISOString(),
        version: (previewContent.version || 0) + 1,
        cacheBuster: Date.now(),
        forceRefresh: true,
      };

      const totalDataSize = JSON.stringify(updateData).length;

      if (totalDataSize > 1000000) {
        console.warn(`Total data size too large: ${totalDataSize} characters`);
        alert(
          `Quiz data is too large (${Math.round(
            totalDataSize / 1000
          )}KB). Please remove some images or use smaller images.`
        );
        return;
      }

      await updateDoc(assessmentRef, updateData);

      setPreviewContent({
        ...previewContent,
        questions: editableQuestions.map((q) => ({
          ...q,
          question: q.questionText || q.question,
          questionText: q.questionText || q.question,
        })),
        assessmentData: {
          ...previewContent.assessmentData,
          questions: editableQuestions.map((q) => ({
            ...q,
            question: q.questionText || q.question,
            questionText: q.questionText || q.question,
          })),
        },
        lastModified: updateData.lastModified,
        version: updateData.version,
      });

      setIsEditMode(false);
      showNotification(
        "Quiz updated successfully! Please refresh the Flutter app to see changes."
      );
      refreshContent();
    } catch (error) {
      console.error("Error updating assessment:", error);

      if (
        error.message.includes("invalid nested entity") ||
        error.message.includes("too large")
      ) {
        try {
          const assessmentRef = doc(db, "contents", previewContent.id);

          const questionsWithoutImages = editableQuestions.map((q) => ({
            ...q,
            image: undefined,
            questionImage: undefined,
            questionImageFile: undefined,
          }));

          const updateDataWithoutImages = {
            questions: questionsWithoutImages,
            assessmentData: {
              ...previewContent.assessmentData,
              questions: questionsWithoutImages,
            },
            updatedAt: serverTimestamp(),
          };

          await updateDoc(assessmentRef, updateDataWithoutImages);

          setPreviewContent({
            ...previewContent,
            questions: questionsWithoutImages,
            assessmentData: {
              ...previewContent.assessmentData,
              questions: questionsWithoutImages,
            },
          });

          setIsEditMode(false);
          showNotification(
            "Quiz saved, but images were too large and removed. Please use smaller images."
          );
          refreshContent();
          return;
        } catch (fallbackError) {
          console.error("Fallback save also failed:", fallbackError);
        }
      }

      showNotification("Failed to update quiz. Please try again.");
    }
  };

  const hasAssessmentChanges = () => {
    return (
      assessmentTitle ||
      assessmentDescription ||
      assessmentCategory !== categories[0] ||
      assessmentQuestions.length > 0 ||
      currentQuestion.questionText ||
      currentQuestion.options.some((opt) => opt) ||
      currentQuestion.correctAnswer ||
      currentQuestion.image
    );
  };

  const confirmExit = () => {
    if (pendingFormAction) {
      pendingFormAction();
      setPendingFormAction(null);
    }
    setShowExitModal(false);
  };

  const cancelExit = () => {
    setPendingFormAction(null);
    setShowExitModal(false);
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      const allowedTypes = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/gif",
      ];
      if (!allowedTypes.includes(file.type)) {
        alert("Please select a valid image file (JPEG, PNG, or GIF)");
        return;
      }

      const maxSize = 5 * 1024 * 1024;
      if (file.size > maxSize) {
        alert("File size must be less than 5MB");
        return;
      }

      const reader = new FileReader();
      reader.onload = (e) => {
        const base64String = e.target.result;
        setCurrentQuestion({
          ...currentQuestion,
          image: base64String,
        });
      };
      reader.onerror = () => {
        alert("Error reading file. Please try again.");
      };
      reader.readAsDataURL(file);
    }
  };

  const removeQuestionImage = () => {
    setCurrentQuestion({
      ...currentQuestion,
      image: null,
    });
  };

  const handleAddQuestion = () => {
    try {
      if (!currentQuestion.questionText.trim()) {
        alert("Please enter a question.");
        return;
      }

      if (
        currentQuestion.options.length < 2 ||
        currentQuestion.options.some((opt) => !opt.trim()) ||
        !currentQuestion.correctAnswer
      ) {
        alert(
          "Please provide at least two non-empty options and select a correct answer."
        );
        return;
      }
      if (!currentQuestion.options.includes(currentQuestion.correctAnswer)) {
        alert("The correct answer must match one of the options.");
        return;
      }

      if (editingQuestionIndex !== null) {
        const updatedQuestions = [...assessmentQuestions];
        updatedQuestions[editingQuestionIndex] = currentQuestion;
        setAssessmentQuestions(updatedQuestions);
        setEditingQuestionIndex(null);
        showNotification("Question updated!");
      } else {
        setAssessmentQuestions([...assessmentQuestions, currentQuestion]);
        showNotification("Question added!");
      }

      setCurrentQuestion({
        questionText: "",
        options: ["", "", "", ""],
        correctAnswer: "",
        image: null,
      });
    } catch (error) {
      console.error("Error adding question:", error.message);
      alert("Failed to add question. Please try again.");
    }
  };

  const handleDeleteQuestion = (index) => {
    try {
      const updatedQuestions = assessmentQuestions.filter(
        (_, i) => i !== index
      );
      setAssessmentQuestions(updatedQuestions);
      showNotification("Question deleted!");
    } catch (error) {
      console.error("Error deleting question:", error.message);
      alert("Failed to delete question. Please try again.");
    }
  };

  const handleEditQuestion = (index) => {
    setCurrentQuestion({ ...assessmentQuestions[index] });
    setEditingQuestionIndex(index);
  };

  const resetAssessmentForm = () => {
    setAssessmentTitle("");
    setAssessmentDescription("");
    setAssessmentCategory(categories[0]);
    setAssessmentQuestions([]);
    setCurrentQuestion({
      questionText: "",
      options: ["", "", "", ""],
      correctAnswer: "",
      image: null,
    });
    setEditingQuestionIndex(null);
  };

  const handleAddAssessment = async (e) => {
    e.preventDefault();
    try {
      if (!assessmentTitle.trim()) {
        alert("Please enter a quiz title.");
        return;
      }

      let finalQuestions = [...assessmentQuestions];
      if (finalQuestions.length === 0 && currentQuestion.questionText.trim()) {
        if (
          currentQuestion.options.length < 2 ||
          currentQuestion.options.some((opt) => !opt.trim()) ||
          !currentQuestion.correctAnswer
        ) {
          alert(
            "Please complete the current question: provide at least two non-empty options and select a correct answer."
          );
          return;
        }
        if (!currentQuestion.options.includes(currentQuestion.correctAnswer)) {
          alert("The correct answer must match one of the options.");
          return;
        }

        finalQuestions.push(currentQuestion);
      }

      if (finalQuestions.length === 0) {
        alert("Please add at least one question.");
        return;
      }

      const user = auth.currentUser;
      if (!user) throw new Error("No authenticated teacher");

      await addDoc(collection(db, "contents"), {
        type: "assessment",
        title: assessmentTitle,
        description: assessmentDescription,
        category: assessmentCategory,
        questions: finalQuestions,
        createdBy: user.uid,
        createdAt: serverTimestamp(),
      });

      await fetchTeacherName(user.uid);

      await addDoc(collection(db, "logs"), {
        teacherName: teacherName,
        activityDescription: `Added quiz: ${assessmentTitle}`,
        createdAt: serverTimestamp(),
      });

      resetAssessmentForm();
      setShowAssessmentForm(false);

      refreshContent();
      showNotification("Quiz added successfully!");
    } catch (error) {
      console.error("Error adding quiz:", error.message);
      alert("Failed to add quiz. Please try again.");
    }
  };

  const handleDeleteContent = async () => {
    try {
      const { id, title, type } = itemToDelete;
      await deleteDoc(doc(db, "contents", id));

      const user = auth.currentUser;
      if (user) {
        await fetchTeacherName(user.uid);
      }

      const itemType =
        type === "assessment" || type === "interactive-assessment"
          ? "quiz"
          : "lesson/material";
      await addDoc(collection(db, "logs"), {
        teacherName: teacherName,
        activityDescription: `Deleted ${itemType}: ${title}`,
        createdAt: serverTimestamp(),
      });

      setContents(contents.filter((item) => item.id !== id));
      setShowDeleteModal(false);
      setItemToDelete(null);
      showNotification("Content deleted successfully!");
    } catch (error) {
      console.error("Error deleting content:", error.message);
      alert("Failed to delete content. Please try again.");
    }
  };

  return (
    <div className="container py-4">
      {/* Header Section */}
      <div className="page-header">
        <h1 className="page-title">Content Management</h1>
        <p className="page-subtitle">
          Create and manage lessons and quizzes for your students
        </p>
      </div>

      {/* Action Section */}
      <div className="action-section">
        <div className="section-header">
          <h2>Create Content</h2>
          <p>
            Create interactive lessons and quizzes manually for your students
          </p>
        </div>
        <div className="action-buttons">
          <button
            className="cl-btn cl-btn-create-lesson"
            onClick={() => {
              setShowRobustContentCreation(true);
              setContentToEdit(null);
              window.robustContentType = "lesson";
            }}
          >
            <span className="add-icon">📚</span> Create Lesson
          </button>

          <button
            className="cl-btn cl-btn-create-assessment"
            onClick={() => setShowAssessmentForm(true)}
            style={{
              backgroundColor: "#dc3545",
              borderColor: "#dc3545",
              marginLeft: "10px",
            }}
          >
            <span className="add-icon">📝</span> Create Quiz
          </button>
        </div>
      </div>

      {/* Filter Section */}
      <div className="filter-section">
        <div className="section-header">
          <h2>Filter Content</h2>
          <p>Find specific content by category, time, or type</p>
        </div>
        <div className="filter-container">
          <div className="filter-group">
            <span
              className={`assessment-filter ${showAssessments ? "active" : ""}`}
              onClick={() => {
                setShowAssessments(!showAssessments);
              }}
            >
              Quizzes
            </span>
          </div>
          <div className="filter-group">
            <select
              id="timeRange"
              className="filter-select"
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
            >
              <option value="1_day">Last 1 Day</option>
              <option value="7_days">Last 7 Days</option>
              <option value="30_days">Last 30 Days</option>
              <option value="all_time">All Time</option>
            </select>
          </div>
          <div className="filter-group">
            <input
              type="date"
              id="dateFilter"
              className="filter-select date-filter"
              value={dateFilter}
              onChange={(e) => setDateFilter(e.target.value)}
              title="Filter by Month and Day"
            />
          </div>
        </div>
      </div>

      {/* Assessment Form */}
      {showAssessmentForm && (
        <div className="modal-overlay">
          <div className="modal-content assessment-form">
            <button
              className="cl-btn close-modal"
              onClick={() => {
                if (hasAssessmentChanges()) {
                  setPendingFormAction(() => () => {
                    setShowAssessmentForm(false);
                    resetAssessmentForm();
                  });
                  setShowExitModal(true);
                } else {
                  setShowAssessmentForm(false);
                  resetAssessmentForm();
                }
              }}
            >
              ×
            </button>
            <form onSubmit={handleAddAssessment}>
              <div className="form-header">
                <input
                  type="text"
                  className="assessment-title-input"
                  id="assessmentTitleInput"
                  value={assessmentTitle}
                  onChange={(e) => setAssessmentTitle(e.target.value)}
                  placeholder="Title"
                />
                <input
                  type="text"
                  className="assessment-description-input"
                  id="assessmentDescriptionInput"
                  value={assessmentDescription}
                  onChange={(e) => setAssessmentDescription(e.target.value)}
                  placeholder="Description"
                />
                <div className="form-section">
                  <label
                    htmlFor="assessmentCategoryInput"
                    className="form-label"
                  >
                    Category
                  </label>
                  <select
                    id="assessmentCategoryInput"
                    className="form-select"
                    value={assessmentCategory}
                    onChange={(e) => setAssessmentCategory(e.target.value)}
                  >
                    {categories.map((category) => (
                      <option key={category} value={category}>
                        {displayCategory(category)}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {assessmentQuestions.map((question, index) => (
                <div key={index} className="question-card">
                  <div className="question-card-content">
                    <div className="question-card-main">
                      <input
                        type="text"
                        placeholder="Question"
                        value={question.questionText}
                        onChange={(e) => {
                          const updatedQuestions = [...assessmentQuestions];
                          updatedQuestions[index] = {
                            ...question,
                            questionText: e.target.value,
                          };
                          setAssessmentQuestions(updatedQuestions);
                        }}
                        className="question-text-input"
                      />

                      <div className="question-image-section">
                        <div className="image-upload-container">
                          {question.image ? (
                            <div className="image-preview-container">
                              <img
                                src={question.image}
                                alt="Question preview"
                                className="question-image-preview"
                              />
                              <button
                                type="button"
                                className="remove-image-btn"
                                onClick={() => {
                                  const updatedQuestions = [
                                    ...assessmentQuestions,
                                  ];
                                  updatedQuestions[index] = {
                                    ...question,
                                    image: null,
                                  };
                                  setAssessmentQuestions(updatedQuestions);
                                }}
                                title="Remove image"
                              >
                                <i className="fas fa-times"></i>
                              </button>
                            </div>
                          ) : (
                            <div className="image-upload-placeholder">
                              <label
                                htmlFor={`question-image-input-${index}`}
                                className="image-upload-btn"
                              >
                                <i className="fas fa-image"></i>
                                <span>Add Image (Optional)</span>
                              </label>
                              <input
                                type="file"
                                id={`question-image-input-${index}`}
                                accept="image/*"
                                onChange={(e) => {
                                  const file = e.target.files[0];
                                  if (file) {
                                    const allowedTypes = [
                                      "image/jpeg",
                                      "image/jpg",
                                      "image/png",
                                      "image/gif",
                                    ];
                                    if (!allowedTypes.includes(file.type)) {
                                      alert(
                                        "Please select a valid image file (JPEG, PNG, or GIF)"
                                      );
                                      return;
                                    }

                                    const maxSize = 5 * 1024 * 1024;
                                    if (file.size > maxSize) {
                                      alert("File size must be less than 5MB");
                                      return;
                                    }

                                    const reader = new FileReader();
                                    reader.onload = (e) => {
                                      const base64String = e.target.result;
                                      const updatedQuestions = [
                                        ...assessmentQuestions,
                                      ];
                                      updatedQuestions[index] = {
                                        ...question,
                                        image: base64String,
                                      };
                                      setAssessmentQuestions(updatedQuestions);
                                    };
                                    reader.onerror = () => {
                                      alert(
                                        "Error reading file. Please try again."
                                      );
                                    };
                                    reader.readAsDataURL(file);
                                  }
                                }}
                                style={{ display: "none" }}
                              />
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="options-list">
                        {question.options.map((option, optIndex) => (
                          <div key={optIndex} className="option-item">
                            <span className="option-indicator"></span>
                            <input
                              type="text"
                              placeholder="Add option"
                              value={option}
                              onChange={(e) => {
                                const newOptions = [...question.options];
                                newOptions[optIndex] = e.target.value;
                                setAssessmentQuestions((prev) => {
                                  const updated = [...prev];
                                  updated[index] = {
                                    ...question,
                                    options: newOptions,
                                  };
                                  return updated;
                                });
                              }}
                              className="option-input"
                            />
                            {optIndex > 0 && (
                              <button
                                type="button"
                                className="cl-btn option-remove-btn"
                                onClick={() => {
                                  const newOptions = [...question.options];
                                  newOptions.splice(optIndex, 1);
                                  setAssessmentQuestions((prev) => {
                                    const updated = [...prev];
                                    updated[index] = {
                                      ...question,
                                      options: newOptions,
                                    };
                                    return updated;
                                  });
                                }}
                              >
                                ×
                              </button>
                            )}
                          </div>
                        ))}
                        <button
                          type="button"
                          className="add-option-btn"
                          onClick={() => {
                            setAssessmentQuestions((prev) => {
                              const updated = [...prev];
                              updated[index] = {
                                ...question,
                                options: [...question.options, ""],
                              };
                              return updated;
                            });
                          }}
                        >
                          Add option
                        </button>
                      </div>

                      <div className="correct-answer-section">
                        <label className="form-label">Correct Answer</label>
                        <select
                          value={question.correctAnswer}
                          onChange={(e) => {
                            setAssessmentQuestions((prev) => {
                              const updated = [...prev];
                              updated[index] = {
                                ...question,
                                correctAnswer: e.target.value,
                              };
                              return updated;
                            });
                          }}
                          className="form-select"
                        >
                          <option value="">Select correct answer</option>
                          {question.options.map((option, optIndex) => (
                            <option
                              key={optIndex}
                              value={option}
                              disabled={!option}
                            >
                              {option || `Option ${optIndex + 1}`}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                    <div className="question-card-actions">
                      <button
                        type="button"
                        className="cl-btn edit-btn"
                        onClick={() => handleEditQuestion(index)}
                      >
                        Edit
                      </button>
                      <button
                        type="button"
                        className="cl-btn delete-btn"
                        onClick={() => handleDeleteQuestion(index)}
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))}

              <div className="question-card">
                <div className="question-card-content">
                  <div className="question-card-main">
                    <input
                      type="text"
                      placeholder="Question"
                      value={currentQuestion.questionText}
                      onChange={(e) =>
                        setCurrentQuestion({
                          ...currentQuestion,
                          questionText: e.target.value,
                        })
                      }
                      className="question-text-input"
                    />

                    <div className="question-image-section">
                      <div className="image-upload-container">
                        {currentQuestion.image ? (
                          <div className="image-preview-container">
                            <img
                              src={currentQuestion.image}
                              alt="Question preview"
                              className="question-image-preview"
                            />
                            <button
                              type="button"
                              className="remove-image-btn"
                              onClick={removeQuestionImage}
                              title="Remove image"
                            >
                              <i className="fas fa-times"></i>
                            </button>
                          </div>
                        ) : (
                          <div className="image-upload-placeholder">
                            <label
                              htmlFor="question-image-input"
                              className="image-upload-btn"
                            >
                              <i className="fas fa-image"></i>
                              <span>Add Image (Optional)</span>
                            </label>
                            <input
                              type="file"
                              id="question-image-input"
                              accept="image/*"
                              onChange={handleImageChange}
                              style={{ display: "none" }}
                            />
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="options-list">
                      {currentQuestion.options.map((option, index) => (
                        <div key={index} className="option-item">
                          <span className="option-indicator"></span>
                          <input
                            type="text"
                            placeholder="Add option"
                            value={option}
                            onChange={(e) => {
                              const newOptions = [...currentQuestion.options];
                              newOptions[index] = e.target.value;
                              setCurrentQuestion({
                                ...currentQuestion,
                                options: newOptions,
                              });
                            }}
                            className="option-input"
                          />
                          {index > 0 && (
                            <button
                              type="button"
                              className="cl-btn option-remove-btn"
                              onClick={() => {
                                const newOptions = [...currentQuestion.options];
                                newOptions.splice(index, 1);
                                setCurrentQuestion({
                                  ...currentQuestion,
                                  options: newOptions,
                                });
                              }}
                            >
                              ×
                            </button>
                          )}
                        </div>
                      ))}
                      <button
                        type="button"
                        className="add-option-btn"
                        onClick={() => {
                          setCurrentQuestion({
                            ...currentQuestion,
                            options: [...currentQuestion.options, ""],
                          });
                        }}
                      >
                        Add option
                      </button>
                    </div>

                    <div className="correct-answer-section">
                      <label className="form-label">Correct Answer</label>
                      <select
                        value={currentQuestion.correctAnswer}
                        onChange={(e) =>
                          setCurrentQuestion({
                            ...currentQuestion,
                            correctAnswer: e.target.value,
                          })
                        }
                        className="form-select"
                      >
                        <option value="">Select correct answer</option>
                        {currentQuestion.options.map((option, index) => (
                          <option key={index} value={option} disabled={!option}>
                            {option || `Option ${index + 1}`}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                  <div className="question-card-actions">
                    <button
                      type="button"
                      className="cl-btn submit-btn"
                      onClick={handleAddQuestion}
                    >
                      <span className="add-icon">+</span> Add Question
                    </button>
                  </div>
                </div>
              </div>

              <div className="modal-actions">
                <button type="submit" className="cl-btn submit-quiz-btn">
                  Add Quiz
                </button>
                <button
                  type="button"
                  className="cl-btn cancel-btn"
                  onClick={() => {
                    if (hasAssessmentChanges()) {
                      setPendingFormAction(() => () => {
                        setShowAssessmentForm(false);
                        resetAssessmentForm();
                      });
                      setShowExitModal(true);
                    } else {
                      setShowAssessmentForm(false);
                      resetAssessmentForm();
                    }
                  }}
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Content Display Section */}
      <div className="content-section">
        <div className="section-header">
          <h2>
            {showAssessments ? "Quizzes" : "Lessons"}
            <span className="content-count">({contents.length})</span>
          </h2>
          <p>Manage your lessons and quizzes for student evaluation</p>
        </div>

        {filterType === "built-in-modules" ? (
          <div className="built-in-modules-info">
            <div className="info-card">
              <h3>📚 Built-in Learning Modules</h3>
              <p>
                These are pre-built learning modules available to all students
              </p>
            </div>
          </div>
        ) : contents.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📚</div>
            <p>
              Create your first {showAssessments ? "quiz" : "lesson/material"}{" "}
              to get started
            </p>
          </div>
        ) : (
          <div className="content-grid">
            {contents.map((item) => (
              <div
                key={item.id}
                className={`cl-content-card category-${
                  item.category
                    ? item.category.toLowerCase().replace(/_/g, "-")
                    : "unknown"
                }`}
              >
                <div className="cl-content-body">
                  <h5 className="cl-content-title">{item.title}</h5>
                  {item.category && (
                    <p className="cl-content-info">
                      Category: {displayCategory(item.category)}
                    </p>
                  )}
                  {item.type && (
                    <div className="content-type-badge">
                      <span className={`type-badge ${item.type}`}>
                        {item.type === "interactive-lesson" &&
                          "🎓 Interactive Lesson"}
                        {item.type === "game-activity" && "🎮 Game Activity"}
                        {item.type === "interactive-assessment" &&
                          "📝 Interactive Quiz"}
                        {item.type === "uploaded-material" && "📄 Raw File"}
                        {item.type === "assessment" && "📋 Quiz"}
                        {item.type === "material" && "📚 Material"}
                        {item.type === "lesson" && "📚 Lesson"}
                        {item.type.startsWith("interactive-") &&
                          "🎓 Interactive Lesson"}
                      </span>
                    </div>
                  )}
                  {item.studentAppReady && (
                    <div className="student-ready-indicator">
                      <span className="ready-badge">✅ Mobile App Ready</span>
                    </div>
                  )}
                </div>
                <div className="cl-content-actions">
                  {(item.type === "lesson" ||
                    item.type === "interactive-lesson" ||
                    item.type === "material" ||
                    item.type === "uploaded-material" ||
                    item.type === "game-activity" ||
                    item.type === "game" ||
                    item.type === "activity" ||
                    item.type.startsWith("interactive-")) && (
                    <button
                      className="cl-btn cl-btn-edit"
                      onClick={() => {
                        setContentToEdit(item);
                        setShowRobustContentCreation(true);
                      }}
                      title="Edit this content in the lesson builder"
                      style={{ minWidth: "150px" }}
                    >
                      👁️✏️ Preview & Edit
                    </button>
                  )}
                  {(item.type === "assessment" ||
                    item.type === "interactive-assessment") && (
                    <button
                      className="cl-btn cl-btn-edit"
                      onClick={() => handlePreviewAndEditAssessment(item)}
                      title="Preview and edit this quiz"
                      style={{ minWidth: "150px" }}
                    >
                      👁️✏️ Preview & Edit
                    </button>
                  )}

                  <button
                    className="cl-btn cl-btn-delete"
                    onClick={() => {
                      setItemToDelete(item);
                      setShowDeleteModal(true);
                    }}
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {showDeleteModal && (
        <div className="confirmation-modal">
          <div className="modal-content">
            <h3 className="modal-title">Confirm Delete</h3>
            <p>
              Are you sure you want to delete "{itemToDelete.title}"? This
              action cannot be undone.
            </p>
            <div className="modal-actions">
              <button
                className="cl-btn modal-btn confirm-btn"
                onClick={handleDeleteContent}
              >
                Yes
              </button>
              <button
                className="cl-btn modal-btn"
                onClick={() => {
                  setShowDeleteModal(false);
                  setItemToDelete(null);
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {showExitModal && (
        <div className="confirmation-modal">
          <div className="modal-content">
            <h3 className="modal-title">Unsaved Changes</h3>
            <p>You haven't saved this. Are you sure you want to exit?</p>
            <div className="modal-actions">
              <button
                className="cl-btn modal-btn confirm-btn"
                onClick={confirmExit}
              >
                Yes
              </button>
              <button
                className="cl-btn modal-btn cancel-btn"
                onClick={cancelExit}
              >
                No
              </button>
            </div>
          </div>
        </div>
      )}

      {notification && <div className="notification">{notification}</div>}

      {showContentCreation && (
        <ContentCreation
          onClose={() => setShowContentCreation(false)}
          onSuccess={(message) => {
            setNotification(message);
            setTimeout(() => setNotification(null), 5000);
            refreshContent();
          }}
        />
      )}

      {showRobustContentCreation && (
        <RobustContentCreation
          editContent={contentToEdit}
          onClose={() => {
            setShowRobustContentCreation(false);
            setContentToEdit(null);
          }}
          onSuccess={(message, newLesson) => {
            console.log("onSuccess called with:", { message, newLesson });

            setNotification(message);
            setTimeout(() => setNotification(null), 5000);

            if (newLesson && !contentToEdit) {
              console.log("Adding new lesson to state:", newLesson);
              setContents((prevContents) => {
                const exists = prevContents.some(
                  (item) => item.id === newLesson.id
                );
                if (exists) {
                  console.log("Lesson already exists in state");
                  return prevContents;
                }
                console.log("Adding new lesson to beginning of list");
                return [newLesson, ...prevContents];
              });
            }

            console.log("Triggering full content refresh");
            refreshContent();

            setContentToEdit(null);
          }}
        />
      )}

      {/* PREVIEW & EDIT MODAL FOR QUIZZES */}
      {showPreviewModal && previewContent && (
        <div className="modal-overlay">
          <div
            className="modal-content assessment-preview-modal"
            style={{ maxWidth: "900px", maxHeight: "90vh", overflow: "auto" }}
          >
            <div
              className="modal-header"
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                padding: "20px",
                borderBottom: "1px solid #e0e0e0",
              }}
            >
              <h2 style={{ margin: 0, fontSize: "24px", fontWeight: "600" }}>
                Edit Quiz
              </h2>
              <button
                className="close-btn"
                onClick={() => {
                  setShowPreviewModal(false);
                  setPreviewContent(null);
                  setIsEditMode(false);
                  setEditableQuestions([]);
                }}
                style={{
                  background: "none",
                  border: "none",
                  fontSize: "28px",
                  cursor: "pointer",
                  color: "#666",
                  padding: "0",
                  width: "30px",
                  height: "30px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                ×
              </button>
            </div>

            <div style={{ padding: "20px" }}>
              {isEditMode ? (
                <div className="edit-mode">
                  <div
                    className="edit-mode-header"
                    style={{ marginBottom: "20px" }}
                  ></div>

                  {editableQuestions.map((question, index) => (
                    <div
                      key={index}
                      className="question-card"
                      style={{
                        marginBottom: "20px",
                        padding: "20px",
                        border: "1px solid #ddd",
                        borderRadius: "8px",
                      }}
                    >
                      <div className="question-card-content">
                        <div className="question-card-main">
                          <label
                            className="form-label"
                            style={{
                              fontWeight: "bold",
                              marginBottom: "10px",
                              display: "block",
                            }}
                          >
                            Question {index + 1}
                          </label>
                          <input
                            type="text"
                            placeholder="Question"
                            value={question.questionText || ""}
                            onChange={(e) => {
                              const updatedQuestions = [...editableQuestions];
                              updatedQuestions[index] = {
                                ...question,
                                questionText: e.target.value,
                              };
                              setEditableQuestions(updatedQuestions);
                            }}
                            className="question-text-input"
                            style={{
                              width: "100%",
                              padding: "10px",
                              marginBottom: "15px",
                              fontSize: "16px",
                            }}
                          />

                          {/* Image section */}
                          <div
                            className="question-image-section"
                            style={{ marginBottom: "15px" }}
                          >
                            <div className="image-upload-container">
                              {question.image ? (
                                <div
                                  className="image-preview-container"
                                  style={{
                                    position: "relative",
                                    display: "inline-block",
                                  }}
                                >
                                  <img
                                    src={question.image}
                                    alt="Question preview"
                                    className="question-image-preview"
                                    style={{
                                      maxWidth: "200px",
                                      maxHeight: "150px",
                                      borderRadius: "8px",
                                    }}
                                  />
                                  <button
                                    type="button"
                                    className="remove-image-btn"
                                    onClick={() => {
                                      const updatedQuestions = [
                                        ...editableQuestions,
                                      ];
                                      updatedQuestions[index] = {
                                        ...question,
                                        image: null,
                                      };
                                      setEditableQuestions(updatedQuestions);
                                    }}
                                    title="Remove image"
                                    style={{
                                      position: "absolute",
                                      top: "5px",
                                      right: "5px",
                                      background: "red",
                                      color: "white",
                                      border: "none",
                                      borderRadius: "50%",
                                      width: "25px",
                                      height: "25px",
                                      cursor: "pointer",
                                    }}
                                  >
                                    ×
                                  </button>
                                </div>
                              ) : (
                                <div className="image-upload-placeholder">
                                  <label
                                    htmlFor={`edit-question-image-${index}`}
                                    className="image-upload-btn"
                                    style={{
                                      display: "inline-block",
                                      padding: "10px 15px",
                                      backgroundColor: "#007bff",
                                      color: "white",
                                      borderRadius: "5px",
                                      cursor: "pointer",
                                    }}
                                  >
                                    📷 Add Image (Optional)
                                  </label>
                                  <input
                                    type="file"
                                    id={`edit-question-image-${index}`}
                                    accept="image/*"
                                    onChange={(e) => {
                                      const file = e.target.files[0];
                                      if (file) {
                                        const allowedTypes = [
                                          "image/jpeg",
                                          "image/jpg",
                                          "image/png",
                                          "image/gif",
                                        ];
                                        if (!allowedTypes.includes(file.type)) {
                                          alert(
                                            "Please select a valid image file (JPEG, PNG, or GIF)"
                                          );
                                          return;
                                        }

                                        const maxSize = 5 * 1024 * 1024;
                                        if (file.size > maxSize) {
                                          alert(
                                            "File size must be less than 5MB"
                                          );
                                          return;
                                        }

                                        const reader = new FileReader();
                                        reader.onload = (e) => {
                                          const base64String = e.target.result;
                                          const updatedQuestions = [
                                            ...editableQuestions,
                                          ];
                                          updatedQuestions[index] = {
                                            ...question,
                                            image: base64String,
                                          };
                                          setEditableQuestions(
                                            updatedQuestions
                                          );
                                        };
                                        reader.onerror = () => {
                                          alert(
                                            "Error reading file. Please try again."
                                          );
                                        };
                                        reader.readAsDataURL(file);
                                      }
                                    }}
                                    style={{ display: "none" }}
                                  />
                                </div>
                              )}
                            </div>
                          </div>

                          <div
                            className="options-list"
                            style={{ marginBottom: "15px" }}
                          >
                            <label
                              style={{
                                fontWeight: "bold",
                                marginBottom: "8px",
                                display: "block",
                              }}
                            >
                              Options:
                            </label>
                            {question.options?.map((option, optIndex) => (
                              <div
                                key={optIndex}
                                className="option-item"
                                style={{
                                  display: "flex",
                                  alignItems: "center",
                                  marginBottom: "8px",
                                }}
                              >
                                <span
                                  className="option-indicator"
                                  style={{
                                    marginRight: "10px",
                                    fontWeight: "bold",
                                    minWidth: "30px",
                                  }}
                                >
                                  {String.fromCharCode(65 + optIndex)}.
                                </span>
                                <input
                                  type="text"
                                  placeholder={`Option ${optIndex + 1}`}
                                  value={option || ""}
                                  onChange={(e) => {
                                    const updatedQuestions = [
                                      ...editableQuestions,
                                    ];
                                    const newOptions = [...question.options];
                                    newOptions[optIndex] = e.target.value;
                                    updatedQuestions[index] = {
                                      ...question,
                                      options: newOptions,
                                    };
                                    setEditableQuestions(updatedQuestions);
                                  }}
                                  className="option-input"
                                  style={{
                                    flex: 1,
                                    padding: "8px",
                                    fontSize: "14px",
                                  }}
                                />
                              </div>
                            ))}
                          </div>

                          <div className="correct-answer-section">
                            <label
                              className="form-label"
                              style={{
                                fontWeight: "bold",
                                marginBottom: "8px",
                                display: "block",
                              }}
                            >
                              Correct Answer:
                            </label>
                            <select
                              value={question.correctAnswer || ""}
                              onChange={(e) => {
                                const updatedQuestions = [...editableQuestions];
                                updatedQuestions[index] = {
                                  ...question,
                                  correctAnswer: e.target.value,
                                };
                                setEditableQuestions(updatedQuestions);
                              }}
                              className="form-select"
                              style={{ width: "100%", padding: "8px" }}
                            >
                              <option value="">Select correct answer</option>
                              {question.options?.map((option, optIndex) => (
                                <option
                                  key={optIndex}
                                  value={option}
                                  disabled={!option}
                                >
                                  {String.fromCharCode(65 + optIndex)}.{" "}
                                  {option || `Option ${optIndex + 1}`}
                                </option>
                              ))}
                            </select>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}

                  <button
                    type="button"
                    className="add-item-btn"
                    onClick={() => {
                      const newQuestion = {
                        questionText: "",
                        options: ["", "", "", ""],
                        correctAnswer: "",
                        image: null,
                      };
                      setEditableQuestions([...editableQuestions, newQuestion]);
                    }}
                    style={{
                      width: "100%",
                      padding: "15px",
                      marginTop: "20px",
                      marginBottom: "20px",
                      backgroundColor: "#28a745",
                      color: "white",
                      border: "none",
                      borderRadius: "8px",
                      fontSize: "16px",
                      fontWeight: "bold",
                      cursor: "pointer",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: "10px",
                    }}
                  >
                    ➕ Add Item
                  </button>

                  <div
                    className="modal-actions"
                    style={{
                      marginTop: "20px",
                      display: "flex",
                      gap: "10px",
                      justifyContent: "flex-end",
                    }}
                  >
                    <button
                      className="cl-btn cancel-btn"
                      onClick={() => {
                        setIsEditMode(false);
                        setShowPreviewModal(false);
                        setPreviewContent(null);
                        setEditableQuestions([]);
                      }}
                    >
                      Cancel
                    </button>
                    <button
                      className="cl-btn submit-btn"
                      onClick={handleSaveEditableAssessment}
                    >
                      💾 Save All Changes
                    </button>
                  </div>
                </div>
              ) : (
                <div className="preview-mode">
                  <h3>Questions Preview</h3>
                  {(
                    previewContent.questions ||
                    previewContent.assessmentData?.questions ||
                    []
                  ).map((question, index) => (
                    <div
                      key={index}
                      className="question-preview-card"
                      style={{
                        marginBottom: "20px",
                        padding: "15px",
                        border: "1px solid #ddd",
                        borderRadius: "8px",
                        backgroundColor: "#f9f9f9",
                      }}
                    >
                      <h4>
                        Question {index + 1}:{" "}
                        {question.questionText || question.question}
                      </h4>
                      {question.image && (
                        <img
                          src={question.image}
                          alt="Question"
                          style={{
                            maxWidth: "200px",
                            margin: "10px 0",
                            borderRadius: "8px",
                          }}
                        />
                      )}
                      <ul style={{ listStyle: "none", padding: 0 }}>
                        {question.options?.map((option, optIndex) => (
                          <li
                            key={optIndex}
                            style={{
                              padding: "8px",
                              marginBottom: "5px",
                              backgroundColor:
                                option === question.correctAnswer
                                  ? "#d4edda"
                                  : "white",
                              border: "1px solid #ddd",
                              borderRadius: "4px",
                              color:
                                option === question.correctAnswer
                                  ? "#155724"
                                  : "black",
                              fontWeight:
                                option === question.correctAnswer
                                  ? "bold"
                                  : "normal",
                            }}
                          >
                            {String.fromCharCode(65 + optIndex)}. {option}{" "}
                            {option === question.correctAnswer && " ✔"}
                          </li>
                        ))}
                      </ul>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Contents;
