import React, { useState, useEffect } from 'react';
import { getAuth, onAuthStateChanged } from 'firebase/auth';
import { getFirestore, doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { useNavigate } from 'react-router-dom';
import '../styles/UserProfile.css';
import 'bootstrap/dist/css/bootstrap.min.css';

const UserProfile = () => {
  const navigate = useNavigate();
  const [userData, setUserData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    profilePhoto: "",
    contactNo: "",
    streetAddress: "",
    barangay: "",
    cityMunicipality: "",
    province: "",
    postalCode: "",
    school: "",
    qualification: "",
    dateOfBirth: "",
    role: "",
    status: "",
    createdAt: "",
    // Additional fields for profile enhancement
    bio: "",
    workPlace: "",
    education: "",
    languages: "",
    interests: ""
  });
  
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [profileImage, setProfileImage] = useState(null);
  const [previewImage, setPreviewImage] = useState(null);
  const [coverImage, setCoverImage] = useState(null);
  const [previewCoverImage, setPreviewCoverImage] = useState(null);
  const [saveStatus, setSaveStatus] = useState(null);
  const [activeTab, setActiveTab] = useState('about');

  useEffect(() => {
    const auth = getAuth();
    const db = getFirestore();

    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        try {
          // Try to get from teacherRequests collection first
          let userDocRef = doc(db, "teacherRequests", user.uid);
          let userDoc = await getDoc(userDocRef);
          
          if (!userDoc.exists()) {
            // Fallback to teachers collection
            userDocRef = doc(db, "teachers", user.uid);
            userDoc = await getDoc(userDocRef);
          }

          if (userDoc.exists()) {
            const data = userDoc.data();
            console.log("Fetched user data from Firestore:", data);

            let formattedDob = "Date of Birth not set";
            if (data.dateOfBirth) {
              if (typeof data.dateOfBirth.toDate === "function") {
                try {
                  formattedDob = data.dateOfBirth
                    .toDate()
                    .toLocaleDateString(undefined, {
                      year: "numeric",
                      month: "long",
                      day: "numeric",
                    });
                } catch (e) {
                  console.error("Error formatting dateOfBirth from Timestamp:", e);
                  formattedDob = "Invalid Date";
                }
              } else if (typeof data.dateOfBirth === "string") {
                formattedDob = data.dateOfBirth;
              }
            }

            setUserData({
              firstName: data.firstName || "",
              lastName: data.lastName || "",
              email: user.email || "",
              profilePhoto: data.profilePhoto || "",
              contactNo: data.contactNo || "",
              streetAddress: data.streetAddress || "",
              barangay: data.barangay || "",
              cityMunicipality: data.cityMunicipality || "",
              province: data.province || "",
              postalCode: data.postalCode || "",
              school: data.school || "",
              qualification: data.qualification || "",
              dateOfBirth: formattedDob,
              role: data.role || "",
              status: data.status || "",
              createdAt: data.createdAt || "",
              // Additional fields for profile enhancement
              bio: data.bio || "",
              workPlace: data.workPlace || "",
              education: data.education || "",
              languages: data.languages || "",
              interests: data.interests || "",
              coverPhoto: data.coverPhoto || ""
            });
          } else {
            console.error("User document not found in Firestore for UID:", user.uid);
            setUserData(prev => ({
              ...prev,
              email: user.email || "",
            }));
          }
        } catch (error) {
          console.error("Error fetching user data:", error);
        } finally {
          setLoading(false);
        }
      } else {
        console.error("No authenticated user found");
        setLoading(false);
      }
    });

    return () => unsubscribe();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setUserData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleImageChange = (e, type) => {
    const file = e.target.files[0];
    if (file) {
      // Validate file type
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
      if (!allowedTypes.includes(file.type)) {
        alert('Please select a valid image file (JPEG, PNG, or GIF)');
        return;
      }
      
      // Validate file size (max 5MB)
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSize) {
        alert('File size must be less than 5MB');
        return;
      }
      
      const reader = new FileReader();
      reader.onload = (e) => {
        const base64String = e.target.result;
        
        if (type === 'profile') {
          setProfileImage(base64String);
          setPreviewImage(base64String);
        } else if (type === 'cover') {
          setCoverImage(base64String);
          setPreviewCoverImage(base64String);
        }
      };
      reader.onerror = () => {
        alert('Error reading file. Please try again.');
      };
      reader.readAsDataURL(file);
    }
  };


  const handleSave = async () => {
    const auth = getAuth();
    const db = getFirestore();
    
    try {
      setUploading(true);
      const user = auth.currentUser;
      if (!user) throw new Error('No authenticated user');

      // Validate required fields
      if (!userData.firstName.trim() || !userData.lastName.trim()) {
        alert('First name and last name are required');
        return;
      }

      // Update user data with base64 images if selected
      const updatedData = {
        ...userData,
        profilePhoto: profileImage || userData.profilePhoto,
        coverPhoto: coverImage || userData.coverPhoto,
        updatedAt: serverTimestamp()
      };

      // Try to update in teacherRequests collection first
      let userDocRef = doc(db, "teacherRequests", user.uid);
      await updateDoc(userDocRef, updatedData);
      
      // Also update in teachers collection if it exists
      try {
        const teachersDocRef = doc(db, "teachers", user.uid);
        await updateDoc(teachersDocRef, updatedData);
      } catch (e) {
        console.log("Teachers collection doesn't exist or update failed:", e);
      }

      setUserData(prev => ({
        ...prev,
        profilePhoto: profileImage || prev.profilePhoto,
        coverPhoto: coverImage || prev.coverPhoto
      }));
      
      setEditing(false);
      setProfileImage(null);
      setPreviewImage(null);
      setCoverImage(null);
      setPreviewCoverImage(null);
      setSaveStatus('success');
      
      setTimeout(() => setSaveStatus(null), 3000);
      
    } catch (error) {
      console.error('Error saving profile:', error);
      setSaveStatus('error');
      alert(`Failed to save profile: ${error.message}`);
      setTimeout(() => setSaveStatus(null), 3000);
    } finally {
      setUploading(false);
    }
  };

  const handleCancel = () => {
    setEditing(false);
    setProfileImage(null);
    setPreviewImage(null);
    setCoverImage(null);
    setPreviewCoverImage(null);
    window.location.reload();
  };

  const formatAddress = () => {
    const parts = [
      userData.streetAddress,
      userData.barangay,
      userData.cityMunicipality,
      userData.province,
    ].filter((part) => part && part !== "");
    
    return parts.length ? parts.join(", ") : "Address not set";
  };


  if (loading) {
    return (
      <div className="profile-loading">
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
        <p>Loading profile...</p>
      </div>
    );
  }

  return (
    <div className="facebook-profile-container">
      {/* Back Button */}
      <div className="profile-back-button">
        <button 
          className="btn btn-outline-primary back-btn"
          onClick={() => navigate('/teacher-dashboard')}
        >
          <i className="fas fa-arrow-left me-2"></i>
          Back to Dashboard
        </button>
      </div>

      {/* Cover Photo Section */}
      <div className="cover-photo-section">
        <div className="cover-photo" style={{
          backgroundImage: previewCoverImage 
            ? `url(${previewCoverImage})` 
            : userData.coverPhoto 
              ? `url(${userData.coverPhoto})` 
              : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          backgroundSize: 'cover',
          backgroundPosition: 'center'
        }}>
          
          {editing && (
            <div className="cover-photo-upload">
              <label htmlFor="cover-photo-input" className="cover-upload-btn">
                <i className="fas fa-camera"></i>
                <span>Change Cover Photo</span>
              </label>
              <input
                type="file"
                id="cover-photo-input"
                accept="image/*"
                onChange={(e) => handleImageChange(e, 'cover')}
                style={{ display: 'none' }}
              />
            </div>
          )}
        </div>
      </div>

      {/* Profile Header Section */}
      <div className="profile-header-section">
        <div className="profile-header-content">
          {/* Profile Picture */}
          <div className="profile-picture-container">
            {previewImage ? (
              <img src={previewImage} alt="Profile Preview" className="profile-img" />
            ) : userData.profilePhoto ? (
              <img src={userData.profilePhoto} alt="Profile" className="profile-img" />
            ) : (
              <div className="profile-placeholder">
                <i className="fas fa-user"></i>
              </div>
            )}
            
            {editing && (
              <div className="profile-picture-upload">
                <label htmlFor="profile-picture-input" className="profile-upload-btn">
                  <i className="fas fa-camera"></i>
                </label>
                <input
                  type="file"
                  id="profile-picture-input"
                  accept="image/*"
                  onChange={(e) => handleImageChange(e, 'profile')}
                  style={{ display: 'none' }}
                />
              </div>
            )}
          </div>

          {/* Profile Info */}
          <div className="profile-info">
            <div className="profile-name-section">
              <h1 className="profile-name">
                {userData.firstName} {userData.lastName}
              </h1>
              <p className="profile-title">{userData.qualification || "Teacher"}</p>
              <p className="profile-location">
                <i className="fas fa-map-marker-alt"></i>
                {formatAddress()}
              </p>
              <div className="profile-status">
                <span className={`status-badge ${userData.status === 'Active' ? 'active' : 'inactive'}`}>
                  <i className="fas fa-circle"></i>
                  {userData.status || 'Pending'}
                </span>
              </div>
            </div>

            <div className="profile-actions">
              {!editing ? (
                <button 
                  className="btn btn-primary edit-profile-btn"
                  onClick={() => setEditing(true)}
                >
                  <i className="fas fa-edit"></i> Edit Profile
                </button>
              ) : (
                <div className="edit-actions">
                  <button 
                    className="btn btn-success save-btn"
                    onClick={handleSave}
                    disabled={uploading}
                  >
                    {uploading ? (
                      <>
                        <span className="spinner-border spinner-border-sm me-2"></span>
                        Saving...
                      </>
                    ) : (
                      <>
                        <i className="fas fa-save"></i> Save Changes
                      </>
                    )}
                  </button>
                  <button 
                    className="btn btn-secondary cancel-btn"
                    onClick={handleCancel}
                    disabled={uploading}
                  >
                    <i className="fas fa-times"></i> Cancel
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {saveStatus && (
          <div className={`save-status ${saveStatus}`}>
            {saveStatus === 'success' ? (
              <i className="fas fa-check-circle"></i>
            ) : (
              <i className="fas fa-exclamation-circle"></i>
            )}
            {saveStatus === 'success' ? 'Profile updated successfully!' : 'Error updating profile. Please try again.'}
          </div>
        )}
      </div>

      {/* Navigation Tabs */}
      <div className="profile-nav">
        <div className="nav-tabs">
          <button 
            className={`nav-tab ${activeTab === 'about' ? 'active' : ''}`}
            onClick={() => setActiveTab('about')}
          >
            <i className="fas fa-user"></i> About
          </button>
          <button 
            className={`nav-tab ${activeTab === 'contact' ? 'active' : ''}`}
            onClick={() => setActiveTab('contact')}
          >
            <i className="fas fa-address-book"></i> Contact
          </button>
          <button 
            className={`nav-tab ${activeTab === 'professional' ? 'active' : ''}`}
            onClick={() => setActiveTab('professional')}
          >
            <i className="fas fa-graduation-cap"></i> Professional
          </button>
        </div>
      </div>

      {/* Tab Content */}
      <div className="profile-content">
        {activeTab === 'about' && (
          <div className="tab-content">
            <div className="content-section">
              <h3><i className="fas fa-user"></i> Biography</h3>
              <div className="section-content">
                {editing ? (
                  <textarea
                    name="bio"
                    value={userData.bio}
                    onChange={handleInputChange}
                    className="form-control bio-textarea"
                    rows="4"
                    placeholder="Tell us about yourself as an educator..."
                  />
                ) : (
                  <p className="bio-text">{userData.bio || "No biography provided"}</p>
                )}
              </div>
            </div>

            <div className="content-section">
              <h3><i className="fas fa-graduation-cap"></i> Education</h3>
              <div className="section-content">
                {editing ? (
                  <input
                    type="text"
                    name="education"
                    value={userData.education}
                    onChange={handleInputChange}
                    className="form-control"
                    placeholder="Educational background"
                  />
                ) : (
                  <p>{userData.education || "Education information not provided"}</p>
                )}
              </div>
            </div>

            <div className="content-section">
              <h3><i className="fas fa-language"></i> Languages</h3>
              <div className="section-content">
                {editing ? (
                  <input
                    type="text"
                    name="languages"
                    value={userData.languages}
                    onChange={handleInputChange}
                    className="form-control"
                    placeholder="Languages spoken"
                  />
                ) : (
                  <p>{userData.languages || "Language information not provided"}</p>
                )}
              </div>
            </div>

            <div className="content-section">
              <h3><i className="fas fa-star"></i> Interests</h3>
              <div className="section-content">
                {editing ? (
                  <input
                    type="text"
                    name="interests"
                    value={userData.interests}
                    onChange={handleInputChange}
                    className="form-control"
                    placeholder="Professional interests"
                  />
                ) : (
                  <p>{userData.interests || "Interests not specified"}</p>
                )}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'contact' && (
          <div className="tab-content">
            <div className="content-section">
              <h3><i className="fas fa-envelope"></i> Contact Details</h3>
              <div className="contact-grid">
                <div className="contact-item">
                  <i className="fas fa-envelope"></i>
                  <div>
                    <label>Email</label>
                    <p>{userData.email}</p>
                  </div>
                </div>
                <div className="contact-item">
                  <i className="fas fa-phone"></i>
                  <div>
                    <label>Phone Number</label>
                    {editing ? (
                      <input
                        type="tel"
                        name="contactNo"
                        value={userData.contactNo}
                        onChange={handleInputChange}
                        className="form-control"
                        placeholder="Enter phone number"
                      />
                    ) : (
                      <p>{userData.contactNo || "Not provided"}</p>
                    )}
                  </div>
                </div>
                <div className="contact-item">
                  <i className="fas fa-calendar"></i>
                  <div>
                    <label>Date of Birth</label>
                    <p>{userData.dateOfBirth}</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="content-section">
              <h3><i className="fas fa-map-marker-alt"></i> Address</h3>
              <div className="address-grid">
                <div className="form-group">
                  <label>Street Address</label>
                  {editing ? (
                    <input
                      type="text"
                      name="streetAddress"
                      value={userData.streetAddress}
                      onChange={handleInputChange}
                      className="form-control"
                      placeholder="Enter street address"
                    />
                  ) : (
                    <p>{userData.streetAddress || "Not provided"}</p>
                  )}
                </div>
                <div className="form-group">
                  <label>Barangay</label>
                  {editing ? (
                    <input
                      type="text"
                      name="barangay"
                      value={userData.barangay}
                      onChange={handleInputChange}
                      className="form-control"
                      placeholder="Enter barangay"
                    />
                  ) : (
                    <p>{userData.barangay || "Not provided"}</p>
                  )}
                </div>
                <div className="form-group">
                  <label>City/Municipality</label>
                  {editing ? (
                    <input
                      type="text"
                      name="cityMunicipality"
                      value={userData.cityMunicipality}
                      onChange={handleInputChange}
                      className="form-control"
                      placeholder="Enter city/municipality"
                    />
                  ) : (
                    <p>{userData.cityMunicipality || "Not provided"}</p>
                  )}
                </div>
                <div className="form-group">
                  <label>Province</label>
                  {editing ? (
                    <input
                      type="text"
                      name="province"
                      value={userData.province}
                      onChange={handleInputChange}
                      className="form-control"
                      placeholder="Enter province"
                    />
                  ) : (
                    <p>{userData.province || "Not provided"}</p>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'professional' && (
          <div className="tab-content">
            <div className="content-section">
              <h3><i className="fas fa-graduation-cap"></i> Professional Details</h3>
              <div className="professional-grid">
                <div className="form-group">
                  <label>Qualification</label>
                  {editing ? (
                    <input
                      type="text"
                      name="qualification"
                      value={userData.qualification}
                      onChange={handleInputChange}
                      className="form-control"
                      placeholder="Enter your qualification"
                    />
                  ) : (
                    <p>{userData.qualification || "Not specified"}</p>
                  )}
                </div>
                <div className="form-group">
                  <label>Work Place</label>
                  {editing ? (
                    <input
                      type="text"
                      name="workPlace"
                      value={userData.workPlace}
                      onChange={handleInputChange}
                      className="form-control"
                      placeholder="Enter your workplace"
                    />
                  ) : (
                    <p>{userData.workPlace || "Not specified"}</p>
                  )}
                </div>
                <div className="form-group">
                  <label>School</label>
                  {editing ? (
                    <input
                      type="text"
                      name="school"
                      value={userData.school}
                      onChange={handleInputChange}
                      className="form-control"
                      placeholder="Enter your school"
                    />
                  ) : (
                    <p>{userData.school || "Not specified"}</p>
                  )}
                </div>
                <div className="form-group">
                  <label>Role</label>
                  <p className="role-display">{userData.role || "Teacher"}</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default UserProfile;
