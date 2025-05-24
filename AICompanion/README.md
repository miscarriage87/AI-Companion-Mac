# AI Companion App - Persistence Implementation

## Overview

This document outlines the implementation of persistence for the AI Companion macOS application. The persistence layer has been implemented using Core Data for storing conversations and messages, and UserDefaults for storing user preferences.

## Implemented Features

### 1. Core Data Model

- Created a Core Data model with the following entities:
  - `CDConversation`: Stores conversation data
  - `CDMessage`: Stores message data
  - `CDProvider`: Stores AI provider data
  - `CDModel`: Stores AI model data

- Established relationships between entities:
  - One-to-many relationship between conversations and messages
  - One-to-many relationship between providers and models
  - One-to-many relationship between providers and conversations
  - One-to-many relationship between providers and messages

### 2. PersistenceController

- Implemented a singleton `PersistenceController` class to manage the Core Data stack
- Added methods for saving, loading, and managing Core Data operations
- Created a preview instance for SwiftUI previews
- Implemented proper error handling for Core Data operations

### 3. UserDefaults Integration

- Enhanced `StorageService` to use UserDefaults for storing user preferences
- Implemented methods for saving and loading user preferences
- Added support for storing API keys securely

### 4. Automatic Saving

- Implemented periodic auto-saving using a timer (every 60 seconds)
- Added save points after important user actions
- Implemented save on app termination and when app resigns active

### 5. Data Migration

- Added support for data versioning and migration
- Implemented a framework for handling future data model changes

### 6. View Model Integration

- Updated `ChatViewModel`, `SidebarViewModel`, and `SettingsViewModel` to use the persistence layer
- Added notification handling for data changes
- Implemented proper cleanup in `deinit` methods

## File Structure

- `AICompanion.xcdatamodeld/`: Core Data model definition
- `Models/CoreDataModels.swift`: Core Data entity classes
- `Services/PersistenceController.swift`: Core Data stack management
- `Services/StorageService.swift`: Service for handling data persistence

## Usage

The persistence layer is automatically initialized when the app starts. Data is saved:

1. Periodically (every 60 seconds)
2. When the app is about to terminate
3. When the app resigns active
4. After important user actions (sending messages, changing settings, etc.)

## Future Enhancements

- Implement encryption for sensitive data
- Add support for iCloud sync
- Optimize Core Data fetch requests for better performance
- Implement more sophisticated data migration strategies
