import * as admin from 'firebase-admin';
import { config } from './env';

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: config.firebase.projectId,
    clientEmail: config.firebase.clientEmail,
    privateKey: config.firebase.privateKey,
  }),
});

export const firebaseAuth = admin.auth();
export const firebaseApp = admin;
