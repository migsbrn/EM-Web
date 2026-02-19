// TeacherLogin.jsx
import React, { useState, useEffect } from "react";
import { auth, db } from "../firebase";
import {
  signInWithEmailAndPassword,
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  signOut,
  sendEmailVerification,
} from "firebase/auth";
import {
  doc,
  setDoc,
  updateDoc,
  serverTimestamp,
  getDoc,
  addDoc,
  collection,
} from "firebase/firestore";
import { useNavigate } from "react-router-dom";
import "../styles/TeacherLogin.css";
import Illustration from "../assets/EM-logo.jpg";
import "bootstrap/dist/js/bootstrap.bundle.min.js";
import "bootstrap/dist/css/bootstrap.min.css";

// Define the list of SPED-related qualifications
const SPEDQualifications = [
  "Select Qualification *", // Placeholder
  "Bachelor of Science in Elementary Education (BSEEd)",
  "Bachelor of Science in Elementary Education major in Special Education (BSEEd-Sped)",
  "Bachelor of Science in Secondary Education (BSEd)",
  "Bachelor of Science in Secondary Education major in Special Education (BSEd-Sped)",
  "Bachelor of Science in Education (BSE)",
  "Bachelor of Science in Education major in Special Education (BSE-Sped)",
  "Master of Arts in Education major in Special Education (MAEd-Sped)",
  "Master of Arts in Teaching major in Special Education (MAT-Sped)",
  "PhD in Special Education",
  "Others",
];

// --- TermsAndConditionsModal (No changes) ---
const TermsAndConditionsModal = () => (
  <div
    className="modal fade"
    id="termsModal"
    tabIndex="-1"
    aria-labelledby="termsModalLabel"
    aria-hidden="true"
  >
    <div className="modal-dialog modal-dialog-scrollable modal-lg">
      <div className="modal-content">
        <div className="modal-header">
          <h5 className="modal-title" id="termsModalLabel">
            EasyMind Teacher Terms and Conditions
          </h5>
          <button
            type="button"
            className="btn-close"
            data-bs-dismiss="modal"
            aria-label="Close"
          ></button>
        </div>
        <div className="modal-body">
          <p>
            Welcome to EasyMind, a Special Education (SPED) teaching and
            learning platform. By registering an account as a Teacher, you agree
            to be bound by these Terms and Conditions. Please read them
            carefully.
          </p>

          <h4 className="mt-4">1. Teacher Account and Registration</h4>
          <ul>
            <li>
              <strong>Eligibility:</strong> You must be an officially qualified
              educator to register. By registering, you warrant that all
              information provided, including your qualifications, is true,
              accurate, and complete.
            </li>
            <li>
              <strong>Account Security:</strong> You are solely responsible for
              maintaining the confidentiality of your password and for all
              activities that occur under your account. You must immediately
              notify EasyMind of any unauthorized use.
            </li>
            <li>
              <strong>Account Status:</strong> Your access is conditional upon a
              review by an EasyMind administrator. You acknowledge that your
              account status will be "Pending" until an administrator verifies
              your details and sets your status to "Active". EasyMind reserves
              the right to refuse service or terminate accounts at its sole
              discretion.
            </li>
          </ul>

          <h4 className="mt-4">2. Intellectual Property Rights (IP)</h4>
          <ul>
            <li>
              <strong>EasyMind Content:</strong> All text, graphics, designs,
              educational materials, software, and content provided by EasyMind
              (the "Content") are the exclusive property of EasyMind or its
              licensors.
            </li>
            <li>
              <strong>License to Teacher:</strong> EasyMind grants you a
              non-exclusive, non-transferable, limited license to use the
              Content solely for the purpose of personal educational use within
              the EasyMind platform for your students.
            </li>
            <li>
              <strong>Restrictions:</strong> You may not copy, reproduce,
              modify, translate, transmit, publish, distribute, or create
              derivative works from the Content without EasyMind's express prior
              written authorization.
            </li>
            <li>
              <strong>User Content:</strong> Any content, data, or feedback you
              submit ("User Content") remains your property. However, by
              submitting it, you grant EasyMind a worldwide, perpetual,
              royalty-free license to use, reproduce, modify, and display the
              User Content to operate and improve the platform and its services.
            </li>
          </ul>

          <h4 className="mt-4">3. Acceptable Use and Teacher Conduct</h4>
          <ul>
            <li>
              You agree not to use the Service to:
              <ul>
                <li>
                  Upload, post, or transmit any content that is threatening,
                  harassing, abusive, defamatory, obscene, or illegal.
                </li>
                <li>Impersonate another person or entity.</li>
                <li>
                  Infringe upon the intellectual property, privacy, or publicity
                  rights of others.
                </li>
                <li>
                  Introduce viruses, worms, or any code of a destructive nature.
                </li>
                <li>
                  Engage in any activity that disrupts or interferes with the
                  security or proper functioning of the Service.
                </li>
              </ul>
            </li>
            <li>
              You must treat all students and other users of the platform with
              respect and follow all relevant laws and school policies regarding
              student data privacy and conduct.
            </li>
          </ul>

          <h4 className="mt-4">4. Privacy and Data Security</h4>
          <ul>
            <li>
              All personal information and student data collected is governed by
              the EasyMind **Privacy Policy**, which is incorporated into these
              Terms.
            </li>
            <li>
              EasyMind implements security measures to protect information, but
              you acknowledge that no system is 100% secure. You are responsible
              for ensuring that your use complies with all applicable privacy
              laws.
            </li>
          </ul>

          <h4 className="mt-4">5. Limitation of Liability and Disclaimer</h4>
          <ul>
            <li>
              The Service is provided on an "AS IS" and "AS AVAILABLE" basis
              without warranties of any kind. EasyMind does not warrant that the
              Service will be uninterrupted, secure, or error-free.
            </li>
            <li>
              EasyMind and its affiliates will not be liable for any direct,
              indirect, incidental, or consequential damages arising out of your
              use of the Service.
            </li>
            <li>
              You agree to indemnify and hold EasyMind harmless from any claims
              arising from your breach of these Terms or your use of the
              Service.
            </li>
          </ul>

          <h4 className="mt-4">6. Changes to Terms</h4>
          <p>
            EasyMind reserves the right to modify these Terms at any time. We
            will notify you of any material changes by posting the updated Terms
            on the website. Your continued use of the Service after such changes
            constitutes your acceptance of the new Terms.
          </p>
        </div>
        <div className="modal-footer">
          {/* Note: Using a button with existing professional back style */}
          <button
            type="button"
            className="t-back-step-button"
            style={{
              flex: "initial",
              width: "auto",
              padding: "0.75rem 1.5rem",
            }}
            data-bs-dismiss="modal"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  </div>
);
// ---------------------------------------------

