// Teacher Content Creation System - Simplified Interface for Image Lessons
import React, { useState } from "react";
import { db } from "../firebase";
import { collection, addDoc, serverTimestamp } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import "../styles/ContentCreation.css"; // Ensure you have necessary styles in this file

// Helper component for creating a single Image + Description item
const LessonItemCreator = ({ item, index, updateItem, removeItem }) => {
  // Use a local URL for file preview. In a real app, this file would be uploaded
  // to Firebase Storage (or similar) to get a persistent URL before final save.
  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      const imageUrl = URL.createObjectURL(file);
      // Store both the file object (for later storage upload) and the preview URL
      updateItem(index, {
        ...item,
        imageFile: file,
        imageUrl,
        type: "image_item",
      });
    }
  };

  const handleDescriptionChange = (e) => {
    updateItem(index, { ...item, description: e.target.value });
  };

  return (
    <div className="card mb-3 p-3">
      <div className="d-flex justify-content-between align-items-center mb-2">
        <h5>Item {index + 1}</h5>
        <button
          className="btn btn-danger btn-sm"
          onClick={() => removeItem(index)}
        >
          <i className="fas fa-trash-alt me-1"></i> Remove
        </button>
      </div>
      <div className="mb-3">
        <label className="form-label">Image Upload (Required)</label>
        <input
          type="file"
          className="form-control"
          accept="image/*"
          onChange={handleFileChange}
        />
        {item.imageUrl && (
          // Display image preview
          <div className="mt-2 text-center">
            <img
              src={item.imageUrl}
              alt={`Lesson Item ${index}`}
              style={{
                width: "100px",
                height: "100px",
                objectFit: "cover",
                borderRadius: "8px",
              }}
              className="img-thumbnail"
            />
          </div>
        )}
      </div>
      <div className="mb-3">
        <label className="form-label">
          Description (Text-to-Speech & Display Text)*
        </label>
        <textarea
          className="form-control"
          rows="3"
          value={item.description}
          onChange={handleDescriptionChange}
          placeholder="Enter the description that the student app will read aloud (e.g., 'This is a red apple.')."
          required
        />
      </div>
    </div>
  );
};

