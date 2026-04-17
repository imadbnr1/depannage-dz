# 🚗 Depannage DZ – Real-Time Towing & Roadside Assistance App

A modern mobile application built with **Flutter** and **Firebase** that connects customers with nearby towing/service providers and enables **real-time GPS tracking** of missions.

---

## 🚀 Overview

Depannage DZ allows users to request roadside assistance and track providers live on the map. Providers receive missions, navigate to customers, and manage the entire service lifecycle directly from the app.

This project evolved from a demo into a **real GPS-based tracking system** using live device location.

---

## ✨ Features

### 👤 Customer Side
- Request roadside assistance (towing, battery, tire, etc.)
- Select service details and destination
- Track provider in real-time on the map
- Call or chat with provider
- View estimated distance, duration, and price
- Cancel request
- Rate provider after mission

---

### 🚚 Provider Side
- Receive nearby service requests
- Accept or reject missions
- Share live GPS location
- Navigate to customer location
- Manage mission lifecycle:
  - Accepted → On the way → Arrived → In service → Completed
- Call and chat with customer
- Rate customer after mission

---

### 📍 Real-Time Tracking
- Powered by Geolocator (real GPS)
- Provider location updates continuously
- Customer sees live movement on the map
- Automatic arrival detection based on distance

---

### 🔥 Backend (Firebase)
- Firebase Authentication
- Cloud Firestore (requests, providers, tracking)
- Firebase Storage
- Firebase Messaging (notifications ready)

---

## 🛠️ Tech Stack

- Flutter
- Firebase (Auth, Firestore, Storage, Messaging)
- Geolocator
- Flutter Map (OpenStreetMap)
- LatLong2
- URL Launcher

---

## 📱 Getting Started

### 1. Clone the repository

git clone https://github.com/imadbnr1/depannage-dz.git
cd depannage-dz

### 2. Install dependencies

flutter pub get

### 3. Run the app

flutter run

⚠️ Important:
Use a real Android or iOS device for testing GPS tracking.
Chrome/web does NOT support full real-time tracking behavior.

---

## ⚙️ Required Permissions

### Android
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- ACCESS_BACKGROUND_LOCATION
- FOREGROUND_SERVICE_LOCATION
- INTERNET
- POST_NOTIFICATIONS

### iOS
- Location When In Use permission

---

## 🧪 Testing Real Tracking

1. Use two devices:
   - Device 1 → Customer
   - Device 2 → Provider

2. Flow:
   - Customer creates request
   - Provider accepts
   - Provider moves physically
   - Customer sees live movement

---

## 📊 Project Status

### ✅ Implemented
- Real GPS live tracking
- Firebase real-time sync
- Provider assignment system
- Full mission lifecycle
- Call & chat features
- Rating system

### 🚧 In Progress
- Real route navigation
- Geocoding addresses
- Payment integration
- Push notifications
- Background tracking optimization

---

## 👨‍💻 Author

Imad Bnr  
https://github.com/imadbnr1

---

## 📄 License

This project is for educational and development purposes.
