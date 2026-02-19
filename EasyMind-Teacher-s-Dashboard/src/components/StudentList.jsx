import { useState, useEffect } from "react";
import { db, auth } from "../firebase";
import {
  collection,
  addDoc,
  query,
  orderBy,
  onSnapshot,
  doc,
  updateDoc,
  deleteDoc,
  getDoc,
  serverTimestamp,
  getDocs,
  where
} from "firebase/firestore";
import "../styles/StudentList.css";
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import "bootstrap/dist/css/bootstrap.min.css";

// Define the complete list of support needs for the select dropdown
const ALL_SUPPORT_NEEDS = [
  "Autism Spectrum Disorder",
  "Intellectual Disability",
];

const StudentList = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [students, setStudents] = useState([]);
  const [studentProgress, setStudentProgress] = useState({});
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showEditConfirmModal, setShowEditConfirmModal] = useState(false);
  const [surname, setSurname] = useState("");
  const [firstName, setFirstName] = useState("");
  const [middleName, setMiddleName] = useState("");
  const [nickname, setNickname] = useState("");
  // Initial state now includes both 'Autism Spectrum Disorder' and 'Intellectual Disability' for better demonstration, 
  // but a single empty array `[]` might be more appropriate if all are optional. 
  // Sticking to one default for non-multi-select, or `[]` for multi-select.
  const [supportNeeds, setSupportNeeds] = useState(["Autism Spectrum Disorder"]); 
  const [profileImage, setProfileImage] = useState(null);
  const [previewImage, setPreviewImage] = useState(null);
  const [error, setError] = useState(null);
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [pendingEditData, setPendingEditData] = useState(null);

  const fetchStudentProgress = async () => {
    try {
      const progressData = {};
      
      const userStatsQuery = query(collection(db, 'userStats'));
      const userStatsSnapshot = await getDocs(userStatsQuery);
      
      userStatsSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.nickname) {
          progressData[data.nickname] = {
            totalXP: data.totalXP || 0,
            level: data.currentLevel || 1,
            streakDays: data.streakDays || 0,
            lastActivity: data.lastActivity || null
          };
        }
      });

      const assessmentQuery = query(collection(db, 'adaptiveAssessmentResults'));
      const assessmentSnapshot = await getDocs(assessmentQuery);
      
      assessmentSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.nickname) {
          if (!progressData[data.nickname]) {
            progressData[data.nickname] = {
              totalXP: 0,
              level: 1,
              streakDays: 0,
              lastActivity: null,
              assessments: []
            };
          }
          
          if (!progressData[data.nickname].assessments) {
            progressData[data.nickname].assessments = [];
          }
          
          progressData[data.nickname].assessments.push({
            assessmentType: data.assessmentType,
            performance: data.performance || 0,
            correctAnswers: data.correctAnswers || 0,
            totalQuestions: data.totalQuestions || 0,
            timestamp: data.timestamp
          });
        }
      });

      const lessonQuery = query(collection(db, 'lessonRetention'));
      const lessonSnapshot = await getDocs(lessonQuery);
      
      lessonSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.nickname) {
          if (!progressData[data.nickname]) {
            progressData[data.nickname] = {
              totalXP: 0,
              level: 1,
              streakDays: 0,
              lastActivity: null,
              assessments: [],
              lessons: []
            };
          }
          
          if (!progressData[data.nickname].lessons) {
            progressData[data.nickname].lessons = [];
          }
          
          progressData[data.nickname].lessons.push({
            moduleName: data.moduleName,
            lessonType: data.lessonType,
            score: data.score || 0,
            totalQuestions: data.totalQuestions || 0,
            passed: data.passed || false,
            completedAt: data.completedAt
          });
        }
      });

      try {
        const gameVisitQuery = query(collection(db, 'visitTracking'), where('itemType', '==', 'game'));
        const gameVisitSnapshot = await getDocs(gameVisitQuery);
        
        gameVisitSnapshot.forEach(doc => {
          const data = doc.data();
          if (data.nickname) {
            if (!progressData[data.nickname]) {
              progressData[data.nickname] = {
                totalXP: 0,
                level: 1,
                streakDays: 0,
                lastActivity: null,
                assessments: [],
                lessons: [],
                games: []
              };
            }
            
            if (!progressData[data.nickname].games) {
              progressData[data.nickname].games = [];
            }
            
            progressData[data.nickname].games.push({
              gameType: data.itemName || 'Unknown Game',
              visitedAt: data.visitedAt,
              moduleName: data.moduleName || 'Unknown Module'
            });
          }
        });
      } catch (gameError) {
        console.log('Game visits not available yet:', gameError);
      }
      
      setStudentProgress(progressData);
    } catch (error) {
      console.error('Error fetching student progress:', error);
    }
  };

  useEffect(() => {
    const teacherId = auth.currentUser?.uid;
    
    if (!teacherId) {
      setError("No authenticated teacher found");
      return;
    }

    // UPDATED QUERY: Filter by createdBy and order by createdAt descending
    const q = query(
      collection(db, "students"), 
      where("createdBy", "==", teacherId),
      orderBy("createdAt", "desc")
    );
    
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const studentData = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setStudents(studentData);
      },
      (error) => {
        setError("Failed to fetch students: " + error.message);
      }
    );
    
    fetchStudentProgress();
    
    return () => unsubscribe();
  }, []);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (!file.type.startsWith('image/')) {
        setError('Please select a valid image file');
        return;
      }
      
      if (file.size > 5 * 1024 * 1024) {
        setError('Image size should be less than 5MB');
        return;
      }

      setProfileImage(file);
      
      const reader = new FileReader();
      reader.onload = (e) => {
        setPreviewImage(e.target.result);
      };
      reader.readAsDataURL(file);
      setError(null);
    }
  };

  const handleSupportNeedsChange = (e) => {
    const { options } = e.target;
    const selectedValues = [];
    for (let i = 0; i < options.length; i++) {
      if (options[i].selected) {
        selectedValues.push(options[i].value);
      }
    }
    setSupportNeeds(selectedValues);
  };

  const convertToBase64 = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result);
      reader.onerror = error => reject(error);
    });
  };

  const generateUID = async () => {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, "0");
    const prefix = `${year}${month}`;

    const studentDocs = students.filter((student) =>
      (student.uid || "").startsWith(prefix)
    );
    if (studentDocs.length === 0) return `${prefix}001`;

    const counters = studentDocs.map((doc) =>
      parseInt((doc.uid || "").slice(-3))
    );
    const maxCounter = Math.max(...counters);
    const newCounter = String(maxCounter + 1).padStart(3, "0");
    return `${prefix}${newCounter}`;
  };

  const getTeacherName = async (teacherId) => {
    try {
      const teacherDocRef = doc(db, "teacherRequests", teacherId);
      const teacherDoc = await getDoc(teacherDocRef);
      if (teacherDoc.exists()) {
        const teacherData = teacherDoc.data();
        return (
          `${teacherData.firstName || ""} ${
            teacherData.lastName || ""
          }`.trim() || "Unknown Teacher"
        );
      }
      return "Unknown Teacher";
    } catch (error) {
      console.error("Error fetching teacher name:", error);
      return "Unknown Teacher";
    }
  };

  const handleAddStudent = async (e) => {
    e.preventDefault();
    if (!surname || !firstName || !nickname || supportNeeds.length === 0) {
      setError("Please fill all required fields: Surname, First Name, Nickname, and Support Needs are required");
      return;
    }

    const nicknameRegex = /^[a-zA-Z0-9]+$/;
    if (!nicknameRegex.test(nickname)) {
      setError("Nickname must contain only letters and numbers (no spaces or special characters)");
      return;
    }

    // Check if nickname already exists FOR THIS TEACHER
    const existingStudent = students.find(student => 
      student.nickname && student.nickname.toLowerCase() === nickname.toLowerCase()
    );
    if (existingStudent) {
      setError("A student with this nickname already exists. Please choose a different nickname.");
      return;
    }

    setError(null);
    try {
      const uid = await generateUID();
      const teacherId = auth.currentUser?.uid;
      if (!teacherId) throw new Error("No authenticated teacher");
      const teacherName = await getTeacherName(teacherId);
      await addDoc(collection(db, "students"), {
        surname,
        firstName,
        middleName,
        nickname,
        supportNeeds, // Uses the array from state
        uid,
        profileImage: profileImage ? await convertToBase64(profileImage) : null,
        createdBy: teacherId,
        createdAt: serverTimestamp(),
      });

      await addDoc(collection(db, "logs"), {
        teacherId,
        teacherName,
        activityDescription: `Added student: ${firstName} ${surname}`,
        createdAt: serverTimestamp(),
      });

      setSurname("");
      setFirstName("");
      setMiddleName("");
      setNickname("");
      setSupportNeeds(["Autism Spectrum Disorder"]); // Reset to a default value
      setProfileImage(null);
      setPreviewImage(null);
      setShowAddModal(false);
    } catch (error) {
      console.error("Add student error:", error);
      setError("Failed to add student: " + error.message);
    }
  };

  const handleEditStudent = async (e) => {
    e.preventDefault();
    if (!surname || !firstName || !nickname || supportNeeds.length === 0) {
      setError("Please fill all required fields");
      return;
    }

    // Check if nickname already exists FOR THIS TEACHER but is NOT the current student
    const existingStudent = students.find(student => 
      student.id !== selectedStudent.id && 
      student.nickname && student.nickname.toLowerCase() === nickname.toLowerCase()
    );
    if (existingStudent) {
      setError("A different student with this nickname already exists. Please choose a different nickname.");
      return;
    }

    setError(null);

    const hasChanges =
      surname !== selectedStudent.surname ||
      firstName !== selectedStudent.firstName ||
      middleName !== selectedStudent.middleName ||
      nickname !== selectedStudent.nickname ||
      profileImage !== null ||
      JSON.stringify(supportNeeds.sort()) !==
        JSON.stringify((selectedStudent.supportNeeds || ["Autism Spectrum Disorder"]).sort());

    if (!hasChanges) {
      setSurname("");
      setFirstName("");
      setMiddleName("");
      setNickname("");
      setSupportNeeds(["Autism Spectrum Disorder"]);
      setShowEditModal(false);
      setSelectedStudent(null);
      return;
    }

    setPendingEditData({
      surname,
      firstName,
      middleName,
      nickname,
      supportNeeds,
      profileImage: profileImage ? await convertToBase64(profileImage) : null,
    });
    setShowEditConfirmModal(true);
  };

  const confirmEditStudent = async () => {
    try {
      const teacherId = auth.currentUser?.uid;
      if (!teacherId) throw new Error("No authenticated teacher");
      const teacherName = await getTeacherName(teacherId);
      await updateDoc(doc(db, "students", selectedStudent.id), {
        surname: pendingEditData.surname,
        firstName: pendingEditData.firstName,
        middleName: pendingEditData.middleName,
        nickname: pendingEditData.nickname,
        supportNeeds: pendingEditData.supportNeeds,
        profileImage: pendingEditData.profileImage || selectedStudent.profileImage, // Keep old image if no new one provided
      });

      await addDoc(collection(db, "logs"), {
        teacherId,
        teacherName,
        activityDescription: `Edited Student Information for ${pendingEditData.firstName} ${pendingEditData.surname}`,
        createdAt: serverTimestamp(),
      });

      setSurname("");
      setFirstName("");
      setMiddleName("");
      setNickname("");
      setSupportNeeds(["Autism Spectrum Disorder"]);
      setProfileImage(null);
      setPreviewImage(null);
      setShowEditModal(false);
      setShowEditConfirmModal(false);
      setSelectedStudent(null);
      setPendingEditData(null);
    } catch (error) {
      console.error("Edit student error:", error);
      setError("Failed to edit student: " + error.message);
    }
  };

  const handleDeleteStudent = async () => {
    try {
      const teacherId = auth.currentUser?.uid;
      if (!teacherId) throw new Error("No authenticated teacher");
      const teacherName = await getTeacherName(teacherId);
      await deleteDoc(doc(db, "students", selectedStudent.id));

      await addDoc(collection(db, "logs"), {
        teacherId,
        teacherName,
        activityDescription: `Deleted student: ${selectedStudent.firstName} ${selectedStudent.surname}`,
        createdAt: serverTimestamp(),
      });

      setShowDeleteModal(false);
      setSelectedStudent(null);
    } catch (error) {
      console.error("Delete student error:", error);
      setError("Failed to delete student: " + error.message);
    }
  };

  const filteredStudents = students
    .filter((student) => {
      const searchLower = searchTerm.toLowerCase();
      return (
        (student.firstName || "").toLowerCase().includes(searchLower) ||
        (student.middleName || "").toLowerCase().includes(searchLower) ||
        (student.surname || "").toLowerCase().includes(searchLower) ||
        (student.uid || "").includes(searchTerm) ||
        (student.nickname || "").toLowerCase().includes(searchLower)
      );
    })
    .sort((a, b) => {
      const nameA = `${a.firstName || ""} ${a.middleName || ""} ${
        a.surname || ""
      }`.toLowerCase();
      const nameB = `${b.firstName || ""} ${b.middleName || ""} ${
        b.surname || ""
      }`.toLowerCase();
      return nameA.localeCompare(nameB);
    });

  return (
    <div className="container py-4">
      <div className="sl-page-header mb-4">
        <div className="d-flex justify-content-between align-items-center">
          <div>
            <h1 className="sl-page-title">
              <i className="fas fa-graduation-cap me-3"></i>
              Student Management
            </h1>
            <p className="sl-page-subtitle">
              Manage student profiles and track academic progress
            </p>
          </div>
          <button
            className="btn btn-primary sl-btn-add-student"
            onClick={() => {
              setSurname(""); setFirstName(""); setMiddleName(""); 
              setNickname(""); setSupportNeeds(["Autism Spectrum Disorder"]); // Reset defaults on modal open
              setProfileImage(null); setPreviewImage(null); setError(null); 
              setShowAddModal(true);
            }}
          >
            <i className="fas fa-plus me-2"></i>
            Add Student
          </button>
        </div>
        
        <div className="sl-search-stats-bar mt-4">
          <div className="row align-items-center">
            <div className="col-md-8">
              <div className="sl-search-container">
                <i className="fas fa-search sl-search-icon"></i>
                <input
                  type="text"
                  className="form-control sl-search-input"
                  placeholder="Search students by name, nickname, or UID..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{ paddingLeft: '2.5rem' }} 
                />
              </div>
            </div>
            <div className="col-md-4">
              <div className="sl-stats-container justify-content-end">
                <div className="sl-stat-item">
                  <span className="sl-stat-number">{filteredStudents.length}</span>
                  <span className="sl-stat-label">Total Students</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div className="alert alert-danger" role="alert">
          {error}
        </div>
      )}

      {/* Add Student Modal */}
      <div
        className={`modal fade ${showAddModal ? "show d-block" : ""}`}
        tabIndex="-1"
        style={{
          backgroundColor: showAddModal ? "rgba(0,0,0,0.5)" : "transparent",
        }}
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">Add New Student</h5>
              <button
                type="button"
                className="btn-close"
                onClick={() => setShowAddModal(false)}
              ></button>
            </div>
            <form onSubmit={handleAddStudent}>
              <div className="modal-body">
                <div className="mb-3">
                  <label htmlFor="addSurname" className="form-label">
                    Surname <span style={{ color: "red" }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="addSurname"
                    value={surname}
                    onChange={(e) => setSurname(e.target.value)}
                    required
                  />
                </div>
                <div className="mb-3">
                  <label htmlFor="addFirstName" className="form-label">
                    First Name <span style={{ color: "red" }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="addFirstName"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    required
                  />
                </div>
                <div className="mb-3">
                  <label htmlFor="addMiddleName" className="form-label">
                    Middle Name
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="addMiddleName"
                    value={middleName}
                    onChange={(e) => setMiddleName(e.target.value)}
                  />
                </div>
                <div className="mb-3">
                  <label htmlFor="addNickname" className="form-label">
                    Nickname <span style={{ color: "red" }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="addNickname"
                    value={nickname}
                    onChange={(e) => setNickname(e.target.value)}
                    required
                  />
                </div>
                {/* UPDATED: Changed from readOnly input to a multi-select dropdown */}
                <div className="mb-3">
                  <label htmlFor="addSupportNeeds" className="form-label">
                    Support Needs <span style={{ color: "red" }}>*</span>
                  </label>
                  <select
                    multiple 
                    className="form-select"
                    id="addSupportNeeds"
                    value={supportNeeds}
                    onChange={handleSupportNeedsChange}
                    required
                  >
                    {ALL_SUPPORT_NEEDS.map((need) => (
                      <option key={need} value={need}>
                        {need}
                      </option>
                    ))}
                  </select>
                  <small className="form-text text-muted">Hold Ctrl/Cmd to select multiple options.</small>
                </div>
                <div className="mb-3">
                  <label htmlFor="addProfileImage" className="form-label">
                    Profile Image (Optional)
                  </label>
                  <input
                    type="file"
                    className="form-control"
                    id="addProfileImage"
                    accept="image/*"
                    onChange={handleImageChange}
                  />
                  {previewImage && (
                    <div className="mt-2">
                      <img 
                        src={previewImage} 
                        alt="Preview" 
                        className="sl-image-preview"
                      />
                    </div>
                  )}
                </div>
              </div>
              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowAddModal(false)}
                >
                  Close
                </button>
                <button type="submit" className="btn btn-primary">
                  Add Student
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      {/* Edit Student Modal */}
      <div
        className={`modal fade ${showEditModal ? "show d-block" : ""}`}
        tabIndex="-1"
        style={{
          backgroundColor: showEditModal ? "rgba(0,0,0,0.5)" : "transparent",
        }}
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">Edit Student</h5>
              <button
                type="button"
                className="btn-close"
                onClick={() => setShowEditModal(false)}
              ></button>
            </div>
            <form onSubmit={handleEditStudent}>
              <div className="modal-body">
                <div className="mb-3">
                  <label htmlFor="editSurname" className="form-label">
                    Surname <span style={{ color: "red" }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="editSurname"
                    value={surname}
                    onChange={(e) => setSurname(e.target.value)}
                    required
                  />
                </div>
                <div className="mb-3">
                  <label htmlFor="editFirstName" className="form-label">
                    First Name <span style={{ color: "red" }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="editFirstName"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    required
                  />
                </div>
                <div className="mb-3">
                  <label htmlFor="editMiddleName" className="form-label">
                    Middle Name
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="editMiddleName"
                    value={middleName}
                    onChange={(e) => setMiddleName(e.target.value)}
                  />
                </div>
                <div className="mb-3">
                  <label htmlFor="editNickname" className="form-label">
                    Nickname <span style={{ color: "red" }}>*</span>
                  </label>
                  <input
                    type="text"
                    className="form-control"
                    id="editNickname"
                    value={nickname}
                    onChange={(e) => setNickname(e.target.value)}
                    required
                  />
                </div>
                {/* UPDATED: Changed from readOnly input to a multi-select dropdown */}
                <div className="mb-3">
                  <label htmlFor="editSupportNeeds" className="form-label">
                    Support Needs <span style={{ color: "red" }}>*</span>
                  </label>
                  <select
                    multiple 
                    className="form-select"
                    id="editSupportNeeds"
                    value={supportNeeds}
                    onChange={handleSupportNeedsChange}
                    required
                  >
                    {ALL_SUPPORT_NEEDS.map((need) => (
                      <option key={need} value={need}>
                        {need}
                      </option>
                    ))}
                  </select>
                  <small className="form-text text-muted">Hold Ctrl/Cmd to select multiple options.</small>
                </div>
                <div className="mb-3">
                  <label htmlFor="editProfileImage" className="form-label">
                    Profile Image (Optional)
                  </label>
                  <input
                    type="file"
                    className="form-control"
                    id="editProfileImage"
                    accept="image/*"
                    onChange={handleImageChange}
                  />
                  {previewImage && (
                    <div className="mt-2">
                      <img 
                        src={previewImage} 
                        alt="Preview" 
                        className="sl-image-preview"
                      />
                    </div>
                  )}
                  {selectedStudent?.profileImage && !previewImage && (
                    <div className="mt-2">
                      <p className="text-muted small">Current image:</p>
                      <img 
                        src={selectedStudent.profileImage} 
                        alt="Current" 
                        className="sl-image-preview"
                      />
                    </div>
                  )}
                </div>
              </div>
              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowEditModal(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      {/* Confirm Edit Modal and Delete Modal (unchanged) */}
      <div
        className={`modal fade ${showEditConfirmModal ? "show d-block" : ""}`}
        tabIndex="-1"
        style={{
          backgroundColor: showEditConfirmModal
            ? "rgba(0,0,0,0.5)"
            : "transparent",
        }}
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">Confirm Edit</h5>
              <button
                type="button"
                className="btn-close"
                onClick={() => setShowEditConfirmModal(false)}
              ></button>
            </div>
            <div className="modal-body">
              Are you sure you want to apply these changes?
            </div>
            <div className="modal-footer">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => setShowEditConfirmModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={confirmEditStudent}
              >
                Confirm
              </button>
            </div>
          </div>
        </div>
      </div>

      <div
        className={`modal fade ${showDeleteModal ? "show d-block" : ""}`}
        tabIndex="-1"
        style={{
          backgroundColor: showDeleteModal ? "rgba(0,0,0,0.5)" : "transparent",
        }}
      >
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">Confirm Delete</h5>
              <button
                type="button"
                className="btn-close"
                onClick={() => setShowDeleteModal(false)}
              ></button>
            </div>
            <div className="modal-body">
              Are you sure you want to delete{" "}
              {`${selectedStudent?.firstName || ""} ${
                selectedStudent?.middleName || ""
              } ${selectedStudent?.surname || ""}`}
              ?
            </div>
            <div className="modal-footer">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => setShowDeleteModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="btn btn-danger"
                onClick={handleDeleteStudent}
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="sl-students-section">
        {filteredStudents.length === 0 ? (
          <div className="sl-empty-state">
            <div className="sl-empty-icon">
              <i className="fas fa-user-graduate"></i>
            </div>
            <h3 className="sl-empty-title">No Students Found</h3>
            <p className="sl-empty-message">
              {searchTerm ? 
                "No students match your search criteria. Try adjusting your search terms." :
                "You haven't added any students yet. Click 'Add Student' to get started."
              }
            </p>
          </div>
        ) : (
          <div className="row">
            {filteredStudents.map((student) => (
              <div key={student.id} className="col-12 col-lg-6 col-xl-4 mb-4">
                <div className="sl-student-card">
                  <div className="sl-student-header">
                    <div className="sl-student-avatar">
                      {student.profileImage ? (
                        <img 
                          src={student.profileImage} 
                          alt={`${student.firstName} ${student.surname}`}
                          className="sl-profile-image"
                        />
                      ) : (
                        <div className="sl-profile-placeholder">
                          <i className="fas fa-user-circle"></i>
                        </div>
                      )}
                    </div>
                    <div className="sl-student-info">
                      <h5 className="sl-student-name">
                        {`${student.firstName || ""} ${student.middleName || ""} ${
                          student.surname || ""
                        }`.trim()}
                      </h5>
                      <p className="sl-student-uid">
                        <i className="fas fa-id-card me-1"></i>
                        UID: {student.uid || "N/A"}
                      </p>
                    </div>
                    <div className="sl-student-actions">
                      <button
                        className="student-list-edit-btn"
                        onClick={() => {
                          setSelectedStudent(student);
                          setSurname(student.surname || "");
                          setFirstName(student.firstName || "");
                          setMiddleName(student.middleName || "");
                          setNickname(student.nickname || "");
                          // Set the state to the student's saved support needs (or default if missing)
                          setSupportNeeds(student.supportNeeds || ["Autism Spectrum Disorder"]); 
                          setProfileImage(null);
                          setPreviewImage(null);
                          setShowEditModal(true);
                        }}
                      >
                        Edit
                      </button>
                      <button
                        className="student-list-delete-btn"
                        onClick={() => {
                          setSelectedStudent(student);
                          setShowDeleteModal(true);
                        }}
                      >
                        Delete
                      </button>
                    </div>
                  </div>

                  <div className="sl-student-details">
                    <div className="sl-detail-item">
                      <span className="sl-detail-label">
                        <i className="fas fa-user-tag me-2"></i>
                        Nickname
                      </span>
                      <span className="sl-detail-value">{student.nickname || "N/A"}</span>
                    </div>
                    
                    <div className="sl-detail-item">
                      <span className="sl-detail-label">
                        <i className="fas fa-heart me-2"></i>
                        Support Needs
                      </span>
                      <span className="sl-detail-value">
                        {(student.supportNeeds || []).join(", ") || "N/A"}
                      </span>
                    </div>
                    
                    {studentProgress[student.nickname] && (
                      <div className="sl-progress-section">
                        <div className="sl-progress-header">
                          <h6 className="sl-progress-title">
                            <i className="fas fa-chart-line me-2"></i>
                            Progress Overview
                          </h6>
                        </div>
                        
                        <div className="sl-progress-stats">
                          <div className="sl-progress-item">
                            <div className="sl-progress-label">Level</div>
                            <div className="sl-progress-value sl-level-badge">
                              {studentProgress[student.nickname].level}
                            </div>
                          </div>
                          
                          <div className="sl-progress-item">
                            <div className="sl-progress-label">Total XP</div>
                            <div className="sl-progress-value sl-xp-badge">
                              {studentProgress[student.nickname].totalXP}
                            </div>
                          </div>
                          
                          {studentProgress[student.nickname].streakDays > 0 && (
                            <div className="sl-progress-item">
                              <div className="sl-progress-label">Streak</div>
                              <div className="sl-progress-value sl-streak-badge">
                                {studentProgress[student.nickname].streakDays} days
                              </div>
                            </div>
                          )}
                        </div>
                        
                        {studentProgress[student.nickname].assessments && 
                         studentProgress[student.nickname].assessments.length > 0 && (
                          <div className="sl-assessments-section">
                            <h6 className="sl-assessments-title">
                              <i className="fas fa-clipboard-check me-2"></i>
                              Recent Assessments
                            </h6>
                            <div className="sl-assessments-list">
                              {studentProgress[student.nickname].assessments.slice(0, 2).map((assessment, index) => (
                                <div key={index} className="sl-assessment-item">
                                  <span className="sl-assessment-type">{assessment.assessmentType}</span>
                                  <span className={`sl-assessment-score ${
                                    assessment.performance >= 0.7 ? 'sl-score-good' : 'sl-score-needs-improvement'
                                  }`}>
                                    {Math.round(assessment.performance * 100)}%
                                  </span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default StudentList;