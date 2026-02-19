const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Configure email transporter using environment variables
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().gmail.email,
    pass: functions.config().gmail.password,
  },
});

exports.sendVerificationCode = functions.https.onCall(async (data, context) => {
  // Require authentication to prevent unauthorized calls
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated."
    );
  }

  const { email, code } = data;

  if (!email || !code) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email and code are required."
    );
  }

  const mailOptions = {
    from: '"EducateMinds Admin" <migsbrin10@gmail.com>',
    to: email,
    subject: "Your Admin Verification Code",
    text: `Your verification code is: ${code}. It expires in 10 minutes. If you did not attempt to sign in, please contact support.`,
    html: `
      <p>Your verification code is: <strong>${code}</strong>.</p>
      <p>It expires in 10 minutes.</p>
      <p>If you did not attempt to sign in, please contact support.</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true, message: "Verification code sent." };
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send verification code email."
    );
  }
});
