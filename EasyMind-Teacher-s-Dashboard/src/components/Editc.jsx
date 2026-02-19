"use client";

import { useState, useEffect } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { db } from "../firebase";
import { doc, updateDoc, getDoc } from "firebase/firestore";
import "../styles/Contents.css";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import "bootstrap/dist/css/bootstrap.min.css";

const categories = [
  "COMMUNICATION_SKILLS",
  "NUMBER_SKILLS",
  "SELF_HELP",
  "PRE-VOCATIONAL_SKILLS",
  "SOCIAL_SKILLS",
  "FUNCTIONAL_ACADEMICS",
];

const EditContent = () => {
  const { id } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const content = location.state?.content;
  const { showQuizzes, materialFilter, sortOrder } = location.state || {
    showQuizzes: false,
    materialFilter: "all materials",
    sortOrder: "newest",
  };

  const [materialTitle, setMaterialTitle] = useState(
    content?.type?.includes("material") ? content.title : ""
  );
  const [materialCategory, setMaterialCategory] = useState(
    content?.category || categories[0]
  );
  const [quizTitle, setQuizTitle] = useState(
    content?.type === "quiz" ? content.title : ""
  );
  const [quizDescription, setQuizDescription] = useState(
    content?.description || ""
  );
  const [quizQuestions, setQuizQuestions] = useState(() => {
    if (content?.type === "quiz") {
      const questions =
        content.questions ||
        content.quizData?.questions ||
        content.questionsData?.questions ||
        [];
      console.log("Initializing with questions:", questions.length);
      return questions;
    }
    return [];
  });
  const [currentQuestion, setCurrentQuestion] = useState({
    questionText: "",
    options: ["", "", "", ""],
    correctAnswer: "",
    image: null,
  });
  // eslint-disable-next-line no-unused-vars
  const [, setEditingQuestionIndex] = useState(null);
  const [notification, setNotification] = useState(null);
  const [errorMessage, setErrorMessage] = useState(null);

  useEffect(() => {
    if (!content) {
      console.error("No content data found for editing. ID:", id);
      navigate("/contents", {
        state: { showQuizzes, materialFilter, sortOrder },
      });
    } else {
      console.log("Content data:", content);
      console.log("Quiz questions:", content.questions);
      console.log("Total questions count:", content.questions?.length || 0);
      console.log("Quiz data questions:", content.quizData?.questions);
      console.log(
        "Quiz data questions count:",
        content.quizData?.questions?.length || 0
      );

      if (content?.type === "quiz") {
        const questions =
          content.questions ||
          content.quizData?.questions ||
          content.questionsData?.questions ||
          [];
        console.log("Updating questions from content:", questions.length);
        console.log("First few questions:", questions.slice(0, 5));
        console.log("Last few questions:", questions.slice(-5));
        console.log(
          "All question indices:",
          questions.map((q, i) => i)
        );
        console.log("Content structure:", {
          hasQuestions: !!content.questions,
          questionsLength: content.questions?.length || 0,
          hasQuizData: !!content.quizData,
          quizDataQuestionsLength: content.quizData?.questions?.length || 0,
          parentLessonId: content.parentLessonId,
        });

        if (content.parentLessonId) {
          console.log("Checking parent lesson data...");
          checkParentLessonData(content.parentLessonId);
        }

        setQuizQuestions(questions);
      }
    }
  }, [content, id, navigate, showQuizzes, materialFilter, sortOrder]);

  const showNotification = (message) => {
    setNotification(message);
    setTimeout(() => setNotification(null), 2000);
  };

  const showError = (message) => {
    setErrorMessage(message);
    setTimeout(() => setErrorMessage(null), 3000);
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

  const checkParentLessonData = async (parentLessonId) => {
    if (!parentLessonId) return;

    try {
      const lessonDoc = await getDoc(doc(db, "contents", parentLessonId));
      if (lessonDoc.exists()) {
        const lessonData = lessonDoc.data();
        console.log("Parent lesson data:", lessonData);
        console.log(
          "Parent lesson items count:",
          lessonData.lessonData?.items?.length || 0
        );
        console.log("Parent lesson items:", lessonData.lessonData?.items);
        return lessonData;
      }
    } catch (error) {
      console.error("Error fetching parent lesson:", error);
    }
    return null;
  };

  const handleDeleteQuestion = (index) => {
    const updatedQuestions = quizQuestions.filter((_, i) => i !== index);
    setQuizQuestions(updatedQuestions);
  };

  const handleUpdateMaterial = async (e) => {
    e.preventDefault();
    if (!materialTitle) {
      showError("Please enter a material title.");
      return;
    }

    try {
      const materialRef = doc(db, "contents", id);
      await updateDoc(materialRef, {
        title: materialTitle,
        category: materialCategory,
      });
      showNotification("Material updated successfully!");
    } catch (error) {
      console.error("Error updating material:", error.message);
      showError("Failed to update material. Please try again.");
    }
  };

  const handleUpdateQuiz = async (e) => {
    e.preventDefault();

    const finalQuestions = [...quizQuestions];
    let newQuestionAddedThisUpdate = false;

    const currentQuestionText =
      currentQuestion.questionText || currentQuestion.question || "";
    if (currentQuestionText.trim() !== "") {
      let isNewQuestionValid = true;
      if (!currentQuestionText) {
        showError("The new question text cannot be empty.");
        isNewQuestionValid = false;
      }

      if (isNewQuestionValid) {
        if (
          currentQuestion.options.some((opt) => !opt.trim()) ||
          !currentQuestion.correctAnswer.trim()
        ) {
          showError(
            "The new question is incomplete (options/answer). It will not be added."
          );
          isNewQuestionValid = false;
        } else if (
          !currentQuestion.options.includes(currentQuestion.correctAnswer)
        ) {
          showError(
            "The new question's correct answer must match one of its options. It will not be added."
          );
          isNewQuestionValid = false;
        }
      }

      if (isNewQuestionValid) {
        finalQuestions.push({ ...currentQuestion });
        newQuestionAddedThisUpdate = true;
      }
    }

    if (!quizTitle.trim()) {
      showError("Please enter a quiz title.");
      return;
    }
    if (finalQuestions.length === 0) {
      showError("The quiz must have at least one question.");
      return;
    }

    for (const question of finalQuestions) {
      const questionText = question.questionText || question.question || "";
      if (!questionText.trim()) {
        showError("One or more questions have empty text.");
        return;
      }
      if (
        question.options.some((opt) => !opt.trim()) ||
        !question.correctAnswer.trim()
      ) {
        showError("One or more questions are incomplete (options/answer).");
        return;
      }
      if (!question.options.includes(question.correctAnswer)) {
        showError(
          "One or more questions have a correct answer that does not match any option."
        );
        return;
      }
    }

    try {
      const quizRef = doc(db, "contents", id);
      await updateDoc(quizRef, {
        title: quizTitle,
        description: quizDescription,
        questions: finalQuestions,
      });

      if (newQuestionAddedThisUpdate) {
        setCurrentQuestion({
          questionText: "",
          options: ["", "", "", ""],
          correctAnswer: "",
          image: null,
        });
      }
      showNotification("Quiz updated successfully!");
    } catch (error) {
      console.error("Error updating quiz:", error.message);
      showError("Failed to update quiz. Please try again.");
    }
  };

  const displayCategory = (category) => {
    if (!category) return "uncategorized";
    return category.toLowerCase().replace(/_/g, " ");
  };

  return (
    <div className="container py-4">
      {content?.type.includes("material") && (
        <div className="modal-overlay">
          <div className="modal-content material-form">
            <button
              className="cl-btn close-modal"
              onClick={() =>
                navigate("/contents", {
                  state: { showQuizzes, materialFilter, sortOrder },
                })
              }
            >
              ×
            </button>
            <h1 className="form-heading">Edit Learning Material</h1>
            <form onSubmit={handleUpdateMaterial}>
              <div className="form-section">
                <label htmlFor="materialTitleInput" className="form-label">
                  Material Title
                </label>
                <input
                  type="text"
                  className="topic-input"
                  id="materialTitleInput"
                  value={materialTitle}
                  onChange={(e) => setMaterialTitle(e.target.value)}
                  placeholder="e.g., Introduction to Numbers"
                />
              </div>
              <div className="form-section">
                <label htmlFor="materialCategoryInput" className="form-label">
                  Category
                </label>
                <select
                  id="materialCategoryInput"
                  className="form-select"
                  value={materialCategory}
                  onChange={(e) => setMaterialCategory(e.target.value)}
                >
                  {categories.map((category) => (
                    <option key={category} value={category}>
                      {displayCategory(category)}
                    </option>
                  ))}
                </select>
              </div>
              <div className="modal-actions">
                <button type="submit" className="cl-btn submit-btn">
                  Update Material
                </button>
                <button
                  type="button"
                  className="cl-btn cancel-btn"
                  onClick={() =>
                    navigate("/contents", {
                      state: { showQuizzes, materialFilter, sortOrder },
                    })
                  }
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {content?.type === "quiz" && (
        <div className="modal-overlay">
          <div className="modal-content quiz-form">
            <button
              className="cl-btn close-modal"
              onClick={() =>
                navigate("/contents", {
                  state: { showQuizzes: true, materialFilter, sortOrder },
                })
              }
            >
              ×
            </button>
            <form onSubmit={handleUpdateQuiz}>
              <div className="form-header">
                <input
                  type="text"
                  id="quizTitleInput"
                  className="quiz-title-input"
                  value={quizTitle}
                  onChange={(e) => setQuizTitle(e.target.value)}
                  placeholder="Untitled Quiz"
                />
                <input
                  type="text"
                  id="quizDescriptionInput"
                  className="quiz-description-input"
                  value={quizDescription}
                  onChange={(e) => setQuizDescription(e.target.value)}
                  placeholder="Quiz description"
                />
                <select
                  className="form-select"
                  value={content.category || categories[0]}
                  disabled
                  style={{ marginTop: "10px", backgroundColor: "#f8f9fa" }}
                >
                  <option value={content.category || categories[0]}>
                    {displayCategory(content.category || categories[0])}
                  </option>
                </select>
              </div>

              {quizQuestions.length > 0 && (
                <div style={{ marginTop: "20px" }}>
                  <h4
                    className="form-label"
                    style={{ fontSize: "1.2rem", marginBottom: "15px" }}
                  >
                    📝 Quiz Questions (Edit Mode) - {quizQuestions.length}{" "}
                    questions
                  </h4>
                  <div className="preview-questions">
                    {console.log(`Rendering ${quizQuestions.length} questions`)}
                    {console.log(`Questions array:`, quizQuestions)}
                    <div
                      style={{
                        background: "#e3f2fd",
                        padding: "10px",
                        marginBottom: "20px",
                        borderRadius: "5px",
                      }}
                    >
                      <strong>Debug Info:</strong> Found {quizQuestions.length}{" "}
                      questions total. Showing questions 1 to{" "}
                      {quizQuestions.length}.
                    </div>
                    {quizQuestions.map((question, index) => {
                      console.log(`Question ${index + 1}:`, question);

                      return (
                        <div
                          key={index}
                          className="preview-question edit-mode-question"
                        >
                          <div className="question-header">
                            <span className="question-number">
                              Q{index + 1}
                            </span>
                            <span className="question-type">
                              Multiple Choice
                            </span>
                          </div>

                          <div className="edit-question-content">
                            <input
                              type="text"
                              placeholder="Question text..."
                              value={
                                question.questionText || question.question || ""
                              }
                              onChange={(e) => {
                                const updatedQuestions = [...quizQuestions];
                                updatedQuestions[index] = {
                                  ...question,
                                  questionText: e.target.value,
                                };
                                setQuizQuestions(updatedQuestions);
                              }}
                              className="edit-question-text"
                            />

                            {/* Image Upload Section for Existing Questions */}
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
                                          ...quizQuestions,
                                        ];
                                        updatedQuestions[index] = {
                                          ...question,
                                          image: null,
                                        };
                                        setQuizQuestions(updatedQuestions);
                                      }}
                                      title="Remove image"
                                    >
                                      <i className="fas fa-times"></i>
                                    </button>
                                  </div>
                                ) : (
                                  <div className="image-upload-placeholder">
                                    <label
                                      htmlFor={`edit-question-image-input-${index}`}
                                      className="image-upload-btn"
                                    >
                                      <i className="fas fa-image"></i>
                                      <span>Add Image (Optional)</span>
                                    </label>
                                    <input
                                      type="file"
                                      id={`edit-question-image-input-${index}`}
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
                                          if (
                                            !allowedTypes.includes(file.type)
                                          ) {
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
                                            const base64String =
                                              e.target.result;
                                            const updatedQuestions = [
                                              ...quizQuestions,
                                            ];
                                            updatedQuestions[index] = {
                                              ...question,
                                              image: base64String,
                                            };
                                            setQuizQuestions(updatedQuestions);
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

                            <div className="question-options edit-mode-options">
                              {console.log(
                                `Question ${index + 1} options:`,
                                question.options
                              )}

                              {question.options &&
                                question.options.length > 0 && (
                                  <div className="preview-options-display">
                                    <h5
                                      style={{
                                        marginBottom: "10px",
                                        color: "#495057",
                                      }}
                                    >
                                      Options:
                                    </h5>
                                    <div className="question-options">
                                      {question.options.map(
                                        (option, optIndex) => (
                                          <div
                                            key={optIndex}
                                            className="option"
                                          >
                                            <span className="option-letter">
                                              {String.fromCharCode(
                                                65 + optIndex
                                              )}
                                              .
                                            </span>
                                            {option}
                                          </div>
                                        )
                                      )}
                                    </div>
                                  </div>
                                )}

                              {(!question.options ||
                                question.options.length === 0) && (
                                <div className="no-options-message">
                                  <p>
                                    ⚠️ No options found. Adding default
                                    options...
                                  </p>
                                </div>
                              )}
                              {(question.options && question.options.length > 0
                                ? question.options
                                : ["", "", "", ""]
                              ).map((option, optIndex) => (
                                <div
                                  key={optIndex}
                                  className="option edit-mode-option"
                                >
                                  <span className="option-letter">
                                    {String.fromCharCode(65 + optIndex)}.
                                  </span>
                                  <input
                                    type="text"
                                    placeholder={`Option ${optIndex + 1}`}
                                    value={option}
                                    onChange={(e) => {
                                      const currentOptions =
                                        question.options || ["", "", "", ""];
                                      const newOptions = [...currentOptions];
                                      newOptions[optIndex] = e.target.value;
                                      const newCorrectAnswer =
                                        newOptions.includes(
                                          question.correctAnswer
                                        )
                                          ? question.correctAnswer
                                          : "";
                                      const updatedQuestions = [
                                        ...quizQuestions,
                                      ];
                                      updatedQuestions[index] = {
                                        ...question,
                                        options: newOptions,
                                        correctAnswer: newCorrectAnswer,
                                      };
                                      setQuizQuestions(updatedQuestions);
                                    }}
                                    className="edit-option-input"
                                  />
                                  {(question.options || []).length > 1 && (
                                    <button
                                      type="button"
                                      className="remove-option-btn"
                                      onClick={() => {
                                        const currentOptions =
                                          question.options || ["", "", "", ""];
                                        const newOptions =
                                          currentOptions.filter(
                                            (_, i) => i !== optIndex
                                          );
                                        const newCorrectAnswer =
                                          newOptions.includes(
                                            question.correctAnswer
                                          )
                                            ? question.correctAnswer
                                            : "";
                                        const updatedQuestions = [
                                          ...quizQuestions,
                                        ];
                                        updatedQuestions[index] = {
                                          ...question,
                                          options: newOptions,
                                          correctAnswer: newCorrectAnswer,
                                        };
                                        setQuizQuestions(updatedQuestions);
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
                                  const currentOptions = question.options || [
                                    "",
                                    "",
                                    "",
                                    "",
                                  ];
                                  const updatedQuestions = [...quizQuestions];
                                  updatedQuestions[index] = {
                                    ...question,
                                    options: [...currentOptions, ""],
                                  };
                                  setQuizQuestions(updatedQuestions);
                                }}
                              >
                                + Add option
                              </button>
                            </div>

                            <div className="correct-answer-selector">
                              <label className="answer-label">
                                Correct Answer:
                              </label>
                              <select
                                value={question.correctAnswer}
                                onChange={(e) => {
                                  const updatedQuestions = [...quizQuestions];
                                  updatedQuestions[index] = {
                                    ...question,
                                    correctAnswer: e.target.value,
                                  };
                                  setQuizQuestions(updatedQuestions);
                                }}
                                className="edit-correct-answer-select"
                              >
                                <option value="">Select correct answer</option>
                                {(question.options &&
                                question.options.length > 0
                                  ? question.options
                                  : ["", "", "", ""]
                                ).map(
                                  (option, optIndex) =>
                                    option.trim() && (
                                      <option key={optIndex} value={option}>
                                        {String.fromCharCode(65 + optIndex)}.{" "}
                                        {option}
                                      </option>
                                    )
                                )}
                              </select>
                              {question.correctAnswer &&
                                !(
                                  question.options &&
                                  question.options.length > 0
                                    ? question.options
                                    : ["", "", "", ""]
                                ).includes(question.correctAnswer) && (
                                  <p className="answer-warning">
                                    ⚠️ The selected correct answer does not
                                    match any option.
                                  </p>
                                )}
                            </div>
                          </div>

                          <div className="question-controls">
                            <button
                              type="button"
                              className="delete-question-btn"
                              onClick={() => handleDeleteQuestion(index)}
                            >
                              🗑️ Delete Question
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              <div
                className="preview-question add-new-question"
                style={{ marginTop: "20px" }}
              >
                <div className="question-header">
                  <span className="question-number">NEW</span>
                  <span className="question-type">Multiple Choice</span>
                </div>
                <h4
                  className="form-label"
                  style={{ marginBottom: "15px", fontSize: "1.1rem" }}
                >
                  ➕ Add New Question
                </h4>
                <div className="edit-question-content">
                  <input
                    type="text"
                    placeholder="New question text..."
                    value={currentQuestion.questionText}
                    onChange={(e) =>
                      setCurrentQuestion({
                        ...currentQuestion,
                        questionText: e.target.value,
                      })
                    }
                    className="edit-question-text"
                  />

                  {/* Image Upload Section for New Question */}
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
                            htmlFor="new-question-image-input"
                            className="image-upload-btn"
                          >
                            <i className="fas fa-image"></i>
                            <span>Add Image (Optional)</span>
                          </label>
                          <input
                            type="file"
                            id="new-question-image-input"
                            accept="image/*"
                            onChange={handleImageChange}
                            style={{ display: "none" }}
                          />
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="question-options edit-mode-options">
                    {currentQuestion.options.map((option, index) => (
                      <div key={index} className="option edit-mode-option">
                        <span className="option-letter">
                          {String.fromCharCode(65 + index)}
                        </span>
                        <input
                          type="text"
                          placeholder={`Option ${index + 1}`}
                          value={option}
                          onChange={(e) => {
                            const newOptions = [...currentQuestion.options];
                            newOptions[index] = e.target.value;
                            const newCorrectAnswer = newOptions.includes(
                              currentQuestion.correctAnswer
                            )
                              ? currentQuestion.correctAnswer
                              : "";
                            setCurrentQuestion({
                              ...currentQuestion,
                              options: newOptions,
                              correctAnswer: newCorrectAnswer,
                            });
                          }}
                          className="edit-option-input"
                        />
                        {currentQuestion.options.length > 1 && (
                          <button
                            type="button"
                            className="remove-option-btn"
                            onClick={() => {
                              const newOptions = currentQuestion.options.filter(
                                (_, i) => i !== index
                              );
                              const newCorrectAnswer = newOptions.includes(
                                currentQuestion.correctAnswer
                              )
                                ? currentQuestion.correctAnswer
                                : "";
                              setCurrentQuestion({
                                ...currentQuestion,
                                options: newOptions,
                                correctAnswer: newCorrectAnswer,
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
                      + Add option
                    </button>
                  </div>

                  <div className="correct-answer-selector">
                    <label className="answer-label">Correct Answer:</label>
                    <select
                      value={currentQuestion.correctAnswer}
                      onChange={(e) =>
                        setCurrentQuestion({
                          ...currentQuestion,
                          correctAnswer: e.target.value,
                        })
                      }
                      className="edit-correct-answer-select"
                    >
                      <option value="">Select correct answer</option>
                      {currentQuestion.options.map(
                        (option, index) =>
                          option.trim() && (
                            <option key={index} value={option}>
                              {String.fromCharCode(65 + index)}. {option}
                            </option>
                          )
                      )}
                    </select>
                    {currentQuestion.correctAnswer &&
                      !currentQuestion.options.includes(
                        currentQuestion.correctAnswer
                      ) && (
                        <p className="answer-warning">
                          ⚠️ The selected correct answer does not match any
                          option.
                        </p>
                      )}
                  </div>
                </div>
              </div>

              <div className="modal-actions">
                <button
                  type="submit"
                  className="cl-btn cl-btn-primary-form-action"
                >
                  Update Quiz
                </button>
                <button
                  type="button"
                  className="cl-btn cl-btn-secondary-form-action"
                  onClick={() =>
                    navigate("/contents", {
                      state: { showQuizzes: true, materialFilter, sortOrder },
                    })
                  }
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {notification && <div className="notification">{notification}</div>}

      {errorMessage && (
        <div className="confirmation-modal">
          <div className="modal-content">
            <h3>Error</h3>
            <p>{errorMessage}</p>
            <div className="modal-actions">
              <button
                className="cl-btn modal-btn confirm-btn"
                onClick={() => setErrorMessage(null)}
              >
                OK
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EditContent;
