# AquaFeedy - Smart IoT Fish Feeder App

## Overview
AquaFeedy is a Flutter-based mobile application designed to control an IoT fish feeder system. It allows users to remotely manage feeding, automate schedules, and monitor device status in real-time.

## Features
- Remote feeding control
- Automated feeding schedule
- Real-time device status (online, RSSI, IP)
- Command execution tracking
- Firebase integration (Firestore & Authentication)

## Tech Stack
- Flutter
- Firebase (Firestore, Auth)
- IoT Device (ESP32)
- REST API

## Architecture
- Users collection
- Feeders collection
  - Commands (history & execution)
  - Schedules (automation)
  - Status (real-time monitoring)

## Setup
1. Clone the repository
2. Run:
   flutter pub get
3. Run app:
   flutter run

## Note
Sensitive files such as Firebase configuration and API keys are excluded for security reasons.