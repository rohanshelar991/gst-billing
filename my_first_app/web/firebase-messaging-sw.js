/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAb1V35iCoe2QE6UkSiDBbP0STqqFlie5I',
  appId: '1:1045577090721:web:d3d5927569e571e159d2e0',
  messagingSenderId: '1045577090721',
  projectId: 'rohandb-58168',
  authDomain: 'rohandb-58168.firebaseapp.com',
  storageBucket: 'rohandb-58168.firebasestorage.app',
  measurementId: 'G-RMJDH0HRJC',
});

firebase.messaging();
