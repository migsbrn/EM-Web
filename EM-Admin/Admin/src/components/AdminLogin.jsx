import React, { useState, useEffect } from "react";
import { auth, db } from "/src/firebase.js";
import {
  signInWithEmailAndPassword,
  onAuthStateChanged,
  sendPasswordResetEmail,
} from "firebase/auth";
import {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  serverTimestamp,
} from "firebase/firestore";
import { useNavigate } from "react-router-dom";
import "../styles/AdminLogin.css";
import Illustration from "../assets/EM-logo.jpg";

// Simulate sending verification code email (replace with Cloud Functions in production)
const sendVerificationCodeEmail = async (email, code) => {
  console.log(`Verification code ${code} sent to ${email}`);
};

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [showVerifyCode, setShowVerifyCode] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [verificationCode, setVerificationCode] = useState("");
  const [userUid, setUserUid] = useState(null);
  const [failedAttempts, setFailedAttempts] = useState(0);

  const navigate = useNavigate();

  const generateVerificationCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        try {
          const idTokenResult = await user.getIdTokenResult(true);
          const role = idTokenResult.claims?.role || null;

          if (role === "admin") {
            const userDocRef = doc(db, "users", user.uid);
            const userDoc = await getDoc(userDocRef);
            if (userDoc.exists() && userDoc.data().verified) {
              navigate("/dashboard");
            } else {
              setShowVerifyCode(true);
              setUserUid(user.uid);
            }
          } else if (role === "teacher") {
            const teacherDocRef = doc(db, "teacherRequests", user.uid);
            const teacherDoc = await getDoc(teacherDocRef);
            if (
              teacherDoc.exists() &&
              teacherDoc.data().status === "Approved"
            ) {
              navigate("/teacher-dashboard");
            } else {
              await auth.signOut();
              setError("Your account is not yet approved by an admin.");
            }
          } else {
            await auth.signOut();
            setError("Access denied: Invalid role.");
          }
        } catch (err) {
          setError(err.message || "An error occurred during authentication.");
        }
      }
    });

    return () => unsubscribe();
  }, [navigate]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const userCredential = await signInWithEmailAndPassword(
        auth,
        email,
        password,
      );
      const user = userCredential.user;

      const idTokenResult = await user.getIdTokenResult(true);
      const role = idTokenResult.claims?.role;

      if (role !== "admin") {
        await auth.signOut();
        throw new Error("Access denied: Only admins can sign in at this time.");
      }

      setFailedAttempts(0);

      const code = generateVerificationCode();
      const userDocRef = doc(db, "users", user.uid);
      await setDoc(
        userDocRef,
        {
          email: user.email,
          verificationCode: code,
          codeTimestamp: serverTimestamp(),
          verified: false,
          createdAt: serverTimestamp(),
        },
        { merge: true },
      );

      await sendVerificationCodeEmail(user.email, code);

      setShowVerifyCode(true);
      setUserUid(user.uid);
      setSuccess("A verification code has been sent to your email.");
    } catch (err) {
      const newFailedAttempts = failedAttempts + 1;
      setFailedAttempts(newFailedAttempts);

      if (newFailedAttempts >= 4) {
        setError(
          "You have exceeded the maximum login attempts. Please reset your password.",
        );
        setShowForgotPassword(true);
        setEmail("");
        setPassword("");
      } else if (err.code === "auth/invalid-credential") {
        setError(
          `Invalid admin credentials. ${4 - newFailedAttempts} attempt(s) remaining.`,
        );
      } else {
        setError(err.message);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyCode = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const userDocRef = doc(db, "users", userUid);
      const userDoc = await getDoc(userDocRef);
      if (!userDoc.exists()) {
        throw new Error("User not found.");
      }

      const { verificationCode: storedCode, codeTimestamp } = userDoc.data();
      const now = new Date();
      const codeAge = codeTimestamp
        ? (now - codeTimestamp.toDate()) / 1000 / 60
        : Infinity;

      if (codeAge > 10) {
        throw new Error("Verification code has expired. Please sign in again.");
      }

      if (storedCode !== verificationCode) {
        throw new Error("Invalid verification code.");
      }

      await updateDoc(userDocRef, {
        verified: true,
        verificationCode: null,
        codeTimestamp: null,
      });

      navigate("/dashboard");
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleForgotPassword = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);
    setSuccess(null);

    try {
      await sendPasswordResetEmail(auth, resetEmail);
      setSuccess("Password reset email sent. Please check your inbox.");
      setShowForgotPassword(false);
      setResetEmail("");
      setFailedAttempts(0);
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const resetToLogin = () => {
    setShowForgotPassword(false);
    setShowVerifyCode(false);
    setError(null);
    setSuccess(null);
    setResetEmail("");
    setVerificationCode("");
  };

  /* ── helpers ── */
  const formTitle = showForgotPassword
    ? "Reset Password"
    : showVerifyCode
      ? "Verify Code"
      : "Welcome back";

  const formEyebrow = showForgotPassword
    ? "Account Recovery"
    : showVerifyCode
      ? "Two-Step Verification"
      : "Admin Portal";

  const formSubtitle = showForgotPassword
    ? "Enter your email and we'll send a reset link."
    : showVerifyCode
      ? "Enter the 6-digit code sent to your email."
      : "Sign in to manage your admin dashboard.";

  return (
    <div className="login-container">
      {/* ── Left: Illustration Panel ── */}
      <div className="illustration">
        <div className="illustration-inner">
          <img
            src={Illustration}
            alt="EasyMind Logo"
            className="illustration-image"
            onError={(e) => {
              e.target.style.display = "none";
            }}
          />
          <div className="illustration-tagline">
            <h2>EasyMind Admin</h2>
            <p>
              Manage teachers, students, and platform settings from one place.
            </p>
          </div>
        </div>

        {/* Decorative dots */}
        <div className="illustration-dots">
          {Array.from({ length: 15 }).map((_, i) => (
            <span key={i} />
          ))}
        </div>
      </div>

      {/* ── Right: Form Panel ── */}
      <div className="login-form">
        <div className="login-form-inner">
          {/* Header */}
          <div className="form-header">
            <span className="form-eyebrow">{formEyebrow}</span>
            <h2>{formTitle}</h2>
            <p className="form-subtitle">{formSubtitle}</p>
          </div>

          {/* ── Sign In Form ── */}
          {!showForgotPassword && !showVerifyCode && (
            <form onSubmit={handleLogin} autoComplete="off">
              <div className="input-group">
                <span className="icon">
                  <i className="fas fa-envelope"></i>
                </span>
                <input
                  type="email"
                  name="email-12345"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email address"
                  required
                  disabled={isLoading}
                  autoComplete="new-email"
                />
              </div>

              <div className="input-group">
                <span className="icon">
                  <i className="fas fa-lock"></i>
                </span>
                <input
                  type="password"
                  name="password-12345"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Password"
                  required
                  disabled={isLoading}
                  autoComplete="new-password"
                />
              </div>

              <button
                type="button"
                className="forgot-password-link"
                onClick={() => setShowForgotPassword(true)}
              >
                Forgot password?
              </button>

              {error && <p className="error">{error}</p>}
              {success && <p className="success">{success}</p>}

              <button
                type="submit"
                className="login-button"
                disabled={isLoading}
              >
                {isLoading ? "Signing in…" : "Sign In"}
              </button>
            </form>
          )}

          {/* ── Forgot Password Form ── */}
          {showForgotPassword && (
            <form onSubmit={handleForgotPassword} autoComplete="off">
              <div className="input-group">
                <span className="icon">
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

              {error && <p className="error">{error}</p>}
              {success && <p className="success">{success}</p>}

              <button
                type="submit"
                className="login-button"
                disabled={isLoading}
              >
                {isLoading ? "Sending…" : "Send Reset Email"}
              </button>
            </form>
          )}

          {/* ── Verify Code Form ── */}
          {showVerifyCode && (
            <form onSubmit={handleVerifyCode} autoComplete="off">
              <div className="input-group">
                <span className="icon">
                  <i className="fas fa-key"></i>
                </span>
                <input
                  type="text"
                  value={verificationCode}
                  onChange={(e) => setVerificationCode(e.target.value)}
                  placeholder="6-digit code"
                  required
                  disabled={isLoading}
                  autoComplete="off"
                  maxLength="6"
                />
              </div>

              {error && <p className="error">{error}</p>}
              {success && <p className="success">{success}</p>}

              <button
                type="submit"
                className="login-button"
                disabled={isLoading}
              >
                {isLoading ? "Verifying…" : "Verify Code"}
              </button>

              <button
                type="button"
                className="back-to-login-link"
                onClick={async () => {
                  await auth.signOut();
                  resetToLogin();
                }}
              >
                ← Back to Sign In
              </button>
            </form>
          )}

          {/* ── Toggle link ── */}
          {(showForgotPassword || showVerifyCode) && (
            <div className="signup-login-toggle">
              <p>
                Remember your password?
                <span onClick={resetToLogin}>Sign In</span>
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Login;
