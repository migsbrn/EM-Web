import React, { useState, useEffect } from "react";
import { getAuth } from "firebase/auth";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import {
  addDoc,
  collection,
  serverTimestamp,
  query,
  where,
  getDocs,
  doc,
  updateDoc,
} from "firebase/firestore";
import { db } from "../firebase";
import "../styles/RobustContentCreation.css";

const RobustContentCreation = ({ onClose, onSuccess, editContent }) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    category: "",
    items: [],
    settings: {
      enableTTS: true,
      enableAnimations: true,
      enableSoundEffects: true,
      enableGamification: true,
      enableProgressTracking: true,
      enableConfetti: true,
    },
  });
  const [currentItem, setCurrentItem] = useState({
    name: "",
    description: "",
    image: "",
  });
  const [isCreating, setIsCreating] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [duplicateCheck, setDuplicateCheck] = useState({
    isChecking: false,
    isDuplicate: false,
    message: "",
  });

  useEffect(() => {
    if (editContent) {
      console.log("Edit Mode: Initializing form with content:", editContent);

      setFormData({
        title: editContent.title || "",
        description: editContent.description || "",
        category: editContent.category || "",
        items: editContent.lessonData?.items || [],
        settings: editContent.settings || {
          enableTTS: true,
          enableAnimations: true,
          enableSoundEffects: true,
          enableGamification: true,
          enableProgressTracking: true,
          enableConfetti: true,
        },
      });

      setCurrentStep(1); // Start at step 1 for editing
    } else {
      setCurrentStep(1);
      setFormData({
        title: "",
        description: "",
        category: "",
        items: [],
        settings: {
          enableTTS: true,
          enableAnimations: true,
          enableSoundEffects: true,
          enableGamification: true,
          enableProgressTracking: true,
          enableConfetti: true,
        },
      });
    }
  }, [editContent]);

  const categories = [
    {
      value: "FUNCTIONAL_ACADEMICS",
      label: "Basic Learning (Reading, Math, etc.)",
    },
    { value: "COMMUNICATION_SKILLS", label: "Communication & Speaking" },
    { value: "SOCIAL_SKILLS", label: "Social & Emotional Skills" },
    { value: "PRE-VOCATIONAL_SKILLS", label: "Work & Job Skills" },
    { value: "SELF_HELP", label: "Self-Care & Daily Living" },
    { value: "NUMBER_SKILLS", label: "Numbers & Counting" },
  ];

  const uploadImageToStorage = async (file, itemName) => {
    return new Promise(async (resolve, reject) => {
      try {
        setUploadingImage(true);

        console.log("Starting image upload for:", itemName);

        const allowedTypes = [
          "image/jpeg",
          "image/jpg",
          "image/png",
          "image/gif",
          "image/webp",
        ];
        if (!allowedTypes.includes(file.type)) {
          alert("Please select a valid image file (JPEG, PNG, GIF, or WebP)");
          resolve(null);
          return;
        }

        const maxSize = 5 * 1024 * 1024;
        if (file.size > maxSize) {
          alert("File size must be less than 5MB");
          resolve(null);
          return;
        }

        const storage = getStorage();
        const fileExtension = file.type.split("/")[1];
        const storageRef = ref(
          storage,
          `lesson_images/${itemName}_${Date.now()}.${fileExtension}`
        );

        console.log("Uploading to storage path:", storageRef.fullPath);

        await uploadBytes(storageRef, file);
        const downloadUrl = await getDownloadURL(storageRef);

        console.log("Image uploaded successfully:", downloadUrl);
        resolve(downloadUrl);
      } catch (error) {
        console.error("Error uploading image:", error);
        alert("Failed to upload image: " + error.message);
        reject(error);
      } finally {
        setUploadingImage(false);
      }
    });
  };

  const handleImageUpload = (fieldName, file) => {
    if (file) {
      const allowedTypes = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/gif",
        "image/webp",
      ];
      if (!allowedTypes.includes(file.type)) {
        alert("Please select a valid image file (JPEG, PNG, GIF, or WebP)");
        return;
      }

      const maxSize = 5 * 1024 * 1024;
      if (file.size > maxSize) {
        alert("File size must be less than 5MB");
        return;
      }

      const previewUrl = URL.createObjectURL(file);

      console.log("Image selected for preview:", fieldName);

      setCurrentItem((prev) => ({
        ...prev,
        [fieldName]: previewUrl,
        [`${fieldName}File`]: file,
      }));
    }
  };

  const handleAddItem = async () => {
    if (!currentItem.name) {
      alert("Please fill in the Item Name");
      return;
    }

    console.log("Adding item:", currentItem);

    let imageUrl = null;
    if (currentItem.imageFile) {
      console.log("Uploading image file...");
      imageUrl = await uploadImageToStorage(
        currentItem.imageFile,
        currentItem.name || `item_${Date.now()}`
      );
      if (!imageUrl) {
        console.error("Image upload failed");
        return;
      }
    } else if (currentItem.image && !currentItem.imageFile) {
      if (currentItem.image.startsWith("http")) {
        imageUrl = currentItem.image;
        console.log("Using existing image URL:", imageUrl);
      } else {
        console.warn(
          "New image added but not a file object, assuming placeholder URL is invalid."
        );
        alert(
          "Image was not properly selected as a file or failed to upload. Please re-select the image."
        );
        return;
      }
    }

    const processedItem = {
      ...currentItem,
      type: "custom",
      id: Date.now(),
      ttsText: currentItem.description || currentItem.name,
      imageUrl: imageUrl,
    };

    delete processedItem.image;
    delete processedItem.imageFile;

    console.log("Processed item:", processedItem);

    setFormData((prev) => ({
      ...prev,
      items: [...prev.items, processedItem],
    }));

    setCurrentItem({
      name: "",
      description: "",
      image: "",
    });

    console.log(
      "Item added successfully. Total items:",
      formData.items.length + 1
    );
  };

  const handleRemoveItem = (id) => {
    console.log("Removing item with id:", id);
    setFormData((prev) => ({
      ...prev,
      items: prev.items.filter((item) => item.id !== id),
    }));
  };

  const checkForDuplicateLesson = async (title) => {
    const isEditMode = !!editContent;
    let q = query(collection(db, "contents"), where("title", "==", title));

    if (isEditMode) {
      q = query(q, where("__name__", "!=", editContent.id));
    }

    try {
      console.log("Checking for duplicate lesson with title:", title);
      setDuplicateCheck({ isChecking: true, isDuplicate: false, message: "" });
      const querySnapshot = await getDocs(q);
      if (!querySnapshot.empty) {
        console.warn("Duplicate lesson found");
        setDuplicateCheck({
          isChecking: false,
          isDuplicate: true,
          message:
            "A lesson with this title already exists. Please choose a different title.",
        });
        return true;
      }
      console.log("No duplicate found");
      setDuplicateCheck({ isChecking: false, isDuplicate: false, message: "" });
      return false;
    } catch (error) {
      console.error("Error checking for duplicate:", error);
      setDuplicateCheck({
        isChecking: false,
        isDuplicate: false,
        message: "Error checking for duplicates. Please try again.",
      });
      return false;
    }
  };

  const handleSubmit = async () => {
    if (isCreating) {
      console.log("Already creating, preventing duplicate submission");
      return;
    }

    console.log("=== Starting lesson submission ===");
    console.log("Form data:", formData);

    const user = getAuth().currentUser;
    if (!user) {
      console.error("No authenticated user");
      alert("You must be logged in to create content.");
      return;
    }
    console.log("Authenticated user:", user.uid);

    if (!formData.title) {
      console.error("No title provided");
      alert("Please enter a lesson title.");
      return;
    }

    if (!formData.category) {
      console.error("No category selected");
      alert("Please select a category.");
      return;
    }

    if (formData.items.length === 0) {
      console.error("No items added");
      alert("Please add at least one lesson item.");
      return;
    }

    const isDuplicate = await checkForDuplicateLesson(formData.title);
    if (isDuplicate) {
      console.log("Duplicate detected, aborting submission");
      return;
    }

    setIsCreating(true);
    console.log("Set isCreating to true");

    try {
      const finalType = editContent?.type || "lesson";

      console.log("Final lesson type that will be saved:", finalType);

      const sharedData = {
        title: formData.title,
        description: formData.description,
        category: formData.category,
        type: finalType,
        lessonData: {
          items: formData.items,
          currentIndex: 0,
        },
        settings: formData.settings,
        studentAppReady: true,
        status: "active",
        createdBy: user.uid,
        forceRefresh: true,
        cacheBuster: Date.now(),
        version: (editContent?.version || 0) + 1,
      };

      console.log(
        "Complete data to be saved:",
        JSON.stringify(sharedData, null, 2)
      );

      if (editContent) {
        console.log("Updating existing lesson:", editContent.id);
        const lessonRef = doc(db, "contents", editContent.id);
        await updateDoc(lessonRef, {
          ...sharedData,
          updatedAt: serverTimestamp(),
          createdBy: editContent.createdBy,
        });
        console.log("✅ Lesson updated successfully with type:", finalType);
        onSuccess(`Lesson "${formData.title}" updated successfully!`);
        onClose();
      } else {
        console.log("Creating new lesson in Firestore...");
        const docRef = await addDoc(collection(db, "contents"), {
          ...sharedData,
          createdAt: serverTimestamp(),
        });

        console.log("✅ Lesson created successfully with ID:", docRef.id);
        console.log("✅ Lesson type saved as:", finalType);
        console.log("✅ This lesson should now appear in mobile app!");

        const newLesson = {
          id: docRef.id,
          ...sharedData,
          createdAt: new Date(),
        };

        console.log("New lesson object for state update:", newLesson);

        onSuccess(
          `Lesson "${formData.title}" created successfully!`,
          newLesson
        );
        onClose();
      }
    } catch (error) {
      console.error(
        `❌ Error ${editContent ? "updating" : "creating"} lesson:`,
        error
      );
      alert(
        `Failed to ${editContent ? "update" : "create"} lesson: ` +
          error.message
      );

      console.error("Error details:", {
        code: error.code,
        message: error.message,
        stack: error.stack,
      });
    } finally {
      setIsCreating(false);
      console.log("Set isCreating to false");
    }
  };

  return (
    <div className="modal-overlay">
      <div
        className="modal-content"
        style={{ width: "90%", maxWidth: "800px" }}
      >
        <div className="modal-header">
          <h2>{editContent ? "Edit Lesson" : "Create Custom Lesson"}</h2>
          <button className="close-btn" onClick={onClose}>
            &times;
          </button>
        </div>

        <div className="modal-body">
          {currentStep === 1 && (
            <div>
              <h3>
                📝{" "}
                {editContent ? "Edit Your Lesson" : "Create Your Custom Lesson"}
              </h3>
              <p className="text-muted mb-4">
                Build a custom lesson by adding items with images and
                descriptions.
              </p>

              <div className="form-section">
                <h4>Lesson Details</h4>
                <div className="form-group">
                  <label>Lesson Title *</label>
                  <input
                    type="text"
                    value={formData.title}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        title: e.target.value,
                      }))
                    }
                    placeholder="Enter lesson title"
                    className="form-control"
                  />
                  {duplicateCheck.isDuplicate && (
                    <div className="alert alert-warning mt-2">
                      {duplicateCheck.message}
                    </div>
                  )}
                </div>
                <div className="form-group">
                  <label>Description</label>
                  <textarea
                    value={formData.description}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        description: e.target.value,
                      }))
                    }
                    placeholder="Describe your lesson"
                    className="form-control"
                    rows="4"
                  />
                </div>
                <div className="form-group">
                  <label>Category *</label>
                  <select
                    value={formData.category}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        category: e.target.value,
                      }))
                    }
                    className="form-control"
                  >
                    <option value="">Select a category</option>
                    {categories.map((category) => (
                      <option key={category.value} value={category.value}>
                        {category.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-section">
                <h4>Add Lesson Item</h4>
                <div className="form-group">
                  <label>Item Name *</label>
                  <input
                    type="text"
                    value={currentItem.name || ""}
                    onChange={(e) =>
                      setCurrentItem((prev) => ({
                        ...prev,
                        name: e.target.value,
                      }))
                    }
                    placeholder="Enter item name"
                    className="form-control"
                  />
                </div>
                <div className="form-group">
                  <label>Description *</label>
                  <textarea
                    value={currentItem.description || ""}
                    onChange={(e) =>
                      setCurrentItem((prev) => ({
                        ...prev,
                        description: e.target.value,
                      }))
                    }
                    placeholder="Describe this item"
                    className="form-control"
                    rows="4"
                  />
                </div>
                <div className="form-group">
                  <label>Item Image</label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) =>
                      handleImageUpload("image", e.target.files[0])
                    }
                    className="form-control"
                  />
                  {currentItem.image && (
                    <img
                      src={currentItem.image}
                      alt="Preview"
                      style={{
                        maxWidth: "200px",
                        marginTop: "10px",
                        borderRadius: "8px",
                      }}
                    />
                  )}
                </div>

                <button
                  onClick={handleAddItem}
                  className="btn btn-primary"
                  style={{ width: "100%", marginTop: "10px" }}
                  disabled={uploadingImage}
                >
                  {uploadingImage ? "⏳ Uploading Image..." : "➕ Add Item"}
                </button>
              </div>

              {formData.items.length > 0 && (
                <div>
                  <h5>Added Items ({formData.items.length})</h5>
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      gap: "10px",
                    }}
                  >
                    {formData.items.map((item, index) => (
                      <div
                        key={item.id}
                        className="item-card"
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "15px",
                          padding: "15px",
                          backgroundColor: "#f0f8ff",
                          borderRadius: "8px",
                          border: "1px solid #b3d9ff",
                        }}
                      >
                        {item.imageUrl && (
                          <img
                            src={item.imageUrl}
                            alt={item.name}
                            style={{
                              width: "80px",
                              height: "80px",
                              objectFit: "cover",
                              borderRadius: "8px",
                              border: "2px solid #ddd",
                            }}
                          />
                        )}
                        <div style={{ flex: 1 }}>
                          <strong>
                            {index + 1}. {item.name}
                          </strong>
                          <p
                            style={{
                              margin: "5px 0 0 0",
                              fontSize: "14px",
                              color: "#666",
                            }}
                          >
                            {item.description}
                          </p>
                        </div>
                        <button
                          onClick={() => handleRemoveItem(item.id)}
                          className="btn btn-danger btn-sm"
                        >
                          Remove
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              <div
                style={{
                  display: "flex",
                  justifyContent: "flex-end",
                  marginTop: "20px",
                }}
              >
                <button
                  onClick={() => setCurrentStep(2)}
                  disabled={formData.items.length === 0}
                  className="btn btn-primary"
                >
                  Next: Review →
                </button>
              </div>
            </div>
          )}

          {currentStep === 2 && (
            <div>
              <h3>Review Your Lesson</h3>

              <div
                className="review-section"
                style={{
                  backgroundColor: "white",
                  padding: "25px",
                  borderRadius: "12px",
                  marginBottom: "20px",
                  boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                }}
              >
                <h4 style={{ color: "#4CAF50" }}>✓ {formData.title}</h4>
                {formData.description && <p>{formData.description}</p>}
                <p>
                  <strong>Category:</strong>{" "}
                  {categories.find((c) => c.value === formData.category)?.label}
                </p>
                <p>
                  <strong>Total Items:</strong> {formData.items.length}
                </p>

                <div style={{ marginTop: "20px" }}>
                  <h5>📱 Mobile App Preview:</h5>
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      gap: "15px",
                    }}
                  >
                    {formData.items.map((item, index) => (
                      <div
                        key={item.id}
                        style={{
                          padding: "15px",
                          backgroundColor: "#f9f9f9",
                          borderRadius: "12px",
                          display: "flex",
                          alignItems: "center",
                          gap: "15px",
                          border: "2px solid #e0e0e0",
                        }}
                      >
                        {item.imageUrl && (
                          <img
                            src={item.imageUrl}
                            alt={item.name}
                            style={{
                              width: "100px",
                              height: "100px",
                              objectFit: "cover",
                              borderRadius: "8px",
                              border: "2px solid #ddd",
                            }}
                          />
                        )}
                        <div style={{ flex: 1 }}>
                          <strong style={{ fontSize: "16px" }}>
                            {index + 1}. {item.name}
                          </strong>
                          <p
                            style={{
                              margin: "8px 0 0 0",
                              fontSize: "14px",
                              color: "#666",
                              lineHeight: "1.5",
                            }}
                          >
                            {item.description}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div
                className="alert alert-info"
                style={{
                  backgroundColor: "#e3f2fd",
                  border: "1px solid #2196f3",
                  padding: "20px",
                  borderRadius: "8px",
                  marginBottom: "20px",
                }}
              >
                <h5>💡 Before You Save</h5>
                <ul style={{ marginBottom: 0 }}>
                  <li>Make sure all information is correct</li>
                  <li>You can edit this lesson later if needed</li>
                  <li>
                    <strong>
                      Students will see this lesson in their mobile app
                      immediately
                    </strong>
                  </li>
                  <li>
                    All uploaded images are stored in the cloud and will display
                    properly
                  </li>
                </ul>
              </div>

              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  marginTop: "20px",
                }}
              >
                <button
                  onClick={() => setCurrentStep(1)}
                  className="btn btn-secondary"
                >
                  ← Back to Edit
                </button>
                <button
                  onClick={handleSubmit}
                  disabled={isCreating}
                  className="btn btn-success"
                  style={{ fontSize: "16px", padding: "12px 30px" }}
                >
                  {isCreating
                    ? "⏳ Saving..."
                    : editContent
                    ? "💾 Update Lesson"
                    : "💾 Save Lesson"}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default RobustContentCreation;
