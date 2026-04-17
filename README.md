# 🚗 Depannage DZ

A real-time roadside assistance platform built with **Flutter + Firebase**, enabling customers to request help and providers to respond with live tracking, routing, and mission management.

---

## ✨ Features

### 👤 Customer App
- Request roadside assistance (battery, tow, fuel, etc.)
- Real-time provider assignment
- Live tracking on map (Flutter Map + OSM)
- Route distance + ETA
- Call / chat with provider
- Rate completed missions

---

### 🚚 Provider App
- Receive nearby mission requests
- Accept / reject missions
- Live GPS tracking
- Turn-by-turn navigation (Google Maps / Waze)
- Mission lifecycle:
  - Accepted → On the way → Arrived → In service → Completed

---

### 🛠️ Admin Dashboard
- Real-time system overview
- Manage providers (approve / block / monitor)
- Monitor active requests
- Notifications & support configuration
- Analytics (missions, users, activity)

---

## 🧠 Core System

- 🔥 Firebase Auth (roles: customer / provider / admin)
- 📦 Firestore (requests, tracking, users, providers)
- 📍 Real GPS tracking
- 🗺️ Flutter Map (OpenStreetMap)
- 🛣️ OSRM Routing (real routes, ETA, distance)
- 🔔 Notification system (lifecycle events)

---

## 🔁 Dispatch Logic

- Nearest provider is selected
- If rejected → next provider
- If timeout → next provider
- Once accepted → request locked
- Tracking starts automatically

---

## 📊 Mission Lifecycle


---

## 🔒 Security

- Firestore security rules enforced
- Role-based access control
- Providers only access assigned missions
- Customers only access their own requests

---

## 📱 Supported Platforms

- Android ✅
- iOS ✅
- Web (basic support)

---

## 🚀 Project Status

### ✅ Completed
- Real dispatch system
- Real-time tracking
- Route calculation (OSRM)
- ETA & distance display
- Provider navigation (Google Maps / Waze)
- Admin dashboard
- Security rules

### 🔄 In Progress
- Push notifications (FCM full integration)
- Background tracking optimization
- Advanced analytics

---

## 📦 Tech Stack

- Flutter
- Firebase (Auth, Firestore)
- Flutter Map (OSM)
- OSRM Routing API
- Dart

---

## 🧪 Future Improvements

- Payment integration
- Support tickets system
- Provider earnings dashboard
- Smart dispatch (traffic-aware)
- Offline handling

---

## 👨‍💻 Author

Imad Benrouane

---

## 📌 Notes

This project evolved into a real production-ready system with scalable architecture and real-time features.