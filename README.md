# Expo Manager Booth System

Expo Manager Booth System is a Flutter-based mobile application developed as part of the **ISB26603 – Mobile and Ubiquitous Computing** course.  
The application provides a centralized platform for managing exhibitions and booth application workflows using a role-based system for **Exhibitors** and **Administrators**, supported by Firebase services.

---

## Project Overview

The purpose of this project is to design and develop a mobile application that simplifies exhibition management and booth booking processes.  
The system enables exhibitors to browse exhibitions and apply for booths, while administrators manage exhibitions and approve or reject applications through a real-time database.

Key objectives include:
- Role-based access control
- Real-time data synchronization
- Persistent user sessions
- Mobile-friendly user interface

---

## Features

- User authentication using Firebase Authentication
- Exhibition browsing and details view
- Booth application submission workflow
- Application approval and management (Admin)
- Real-time data updates using Cloud Firestore
- Persistent login using local storage
- Date and time formatting for better readability

---

## Technology Stack

- **Framework:** Flutter (Android)
- **Language:** Dart
- **Backend Services:** Firebase  
  - Firebase Authentication  
  - Cloud Firestore  
- **Local Storage:** Shared Preferences  

---

## Branching Strategy

This repository follows a simple and maintainable Git branching strategy:

- **main**
  - Contains stable, tested, and runnable code
  - Used for final submission and presentation

- **development** (if applicable)
  - Used for feature development and testing before merging into `main`

All final features were merged into the `main` branch to ensure application stability before submission.

---

## ⚙️ Installation & Setup

Follow the steps below to run the project locally.

### Steps Below

### 1. Clone the repository
git clone https://github.com/akagami27/mobileapp-expomanager.git
cd expo_manager_booth_new


### 2.Install dependencies
flutter pub get

### 3.Firebase Configuration
Ensure the following are correctly set up:

-firebase_options.dart is present

-Firebase Authentication is enabled

-Cloud Firestore is enabled

-The project is linked to the correct Firebase project

### 4.Run the application
flutter run


### Flutter Version & Dependencies

Flutter SDK

Flutter SDK: >=3.0.0 <4.0.0

Dart SDK: >=3.0.0




