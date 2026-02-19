import React, { useState, useEffect, useRef } from "react";
import { getAuth, updateProfile, onAuthStateChanged } from "firebase/auth";
// Added onSnapshot for real-time listening
import {
  getFirestore,
  doc,
  getDoc,
  setDoc,
  onSnapshot,
} from "firebase/firestore";
import "../styles/Settings.css";

// Initialize services
const auth = getAuth();
const db = getFirestore(); // Initialize Firestore

const Settings = () => {
  const fileInputRef = useRef(null);
  const [user, setUser] = useState(null);
  const [adminProfileData, setAdminProfileData] = useState({});
  const [displayName, setDisplayName] = useState("");
  // photoFile stores the Base64 string
  const [photoFile, setPhotoFile] = useState(null);
  const [previewImage, setPreviewImage] = useState(null); // URL for display
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [isUploading, setIsUploading] = useState(false);
  // Delete account functionality removed

  useEffect(() => {
    const auth = getAuth();
    let snapshotUnsubscribe = () => {};

    const unsubscribeAuth = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      setDisplayName(currentUser?.displayName || "");

      if (currentUser) {
        const adminDocRef = doc(db, "admins", currentUser.uid);

        // Use onSnapshot to listen for real-time updates on the Admin profile data
        snapshotUnsubscribe = onSnapshot(
          adminDocRef,
          (docSnapshot) => {
            const data = docSnapshot.data();
            if (docSnapshot.exists()) {
              setAdminProfileData(data);
              // Prioritize Base64 image from Firestore, otherwise use Auth profile URL
              setPreviewImage(
                data.profilePhotoBase64 || currentUser.photoURL || null,
              );
            } else {
              // If no custom profile, use Auth photoURL
              setPreviewImage(currentUser.photoURL || null);
            }
          },
          (error) => {
            console.error("Error listening to admin profile:", error);
            setPreviewImage(currentUser.photoURL || null);
          },
        );
      } else {
        // Clear snapshot listener if user logs out
        if (snapshotUnsubscribe) snapshotUnsubscribe();
      }
    });

    // Cleanup: unsubscribe from both listeners
    return () => {
      unsubscribeAuth();
      if (snapshotUnsubscribe) snapshotUnsubscribe();
    };
  }, [db]);

  const generateNameFromEmail = (email) => {
    if (!email) return "N/A";
    const prefix = email.split("@")[0];
    const lettersOnly = prefix.replace(/[^a-zA-Z]/g, "");
    return lettersOnly.charAt(0).toUpperCase() + lettersOnly.slice(1);
  };

  const handleNameChange = async (e) => {
    e.preventDefault();
    setError("");
    setSuccess("");
    if (!displayName.trim()) {
      setError("Name cannot be empty");
      return;
    }
    try {
      await updateProfile(auth.currentUser, { displayName });
      // Also update Firestore admin document
      const adminDocRef = doc(db, "admins", auth.currentUser.uid);
      await setDoc(adminDocRef, { displayName }, { merge: true });

      setSuccess("Name updated successfully");

      // Clear success message after 3 seconds
      setTimeout(() => {
        setSuccess("");
      }, 3000);
    } catch (error) {
      setError("Error updating name: " + error.message);
    }
  };

  // Triggers the hidden file input when the profile picture is clicked
  const handleProfilePhotoClick = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  // Reads the file as a Base64 string and stores it in state (SAME AS USERPROFILE.JSX)
  const handleFileChange = (e) => {
    setError("");
    const file = e.target.files[0];

    if (file) {
      const allowedTypes = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/gif",
      ];
      if (!allowedTypes.includes(file.type)) {
        setError("Please select a valid image file (JPEG, PNG, or GIF).");
        setPhotoFile(null);
        return;
      }
      // Keep max size check but rely on Firestore limit
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSize) {
        setError("File size must be less than 5MB.");
        setPhotoFile(null);
        return;
      }

      const reader = new FileReader();
      reader.onload = (e) => {
        const base64String = e.target.result;
        setPhotoFile(base64String); // Store the Base64 string
        setPreviewImage(base64String); // Set the preview
      };
      reader.onerror = () => {
        setError("Error reading file. Please try again.");
        setPhotoFile(null);
      };
      reader.readAsDataURL(file);
    } else {
      setPhotoFile(null);
    }
  };

  // Saves the Base64 string to a Firestore document and clears the success message.
  const handlePhotoUpload = async (e) => {
    e.preventDefault();
    setError("");
    setSuccess("");

    if (!photoFile) {
      setError("Please select a new photo.");
      return;
    }

    setIsUploading(true);
    try {
      const adminDocRef = doc(db, "admins", auth.currentUser.uid);

      // Save the Base64 string to the Firestore document field 'profilePhotoBase64'
      await setDoc(
        adminDocRef,
        {
          profilePhotoBase64: photoFile,
          updatedAt: new Date().toISOString(),
        },
        { merge: true },
      );

      setSuccess("Profile photo updated successfully");
      setPhotoFile(null); // Clear the file state after update

      // Clear success message after 3 seconds
      setTimeout(() => {
        setSuccess("");
      }, 3000);
    } catch (error) {
      console.error("Firestore Update Error (Base64 method):", error);
      setError(
        "Error updating photo in Firestore. It may exceed the 1MB document limit.",
      );
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="settings-outer-wrapper">
      {/* Moved Title Outside the Card */}
      <h1 className="settings-page-title">Account Settings</h1>

      <div className="settings-container">
        {/* Admin Profile Section */}
        <div className="settings-section">
          <h2 className="settings-subsection-title">Profile Photo & Info</h2>

          <div className="profile-photo-upload-container">
            <div
              className="profile-picture-wrapper"
              onClick={handleProfilePhotoClick}
              title="Click to change profile photo"
            >
              {/* Display the image or the placeholder icon */}
              {previewImage ? (
                <img
                  src={previewImage}
                  alt="Admin Profile"
                  className="modal-profile-image"
                />
              ) : (
                <div className="profile-placeholder">
                  <i className="fas fa-user"></i>
                </div>
              )}

              {/* Camera Overlay Icon */}
              <div className="camera-overlay">
                <i className="fas fa-camera"></i>
              </div>
            </div>

            {/* Hidden File Input */}
            <input
              type="file"
              accept="image/*"
              ref={fileInputRef}
              onChange={handleFileChange}
              style={{ display: "none" }}
              id="profile-photo-input"
            />
          </div>

          <div className="modal-info">
            <div className="profile-info-item">
              <strong>Name:</strong>{" "}
              <span>
                {user?.displayName || generateNameFromEmail(user?.email)}
              </span>
            </div>
            <div className="profile-info-item">
              <strong>Email:</strong> <span>{user?.email || "N/A"}</span>
            </div>
          </div>

          {/* Upload Button visible only if a new photo is selected */}
          {photoFile && (
            <div className="settings-field upload-action-field">
              <button
                className="settings-button settings-button-primary"
                onClick={handlePhotoUpload}
                disabled={isUploading}
              >
                {isUploading ? (
                  <>
                    <i className="fas fa-spinner fa-spin me-2"></i> Saving...
                  </>
                ) : (
                  <>
                    <i className="fas fa-cloud-upload-alt"></i> Confirm Photo
                    Update
                  </>
                )}
              </button>
            </div>
          )}

          <form onSubmit={handleNameChange} className="settings-field">
            <label className="settings-label">Update Name</label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              className="settings-input"
              placeholder="Enter new name"
            />
            <button
              type="submit"
              className="settings-button settings-button-secondary"
            >
              <i className="fas fa-pen"></i> Update Name
            </button>
          </form>

          {error && (
            <p className="error-message">
              <i className="fas fa-exclamation-circle"></i> {error}
            </p>
          )}
          {success && (
            <p className="success-message">
              <i className="fas fa-check-circle"></i> {success}
            </p>
          )}
        </div>
      </div>
    </div>
  );
};

export default Settings;