// Main ContentCreation Component
const ContentCreation = ({ onClose, onSuccess }) => {
  const auth = getAuth();
  // New state: 'imageLesson' for the visual builder, 'documentUpload' for the generator
  const [contentType, setContentType] = useState("imageLesson");
  const [isCreating, setIsCreating] = useState(false);
  const [lessonData, setLessonData] = useState({
    title: "",
    description: "",
    category: "FUNCTIONAL_ACADEMICS", // Default category
    difficulty: "beginner", // Default difficulty

    // Core content structure: array of objects { imageFile, imageUrl, description }
    items: [],

    // Mobile App Settings (Toggles)
    enableTTS: true,
    enableAnimations: true,
    enableSoundEffects: true,
    enableProgressTracking: true,
  });

  const handleBasicChange = (e) => {
    setLessonData({ ...lessonData, [e.target.name]: e.target.value });
  };

  const handleSettingToggle = (settingName) => {
    setLessonData((prevData) => ({
      ...prevData,
      [settingName]: !prevData[settingName],
    }));
  };

  const addItem = () => {
    setLessonData((prevData) => ({
      ...prevData,
      items: [
        ...prevData.items,
        { description: "", imageUrl: null, imageFile: null },
      ],
    }));
  };

  const updateItem = (index, newItem) => {
    setLessonData((prevData) => {
      const newItems = [...prevData.items];
      newItems[index] = newItem;
      return { ...prevData, items: newItems };
    });
  };

  const removeItem = (index) => {
    setLessonData((prevData) => ({
      ...prevData,
      items: prevData.items.filter((_, i) => i !== index),
    }));
  };

  const canSubmit = () => {
    // Check title, at least one item, and all items have an image URL and description
    return (
      lessonData.title.trim() !== "" &&
      lessonData.items.length > 0 &&
      lessonData.items.every(
        (item) => item.description?.trim() !== "" && item.imageUrl !== null
      )
    );
  };

  const handleSubmit = async () => {
    if (!canSubmit() || isCreating) return;

    const user = auth.currentUser;
    if (!user) {
      alert("You must be logged in to create content.");
      return;
    }

    setIsCreating(true);

    try {
      // *** 1. IMAGE UPLOAD SIMULATION ***
      // In a real application, a call would be made here to Firebase Storage
      // for each item.imageFile to get a permanent public download URL.

      const processedItems = lessonData.items.map((item) => ({
        description: item.description,
        // Use the temporary URL or a placeholder if a storage function is not available
        imageUrl: item.imageUrl || "placeholder_image_url_required",
        type: "visual_item", // Type for the mobile app to render an image/text card
      }));

      // *** 2. CONSTRUCT THE FINAL MOBILE APP JSON STRUCTURE ***
      const finalLessonData = {
        title: lessonData.title,
        description: lessonData.description,
        category: lessonData.category,
        difficulty: lessonData.difficulty,
        type: "visual_lesson", // Custom type recognized by the Flutter app

        // Settings directly mapped to the student app features
        enableTTS: lessonData.enableTTS,
        enableAnimations: lessonData.enableAnimations,
        enableSoundEffects: lessonData.enableSoundEffects,
        enableProgress: lessonData.enableProgressTracking,

        // Core content structure for the mobile app
        content: {
          items: processedItems, // The simple list of images and descriptions
          currentIndex: 0,
        },

        // Metadata
        createdBy: user.uid, // <-- ADDED: Creator ID
        createdAt: serverTimestamp(),
      };

      // *** 3. SAVE TO FIRESTORE ***
      await addDoc(collection(db, "contents"), finalLessonData);

      onSuccess(`Image Lesson: "${lessonData.title}" created successfully!`);
      onClose();
    } catch (error) {
      console.error("Error creating content:", error);
      alert("Failed to create content. Check the console for details.");
    } finally {
      setIsCreating(false);
    }
  };

  // --- Render Functions for Tabs ---

  const renderImageLessonTab = () => (
    <div className="creation-form">
      <h3>Image Lesson Builder 🖼️</h3>
      <p className="text-muted">
        Create a step-by-step lesson by uploading an image and providing a
        description for each learning item. These descriptions will be read
        aloud to the student.
      </p>

      {/* Basic Info Card */}
      <div className="card p-4 mb-4 shadow-sm">
        <h4>Lesson Details</h4>
        <div className="mb-3">
          <label className="form-label">Lesson Title*</label>
          <input
            type="text"
            className="form-control"
            name="title"
            value={lessonData.title}
            onChange={handleBasicChange}
            placeholder="e.g., Identifying Community Helpers"
            required
          />
        </div>
        <div className="row">
          <div className="col-md-6 mb-3">
            <label className="form-label">Category</label>
            <select
              className="form-select"
              name="category"
              value={lessonData.category}
              onChange={handleBasicChange}
            >
              <option value="FUNCTIONAL_ACADEMICS">Functional Academics</option>
              <option value="COMMUNICATION_SKILLS">Communication Skills</option>
              <option value="SOCIAL_SKILLS">Social Skills</option>
              <option value="SELF_HELP">Self-Help</option>
              <option value="PRE-VOCATIONAL_SKILLS">
                Pre-Vocational Skills
              </option>
              <option value="OTHER">Other</option>
            </select>
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label">Difficulty</label>
            <select
              className="form-select"
              name="difficulty"
              value={lessonData.difficulty}
              onChange={handleBasicChange}
            >
              <option value="beginner">Beginner</option>
              <option value="intermediate">Intermediate</option>
              <option value="advanced">Advanced</option>
            </select>
          </div>
        </div>
      </div>

      {/* Lesson Items Card */}
      <div className="card p-4 mb-4 shadow-sm">
        <h4>Lesson Items (Slides)</h4>
        {lessonData.items.map((item, index) => (
          <LessonItemCreator
            key={index}
            item={item}
            index={index}
            updateItem={updateItem}
            removeItem={removeItem}
          />
        ))}
        <button className="btn btn-secondary w-100" onClick={addItem}>
          <i className="fas fa-plus me-2"></i> Add New Image Item
        </button>
        {lessonData.items.length === 0 && (
          <p className="text-danger mt-2">
            ⚠️ Please add at least one item to the lesson.
          </p>
        )}
      </div>

      {/* App Settings Card */}
      <div className="card p-4 mb-4 shadow-sm">
        <h4>Mobile App Settings</h4>
        <p className="text-muted">
          Control the interactive features for students.
        </p>

        <div className="form-check form-switch mb-2">
          <input
            className="form-check-input"
            type="checkbox"
            role="switch"
            id="enableTTS"
            checked={lessonData.enableTTS}
            onChange={() => handleSettingToggle("enableTTS")}
          />
          <label className="form-check-label" htmlFor="enableTTS">
            <i className="fas fa-volume-up me-2"></i> Enable Text-to-Speech
            (TTS)
          </label>
        </div>

        <div className="form-check form-switch mb-2">
          <input
            className="form-check-input"
            type="checkbox"
            role="switch"
            id="enableSoundEffects"
            checked={lessonData.enableSoundEffects}
            onChange={() => handleSettingToggle("enableSoundEffects")}
          />
          <label className="form-check-label" htmlFor="enableSoundEffects">
            <i className="fas fa-music me-2"></i> Enable Sound Effects
          </label>
        </div>

        <div className="form-check form-switch mb-2">
          <input
            className="form-check-input"
            type="checkbox"
            role="switch"
            id="enableAnimations"
            checked={lessonData.enableAnimations}
            onChange={() => handleSettingToggle("enableAnimations")}
          />
          <label className="form-check-label" htmlFor="enableAnimations">
            <i className="fas fa-bahai me-2"></i> Enable Animations
          </label>
        </div>

        <div className="form-check form-switch">
          <input
            className="form-check-input"
            type="checkbox"
            role="switch"
            id="enableProgressTracking"
            checked={lessonData.enableProgressTracking}
            onChange={() => handleSettingToggle("enableProgressTracking")}
          />
          <label className="form-check-label" htmlFor="enableProgressTracking">
            <i className="fas fa-chart-line me-2"></i> Enable Progress Tracking
          </label>
        </div>
      </div>

      <div className="d-flex justify-content-end mt-4">
        <button
          className="btn btn-primary btn-lg"
          onClick={handleSubmit}
          disabled={!canSubmit() || isCreating}
        >
          {isCreating ? (
            <>
              <span
                className="spinner-border spinner-border-sm me-2"
                role="status"
                aria-hidden="true"
              ></span>
              Creating Lesson...
            </>
          ) : (
            <>
              <i className="fas fa-save me-2"></i> Save and Deploy Lesson
            </>
          )}
        </button>
      </div>
    </div>
  );

  const renderDocumentUploadTab = () => (
    <div className="creation-form">
      <h3>Automatic Content Generation from Document 📄➡️💻</h3>
      <div className="card p-4 mb-4 shadow-sm">
        <h4 className="text-success">
          Proposed Feature: AI-Powered Lesson Generation
        </h4>
        <p className="text-info">
          <i className="fas fa-robot me-2"></i>
          This feature is where you can upload a PDF, Word, or text document and
          have our system automatically convert it into a structured,
          interactive lesson for the student app.
        </p>
        <p className="text-muted">
          **Implementation Note:** Converting complex documents into a
          structured mobile app JSON requires a **backend AI/NLP service**. The
          front-end code below is a placeholder that shows the desired teacher
          experience:
        </p>
        <div className="mb-3">
          <label className="form-label">
            Select Document File (.pdf, .doc, .docx, .txt)
          </label>
          <input
            type="file"
            className="form-control"
            accept=".pdf,.doc,.docx,.txt"
            disabled // Disabled until the backend API is connected
          />
        </div>
        <button className="btn btn-success" disabled>
          <i className="fas fa-magic me-2"></i> Upload and Generate Lesson Draft
        </button>
        <p className="small mt-3 text-warning">
          *Once generated, you will review and edit the draft using a simplified
          interface like the Image Lesson Builder before saving.
        </p>
      </div>
    </div>
  );

  return (
    <div className="content-creation-modal-overlay">
      <div className="content-creation-modal-content">
        <div className="modal-header">
          <h2 className="modal-title">Create New Content</h2>
          <button className="close-btn" onClick={onClose}>
            &times;
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="nav nav-tabs mb-4">
          <button
            className={`nav-link ${
              contentType === "imageLesson" ? "active" : ""
            }`}
            onClick={() => setContentType("imageLesson")}
          >
            <i className="fas fa-images me-2"></i> Image Lesson Builder
          </button>
          <button
            className={`nav-link ${
              contentType === "documentUpload" ? "active" : ""
            }`}
            onClick={() => setContentType("documentUpload")}
          >
            <i className="fas fa-file-upload me-2"></i> Auto-Generate (PDF/DOC)
          </button>
        </div>

        <div className="modal-body p-0">
          {contentType === "imageLesson" && renderImageLessonTab()}
          {contentType === "documentUpload" && renderDocumentUploadTab()}
        </div>
      </div>
    </div>
  );
};

export default ContentCreation;
