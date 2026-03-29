import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyCi6JGy9HCg5J9bMlXaFrDMi_dGjEwO0yI',
  authDomain: 'rumora-c0d7b.firebaseapp.com',
  projectId: 'rumora-c0d7b',
  storageBucket: 'rumora-c0d7b.firebasestorage.app',
  messagingSenderId: '836167337536',
  appId: '1:836167337536:web:c5ad438efe7e335b0ec1a5',
  measurementId: 'G-WL4R4N5E18',
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
