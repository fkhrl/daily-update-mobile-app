// firebase-messaging-sw.js
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAlRE3DokRheJytePJH7BSkTbz8qJA5_7Y",
  appId: "1:925566632947:web:73d69f019d92ffbf714886",
  messagingSenderId: "925566632947",
  projectId: "daily-update-app-2ff4c",
  storageBucket: "daily-update-app-2ff4c.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);
});
