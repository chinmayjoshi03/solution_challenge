// services/firebaseAdmin.ts
import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Ensure you have the correct relative path for your service account JSON file
const serviceAccount = require('./solution-challenge-704ed-firebase-adminsdk-fbsvc-f60341b406.json');

// Initialize the default Firebase Admin app if it hasn't been initialized already
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

export const db = admin.firestore();
export default admin;
