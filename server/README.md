# Healthcare Management App - Backend Server

This is the backend server for the Healthcare Management App. It provides secure API endpoints for administrative operations like creating staff accounts without affecting the current authentication state in the Flutter app.

## Features

- Create staff accounts (doctors, nurses, receptionists) without auto-login
- Update staff account status (active/inactive)
- Role-based access control using Firebase custom claims

## Setup Instructions

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Firebase project with Authentication and Firestore enabled

### Firebase Setup

1. Go to your [Firebase Console](https://console.firebase.google.com/)
2. Navigate to Project Settings > Service Accounts
3. Click "Generate new private key"
4. Save the JSON file as `serviceAccountKey.json` in the server directory

### Installation

```bash
# Install dependencies
npm install

# Start the server
npm start

# For development with auto-reload
npm run dev
```

### Configuration

The server runs on port 3000 by default. You can change this by setting the PORT environment variable.

## API Endpoints

### Health Check
- **GET /** - Check if the server is running

### Create Staff Member
- **POST /api/create-staff**
  - Body: `{ email, password, name, role, phoneNumber, specialty, licenseNumber }`
  - Role must be one of: doctor, nurse, receptionist, admin

### Update Staff Status
- **PATCH /api/staff/:userId/status**
  - Body: `{ isActive }`

## Integration with Flutter App

The Flutter app communicates with this backend server using the `ApiService` class. Make sure to update the base URL in the ApiService to match your server's address.

## Security Considerations

- This server should be deployed with HTTPS in production
- Add authentication middleware for API endpoints in production
- Store the serviceAccountKey.json securely and never commit it to version control
