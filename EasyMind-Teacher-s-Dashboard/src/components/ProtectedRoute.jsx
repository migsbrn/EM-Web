import React, { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { auth, db } from '../firebase';
import { onAuthStateChanged, getIdTokenResult } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';

const ProtectedRoute = ({ requiredRole, requiredStatus, redirectPath = '/', children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(null);
  const [isAuthorized, setIsAuthorized] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        console.log('ProtectedRoute - User authenticated:', user.uid, user.email);
        try {
          const idTokenResult = await getIdTokenResult(user, true);
          console.log('ProtectedRoute - Token claims:', idTokenResult.claims);
          const role = idTokenResult.claims?.role || null;

          setIsAuthenticated(true);

          if (role === requiredRole || !requiredRole) {
            if (requiredStatus) {
              const userDocRef = doc(db, 'teacherRequests', user.uid);
              console.log('ProtectedRoute - Fetching teacher doc for UID:', user.uid);
              const userDoc = await getDoc(userDocRef);
              if (userDoc.exists()) {
                const teacherData = userDoc.data();
                console.log('ProtectedRoute - Teacher Doc Data:', teacherData);
                const status = teacherData.status;
                if (status === requiredStatus) {
                  setIsAuthorized(true);
                } else {
                  setError(`Teacher account status is ${status}, but ${requiredStatus} is required.`);
                  setIsAuthorized(false);
                }
              } else {
                setError(`Teacher request document does not exist for UID: ${user.uid}`);
                setIsAuthorized(false);
              }
            } else {
              setIsAuthorized(true);
            }
          } else {
            setError(`Access denied: Role ${role} does not match required role ${requiredRole}.`);
            setIsAuthorized(false);
          }
        } catch (err) {
          console.error('ProtectedRoute - Authorization error:', err);
          setError('Authorization error: ' + (err.message || 'Unknown error'));
          setIsAuthorized(false);
        }
      } else {
        console.log('ProtectedRoute - No user is authenticated');
        setIsAuthenticated(false);
        setIsAuthorized(false);
      }
      setIsLoading(false);
    });

    return () => unsubscribe && unsubscribe();
  }, [requiredRole, requiredStatus]);

  if (isLoading || isAuthenticated === null || isAuthorized === null) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated || !isAuthorized) {
    console.log('ProtectedRoute - Redirecting due to:', error);
    return <Navigate to={redirectPath} replace state={{ error }} />;
  }

  return children;
};

export default ProtectedRoute;