const TeacherLogin = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showSignUp, setShowSignUp] = useState(false);
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [signUpStep, setSignUpStep] = useState(1);
  const [showPassword, setShowPassword] = useState(false);
  const [showSignUpPassword, setShowSignUpPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [signUpData, setSignUpData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    contactNo: "",
    qualification: SPEDQualifications[0], // Initialize with placeholder
    password: "",
    confirmPassword: "",
  });
  const [formErrors, setFormErrors] = useState({});
  const [justSignedUp, setJustSignedUp] = useState(false);
  const [hasAcceptedTerms, setHasAcceptedTerms] = useState(false); // STATE FOR TERMS

  const navigate = useNavigate();

  useEffect(() => {
    // Listen for auth state changes
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      // Don't run auth logic if we're on sign-up form
      if (showSignUp) {
        console.log(
          "TeacherLogin - Skipping auth check because on sign-up form"
        );
        return;
      }

      // Don't override success message if we just signed up
      if (justSignedUp) {
        console.log(
          "TeacherLogin - Skipping auth check because just signed up"
        );
        return;
      }

      if (user) {
        console.log("TeacherLogin - User authenticated:", user.uid, user.email);
        try {
          // Force token refresh
          await user.getIdToken(true);
          // Check if user exists in teacherRequests collection first
          const teacherDocRef = doc(db, "teacherRequests", user.uid);
          console.log("TeacherLogin - Fetching teacher doc for UID:", user.uid);
          const teacherDoc = await getDoc(teacherDocRef);

          if (teacherDoc.exists()) {
            const teacherData = teacherDoc.data();
            const role = teacherData.role;
            const status = teacherData.status;

            if (role === "teacher") {
              if (status === "Active") {
                console.log(
                  "TeacherLogin - Status is Active, navigating to /teacher-dashboard"
                );
                // Update lastLogin timestamp
                await updateDoc(teacherDocRef, {
                  lastLogin: serverTimestamp(),
                });
                console.log(
                  "TeacherLogin - Updated lastLogin for UID:",
                  user.uid
                );
                navigate("/teacher-dashboard");
              } else {
                console.log("TeacherLogin - Status is not Active:", status);
                setError(
                  "Your account is not yet active. Please wait for admin activation."
                );
                await signOut(auth);
              }
            } else {
              console.log("TeacherLogin - Role is not 'teacher':", role);
              setError(
                "Access denied: Only teachers can sign in to this portal. Please contact an admin to activate your account."
              );
              await signOut(auth);
            }
          } else {
            console.log(
              "TeacherLogin - Teacher document does not exist for UID:",
              user.uid
            );
            setError("Teacher request not found. Please contact an admin.");
            await signOut(auth);
          }
        } catch (err) {
          console.error("TeacherLogin - Authentication error:", err);
          setError(
            "Authentication failed: " + (err.message || "Unknown error")
          );
          await signOut(auth);
        }
      } else {
        console.log("TeacherLogin - No user is authenticated");
      }
    });

    return () => unsubscribe();
  }, [navigate, showSignUp, justSignedUp]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      console.log("TeacherLogin - Attempting login with email:", email);

      // Validate email format first
      if (!email || !email.includes("@")) {
        setError("Please enter a valid email address.");
        return;
      }

      const userCredential = await signInWithEmailAndPassword(
        auth,
        email,
        password
      );
      const user = userCredential.user;
      console.log("TeacherLogin - Login successful for UID:", user.uid);

      // Fetch teacher data to get name
      const teacherDocRef = doc(db, "teacherRequests", user.uid);
      const teacherDoc = await getDoc(teacherDocRef);
      if (teacherDoc.exists()) {
        const teacherData = teacherDoc.data();
        const teacherName = `${teacherData.firstName} ${teacherData.lastName}`;

        // Log the login event to logs
        await addDoc(collection(db, "logs"), {
          teacherId: user.uid,
          teacherName: teacherName,
          activityDescription: "Logged in",
          createdAt: serverTimestamp(),
        });
        console.log("TeacherLogin - Login event logged for:", teacherName);

        // Log the login event to teacherLogins
        await addDoc(collection(db, "teacherLogins"), {
          teacherId: user.uid,
          loginTime: serverTimestamp(),
        });
        console.log("TeacherLogin - Teacher login logged for UID:", user.uid);
      } else {
        throw new Error("Teacher document not found");
      }

      // Force token refresh immediately after login
      await user.getIdToken(true);
      console.log("TeacherLogin - Token refreshed after login");
    } catch (err) {
      console.error("TeacherLogin - Login error:", err);
      if (err.code === "auth/invalid-email") {
        setError("Please enter a valid email address.");
      } else if (err.code === "auth/user-not-found") {
        setError(
          "Account not found. Please sign up first or contact admin if you believe this is an error."
        );
      } else if (err.code === "auth/wrong-password") {
        setError("Incorrect password. Please try again.");
      } else if (err.code === "auth/invalid-credential") {
        setError(
          "Invalid credentials. Please check your email and password, or sign up if you're a new teacher."
        );
      } else if (err.code === "auth/too-many-requests") {
        setError("Too many failed attempts. Please try again later.");
      } else {
        setError("Login failed: " + err.message);
      }
    } finally {
      setIsLoading(false);
    }
  };

  // Debug function to check form completion
  const isStep1Complete = () => {
    // Check if qualification is not the placeholder
    const required = ["firstName", "lastName", "email", "contactNo"];
    const missing = required.filter((field) => !signUpData[field]?.trim());

    // Add validation for qualification dropdown specifically
    if (
      signUpData.qualification === SPEDQualifications[0] ||
      !signUpData.qualification
    ) {
      missing.push("qualification");
    }

    console.log("Step 1 validation check:", {
      missing,
      formData: signUpData,
      isComplete: missing.length === 0,
    });

    return missing.length === 0;
  };

  const handleNextStep = () => {
    console.log("Next button clicked, checking step 1 completion...");

    if (!isStep1Complete()) {
      console.log("Step 1 not complete, showing validation errors");
      const errors = validateForm();
      // Ensure we only show step 1 errors
      const step1Errors = Object.keys(errors).reduce((acc, key) => {
        if (
          [
            "firstName",
            "lastName",
            "email",
            "contactNo",
            "qualification",
          ].includes(key)
        ) {
          acc[key] = errors[key];
        }
        return acc;
      }, {});
      setFormErrors(step1Errors);
      setError("Please fill in all required fields before proceeding.");
      return;
    }

    console.log("Step 1 complete, proceeding to step 2");
    setFormErrors({});
    setError(null);
    setSignUpStep(2);
  };

  const validateForm = () => {
    const errors = {};
    if (!signUpData.firstName) errors.firstName = "First name is required";
    if (!signUpData.lastName) errors.lastName = "Last name is required";
    if (!signUpData.email) {
      errors.email = "Email is required";
    } else if (!/\S+@\S+\.\S+/.test(signUpData.email)) {
      errors.email = "Need valid email";
    }
    if (!signUpData.contactNo) {
      errors.contactNo = "Contact number is required";
    } else if (!/^\d{11}$/.test(signUpData.contactNo)) {
      errors.contactNo = "Contact number must be exactly 11 digits";
    }
    // Updated validation for dropdown
    if (
      !signUpData.qualification ||
      signUpData.qualification === SPEDQualifications[0]
    ) {
      errors.qualification = "Qualification is required";
    }
    if (!signUpData.password) errors.password = "Password is required";
    if (signUpData.password !== signUpData.confirmPassword) {
      errors.confirmPassword = "Passwords do not match";
    }
    // Terms validation
    if (signUpStep === 2 && !hasAcceptedTerms) {
      errors.terms = "Acceptance of Terms is required";
    }
    return errors;
  };

  const handleSignUpChange = (e) => {
    const { name, value } = e.target;
    if (name === "contactNo") {
      const numericValue = value.replace(/[^0-9]/g, "");
      setSignUpData({ ...signUpData, [name]: numericValue });
    } else {
      setSignUpData({ ...signUpData, [name]: value });
    }
    const errors = { ...formErrors };
    if (errors[name]) {
      delete errors[name];
      setFormErrors(errors);
    }
  };

  const handleSignUp = async (e) => {
    e.preventDefault();

    // Check terms acceptance first
    if (!hasAcceptedTerms) {
      setError(
        "❌ You must accept the Terms and Conditions to create an account."
      );
      setFormErrors({
        ...formErrors,
        terms: "Acceptance of Terms is required",
      });
      return;
    }

    const errors = validateForm();
    if (Object.keys(errors).length > 0) {
      setFormErrors(errors);
      // Filter out Step 1 errors if we are on Step 2
      const step2Errors = Object.keys(errors).filter(
        (key) =>
          key !== "firstName" &&
          key !== "lastName" &&
          key !== "email" &&
          key !== "contactNo" &&
          key !== "qualification"
      );
      if (step2Errors.length > 0) {
        setError(
          "❌ Please fix the errors in your credentials before proceeding."
        );
      }
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      console.log(
        "TeacherLogin - Starting sign-up process with email:",
        signUpData.email
      );

      // Step 1: Create Firebase Auth user
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        signUpData.email,
        signUpData.password
      );
      const user = userCredential.user;
      console.log("TeacherLogin - User authenticated, UID:", user.uid);

      // Step 2: Send email verification
      try {
        await sendEmailVerification(user);
        console.log("TeacherLogin - Verification email sent to:", user.email);
      } catch (emailError) {
        console.warn("TeacherLogin - Email verification failed:", emailError);
        // Continue with sign-up even if email verification fails
      }

      // Step 3: Prepare user data for Firestore
      const userData = {
        firstName: signUpData.firstName,
        lastName: signUpData.lastName,
        email: signUpData.email,
        contactNo: signUpData.contactNo,
        qualification: signUpData.qualification,
        profilePhoto: null,
        role: "teacher",
        status: "Pending",
        createdAt: serverTimestamp(),
      };

      console.log("TeacherLogin - Saving user data to Firestore:", userData);

      // Step 4: Save to Firestore (this should work with updated rules)
      await setDoc(doc(db, "teacherRequests", user.uid), userData);
      console.log(
        "TeacherLogin - User data saved successfully for UID:",
        user.uid
      );

      // Step 5: Verify the document was saved
      const savedDoc = await getDoc(doc(db, "teacherRequests", user.uid));
      if (!savedDoc.exists()) {
        throw new Error(
          "Failed to verify saved data in Firestore. Please try again."
        );
      }
      console.log("TeacherLogin - Verified saved data:", savedDoc.data());

      // Step 6: Sign out and show success message
      await signOut(auth);
      console.log("TeacherLogin - User signed out after sign-up.");

      // Show success message - Focus on email verification
      setError(
        "✅ Account created successfully! Please verify your email address. Check your inbox and click the verification link."
      );

      // Set flag to prevent auth useEffect from overriding this message
      setJustSignedUp(true);

      console.log(
        "TeacherLogin - Success message set:",
        "Account created successfully! Please verify your email address."
      );

      // Reset form
      setSignUpData({
        firstName: "",
        lastName: "",
        email: "",
        contactNo: "",
        qualification: SPEDQualifications[0],
        password: "",
        confirmPassword: "",
      });
      setSignUpStep(1);
      setFormErrors({});
      setHasAcceptedTerms(false); // Reset terms acceptance
    } catch (err) {
      console.error("TeacherLogin - Sign-up error:", {
        code: err.code,
        message: err.message,
        stack: err.stack,
        name: err.name,
      });

      // Provide user-friendly error messages
      let errorMessage = "❌ Sign-up failed. Please try again.";

      if (err.code === "auth/email-already-in-use") {
        errorMessage =
          "❌ This email is already registered. Please use a different email or try signing in.";
      } else if (err.code === "auth/weak-password") {
        errorMessage =
          "❌ Password is too weak. Please choose a stronger password.";
      } else if (err.code === "auth/invalid-email") {
        errorMessage = "❌ Please enter a valid email address.";
      } else if (err.code === "auth/operation-not-allowed") {
        errorMessage =
          "❌ Email/password accounts are not enabled. Please contact support.";
      } else if (err.code === "auth/network-request-failed") {
        errorMessage =
          "❌ Network error. Please check your internet connection and try again.";
      } else if (err.code === "permission-denied") {
        errorMessage =
          "❌ Permission denied. Please check your Firestore security rules.";
      } else if (err.message.includes("Failed to verify saved data")) {
        errorMessage =
          "❌ Account created but data verification failed. Please contact support.";
      } else if (err.message) {
        errorMessage = `❌ ${err.message}`;
      }

      setError(errorMessage);
    } finally {
      setIsLoading(false);
      console.log("TeacherLogin - Sign-up process completed.");
    }
  };

  const handleForgotPassword = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      await sendPasswordResetEmail(auth, resetEmail);
      setError("✅ Password reset email sent. Please check your inbox.");
      setShowForgotPassword(false);
      setResetEmail("");
    } catch (err) {
      setError("❌ " + err.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <div className="t-login-container">
        <div className="t-login-form">
          <div className="t-form-logo">
            <img
              src={Illustration}
              alt="Logo"
              className="t-illustration-image"
              onError={(e) => {
                e.target.style.display = "none";
                setError("Failed to load illustration.");
              }}
            />
          </div>
          <h2>
            {showSignUp
              ? "Register as Teacher"
              : showForgotPassword
              ? "Forgot Password"
              : "Sign In"}
          </h2>
          {!showSignUp && !showForgotPassword ? (
            <form onSubmit={handleLogin} autoComplete="off">
              <div className="t-input-group">
                <span className="t-icon">
                  <i className="fas fa-user"></i>
                </span>
                <input
                  type="email"
                  name="email-12345"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email"
                  required
                  disabled={isLoading}
                  autoComplete="new-email"
                />
              </div>
              <div className="t-input-group">
                <span className="t-icon">
                  <i className="fas fa-lock"></i>
                </span>
                {/* === Password Input Wrapper === */}
                <div className="t-password-input-wrapper">
                  <input
                    type={showPassword ? "text" : "password"}
                    name="password-12345"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Password"
                    required
                    disabled={isLoading}
                    autoComplete="new-password"
                  />
                  <span
                    className="t-password-toggle"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    <i
                      className={`fas ${
                        showPassword ? "fa-eye-slash" : "fa-eye"
                      }`}
                    ></i>
                  </span>
                </div>
                {/* ================================================= */}
              </div>
              <p
                className="t-forgot-password"
                onClick={() => setShowForgotPassword(true)}
                style={{
                  color: "#3d5d53",
                  cursor: "pointer",
                  textAlign: "right",
                  margin: "5px 0 1rem 0",
                  fontSize: "0.875rem",
                }}
              >
                Forgot Password?
              </p>

              {/* Authentication Flow Info */}
              <div
                style={{
                  background: "#f0f9ff",
                  border: "1px solid #0ea5e9",
                  borderRadius: "8px",
                  padding: "12px",
                  margin: "1rem 0",
                  fontSize: "0.85rem",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "8px",
                  }}
                >
                  <span style={{ marginRight: "8px" }}>ℹ️</span>
                  <strong style={{ color: "#0c4a6e" }}>
                    Authentication Flow
                  </strong>
                </div>
                <p
                  style={{ color: "#0c4a6e", margin: "0", fontSize: "0.8rem" }}
                >
                  <strong>New Teacher:</strong> Sign up → Verify email → Wait
                  for admin approval.
                  <br />
                  <strong>Existing Teacher:</strong> Sign in with your approved
                  credentials.
                  <br />
                  <strong>Sign-in Error:</strong> "Your account is not yet
                  active" only appears when signing in.
                </p>
              </div>

              {/* Conditional class applied here */}
              {error && (
                <p className={error.startsWith("✅") ? "t-success" : "t-error"}>
                  {error}
                </p>
              )}

              <button
                type="submit"
                className="t-login-button"
                disabled={isLoading}
              >
                {isLoading ? "Signing In..." : "SIGN IN"}
              </button>

              {/* Terms link for Sign-In page */}
              <div
                style={{
                  textAlign: "center",
                  marginTop: "1.5rem",
                  fontSize: "0.875rem",
                  color: "#64748b",
                }}
              >
                <a
                  href="#"
                  data-bs-toggle="modal"
                  data-bs-target="#termsModal"
                  style={{
                    color: "#4f46e5",
                    fontWeight: 600,
                    textDecoration: "none",
                  }}
                >
                  View Terms and Conditions
                </a>
              </div>
            </form>
          ) : showForgotPassword ? (
            <form onSubmit={handleForgotPassword} autoComplete="off">
              <div className="t-input-group">
                <span className="t-icon">
                  <i className="fas fa-envelope"></i>
                </span>
                <input
                  type="email"
                  value={resetEmail}
                  onChange={(e) => setResetEmail(e.target.value)}
                  placeholder="Enter your email"
                  required
                  disabled={isLoading}
                  autoComplete="new-email"
                />
              </div>
              {/* Conditional class applied here */}
              {error && (
                <p className={error.startsWith("✅") ? "t-success" : "t-error"}>
                  {error}
                </p>
              )}
              <button
                type="submit"
                className="t-login-button"
                disabled={isLoading}
              >
                {isLoading ? "Sending..." : "Send Reset Email"}
              </button>
              <p
                className="t-back-to-login"
                onClick={() => {
                  setShowForgotPassword(false);
                  setError(null);
                  setResetEmail("");
                }}
                style={{
                  color: "#3d5d53",
                  cursor: "pointer",
                  textAlign: "center",
                  marginTop: "10px",
                }}
              >
                Back to Sign In
              </p>
            </form>
          ) : (
            <form onSubmit={handleSignUp} autoComplete="off">
              {/* Step Indicator */}
              <div className="t-step-indicator">
                <div
                  className={`t-step ${signUpStep >= 1 ? "t-step-active" : ""}`}
                >
                  <span className="t-step-number">1</span>
                  <span className="t-step-label">Basic Info</span>
                </div>
                <div
                  className={`t-step ${signUpStep >= 2 ? "t-step-active" : ""}`}
                >
                  <span className="t-step-number">2</span>
                  <span className="t-step-label">Credentials</span>
                </div>
              </div>

              {/* Step 1: Basic Information */}
              {signUpStep === 1 && (
                <div className="t-step-content">
                  <h3 className="t-step-title">Basic Information</h3>
                  <p className="t-step-description">Tell us about yourself</p>

                  <div className="t-input-row">
                    <div className="t-input-group t-half-width">
                      <input
                        type="text"
                        name="firstName"
                        value={signUpData.firstName}
                        onChange={handleSignUpChange}
                        placeholder="First Name *"
                        required
                        disabled={isLoading}
                        autoComplete="given-name"
                      />
                      {formErrors.firstName && (
                        <p className="t-error">{formErrors.firstName}</p>
                      )}
                    </div>
                    <div className="t-input-group t-half-width">
                      <input
                        type="text"
                        name="lastName"
                        value={signUpData.lastName}
                        onChange={handleSignUpChange}
                        placeholder="Last Name *"
                        required
                        disabled={isLoading}
                        autoComplete="family-name"
                      />
                      {formErrors.lastName && (
                        <p className="t-error">{formErrors.lastName}</p>
                      )}
                    </div>
                  </div>

                  <div className="t-input-group">
                    <input
                      type="email"
                      name="email"
                      value={signUpData.email}
                      onChange={handleSignUpChange}
                      placeholder="E-mail Address *"
                      required
                      disabled={isLoading}
                      autoComplete="email"
                    />
                    {formErrors.email && (
                      <p className="t-error">{formErrors.email}</p>
                    )}
                  </div>

                  <div className="t-input-row">
                    <div className="t-input-group t-half-width">
                      <input
                        type="tel"
                        name="contactNo"
                        value={signUpData.contactNo}
                        onChange={handleSignUpChange}
                        placeholder="Contact No *"
                        required
                        disabled={isLoading}
                        maxLength="11"
                        autoComplete="tel"
                      />
                      {formErrors.contactNo && (
                        <p className="t-error">{formErrors.contactNo}</p>
                      )}
                    </div>
                    {/* Qualification dropdown */}
                    <div className="t-input-group t-half-width">
                      <select
                        name="qualification"
                        value={signUpData.qualification}
                        onChange={handleSignUpChange}
                        required
                        disabled={isLoading}
                        autoComplete="organization-title"
                      >
                        {SPEDQualifications.map((qual, index) => (
                          <option
                            key={index}
                            value={qual}
                            // Disable the placeholder option
                            disabled={index === 0}
                            // Hide the placeholder text if it's the selected value (for styling)
                            hidden={
                              index === 0 &&
                              signUpData.qualification === SPEDQualifications[0]
                            }
                          >
                            {qual}
                          </option>
                        ))}
                      </select>
                      {formErrors.qualification && (
                        <p className="t-error">{formErrors.qualification}</p>
                      )}
                    </div>
                    {/* End of Qualification dropdown */}
                  </div>

                  <button
                    type="button"
                    className="t-login-button"
                    onClick={handleNextStep}
                    disabled={isLoading}
                  >
                    Next Step →
                  </button>
                </div>
              )}

              {/* Step 2: Credentials */}
              {signUpStep === 2 && (
                <div className="t-step-content">
                  <h3 className="t-step-title">Create Password</h3>
                  <p className="t-step-description">Secure your account</p>

                  <div className="t-input-group">
                    <div className="t-password-input-wrapper">
                      <input
                        type={showSignUpPassword ? "text" : "password"}
                        name="password"
                        value={signUpData.password}
                        onChange={handleSignUpChange}
                        placeholder="Password *"
                        required
                        disabled={isLoading}
                        autoComplete="new-password"
                      />
                      <span
                        className="t-password-toggle"
                        onClick={() =>
                          setShowSignUpPassword(!showSignUpPassword)
                        }
                      >
                        <i
                          className={`fas ${
                            showSignUpPassword ? "fa-eye-slash" : "fa-eye"
                          }`}
                        ></i>
                      </span>
                    </div>
                    {formErrors.password && (
                      <p className="t-error">{formErrors.password}</p>
                    )}
                  </div>

                  <div className="t-input-group">
                    <div className="t-password-input-wrapper">
                      <input
                        type={showConfirmPassword ? "text" : "password"}
                        name="confirmPassword"
                        value={signUpData.confirmPassword}
                        onChange={handleSignUpChange}
                        placeholder="Confirm Password *"
                        required
                        disabled={isLoading}
                        autoComplete="new-password"
                      />
                      <span
                        className="t-password-toggle"
                        onClick={() =>
                          setShowConfirmPassword(!showConfirmPassword)
                        }
                      >
                        <i
                          className={`fas ${
                            showConfirmPassword ? "fa-eye-slash" : "fa-eye"
                          }`}
                        ></i>
                      </span>
                    </div>
                    {formErrors.confirmPassword && (
                      <p className="t-error">{formErrors.confirmPassword}</p>
                    )}
                  </div>

                  {/* --- FIX: Updated Checkbox Structure for Smaller/Cleaner Look --- */}
                  <div
                    style={{
                      marginBottom: "1rem",
                      textAlign: "left",
                      padding: "0 0.5rem",
                      width: "100%",
                    }}
                  >
                    <div className="form-check">
                      <input
                        className="form-check-input"
                        type="checkbox"
                        id="acceptTerms"
                        checked={hasAcceptedTerms}
                        onChange={(e) => {
                          setHasAcceptedTerms(e.target.checked);
                          if (e.target.checked)
                            setFormErrors({ ...formErrors, terms: undefined });
                        }}
                        disabled={isLoading}
                        style={{ marginTop: "0.35rem" }}
                      />
                      <label
                        className="form-check-label"
                        htmlFor="acceptTerms"
                        style={{
                          fontSize: "0.875rem",
                          fontWeight: 500,
                          color: "#374151",
                          marginLeft: "0.5rem", // Adjust distance from checkbox
                        }}
                      >
                        I agree to the EasyMind Terms and Conditions *
                      </label>
                      {/* Separate clickable button/link to open the modal */}
                      <a
                        href="#"
                        data-bs-toggle="modal"
                        data-bs-target="#termsModal"
                        style={{
                          color: "#4f46e5",
                          fontWeight: 600,
                          textDecoration: "none",
                          marginLeft: "0.5rem",
                          fontSize: "0.875rem",
                        }}
                      >
                        (View details)
                      </a>
                    </div>
                    {formErrors.terms && (
                      <p className="t-error">{formErrors.terms}</p>
                    )}
                  </div>
                  {/* ------------------------------------------- */}

                  <div className="t-step-navigation">
                    <button
                      type="button"
                      className="t-back-step-button"
                      onClick={() => setSignUpStep(1)}
                      disabled={isLoading}
                    >
                      ← Back
                    </button>
                    <button
                      type="submit"
                      className="t-login-button"
                      disabled={isLoading || !hasAcceptedTerms} // Disable if terms not accepted
                    >
                      {isLoading ? "Creating Account..." : "Create Account"}
                    </button>
                  </div>
                </div>
              )}

              {/* Conditional class applied here */}
              {error && (
                <p className={error.startsWith("✅") ? "t-success" : "t-error"}>
                  {error}
                </p>
              )}
            </form>
          )}
          <div className="t-signup-login-toggle">
            <p>
              {showSignUp
                ? "Have an account? "
                : showForgotPassword
                ? "Remember your password? "
                : "Don't have an account? "}
              <span
                onClick={() => {
                  setShowSignUp(!showSignUp);
                  setShowForgotPassword(false);
                  setError(null);
                  setResetEmail("");
                  // Clear sign-up form state and errors on toggle
                  setSignUpStep(1);
                  setFormErrors({});
                  setHasAcceptedTerms(false);
                }}
                style={{ color: "#3d5d53", cursor: "pointer" }}
              >
                {showSignUp
                  ? "Sign In"
                  : showForgotPassword
                  ? "Sign Up"
                  : "Sign Up"}
              </span>
            </p>
          </div>
        </div>
      </div>
      {/* --- ADD NEW MODAL COMPONENT OUTSIDE THE MAIN CONTAINER --- */}
      <TermsAndConditionsModal />
    </>
  );
};

export default TeacherLogin;
