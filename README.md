# 🐟 AquaFeedy - Smart IoT Fish Feeder App

## 🚀 Overview

AquaFeedy is a Flutter-based mobile application built to control and monitor an IoT fish feeder system in real-time.
The app allows users to automate feeding schedules, monitor device status, and control feeding remotely using Firebase as the backend.

This project demonstrates a real-world implementation of **IoT + Mobile App integration**.

---

## ✨ Key Features

* 📱 **Remote Feeding Control**
  Manually trigger feeding from anywhere.

* ⏰ **Automated Scheduling**
  Set feeding schedules based on time and days.

* 📡 **Real-time Device Monitoring**
  View device status including online state, RSSI signal, and IP address.

* 📊 **Command History Tracking**
  Track all feeding commands and execution status.

* 🔐 **User Authentication**
  Secure login system using Firebase Authentication.

* 🤖 **AI Chat Assistant**
  Integrated chatbot feature to assist users (Gemini/OpenAI-based).

---

## 🛠 Tech Stack

* **Frontend:** Flutter
* **Backend:** Firebase (Firestore & Authentication)
* **IoT Device:** ESP32
* **Communication:** REST API / HTTP
* **AI Integration:** Gemini API / OpenAI API

---

## 🧠 System Architecture

```
Users
 └── feeders
      ├── commands   → feeding history & execution logs
      ├── schedules  → automated feeding system
      └── status     → real-time device monitoring
```

---

## 📸 Screenshots

```
assets/screenshots/login.png
assets/screenshots/register.png
assets/screenshots/forgetpassword.png
assets/screenshots/home.png
assets/screenshots/schedule.png
assets/screenshots/schedule_2.png
assets/screenshots/chatbot.png
assets/screenshots/setting.png

```

---

## ⚙️ Installation & Setup

1. Clone the repository:

```
git clone https://github.com/USERNAME/aquafeedy-flutter.git
```

2. Install dependencies:

```
flutter pub get
```

3. Run the app:

```
flutter run
```

---

## 🔐 Security Note

Sensitive data such as API keys and Firebase configuration files are excluded using `.gitignore`.

---

## 💼 Project Value

This project showcases:

* Real-world IoT + Mobile integration
* Firebase-based backend system
* Real-time data handling
* Clean Flutter application structure
* API integration and automation logic

---

## 👨‍💻 Author

**Muhammad Gymnastiar**
Informatics Student | Flutter & IoT Developer
