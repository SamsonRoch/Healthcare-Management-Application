# Healthcare Management App
## Project Structure

```
healthcare_management_app/
├── android/            # Android-specific files
├── ios/                # iOS-specific files
├── lib/                # Dart source code
│   ├── config/         # Configuration files
│   ├── core/           # Core functionality
│   ├── data/           # Data layer
│   │   ├── models/     # Data models
│   │   ├── providers/  # Data providers
│   │   └── repositories/ # Repositories
│   ├── services/       # Services
│   ├── ui/             # UI components
│   │   ├── screens/    # App screens
│   │   ├── widgets/    # Reusable widgets
│   │   └── theme/      # App theme
│   └── main.dart       # Entry point
├── server/             # NodeJs source code
├── test/               # Test files
└── pubspec.yaml        # Dependencies
```

## Setup Instructions

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   a. Create a new Firebase project:
      - Go to the Firebase Console (https://console.firebase.google.com/)
      - Click "Add project"
      - Enter your project name and follow the setup wizard
   
   b. Configure Android app:
      - In Firebase Console, click "Add app" and select Android
      - Use package name from android/app/build.gradle
      - Download google-services.json
      - Place it in android/app/
      - Add the Firebase SDK to build.gradle files:
        * In android/build.gradle, add to buildscript dependencies:
          ```
          classpath 'com.google.gms:google-services:4.3.15'
          ```
        * In android/app/build.gradle, add at the bottom:
          ```
          apply plugin: 'com.google.gms.google-services'
          ```
   
   c. Configure iOS app:
      - In Firebase Console, click "Add app" and select iOS
      - Use Bundle ID from ios/Runner.xcodeproj/project.pbxproj
      - Download GoogleService-Info.plist
      - Place it in ios/Runner/
      - Open ios/Runner.xcworkspace in Xcode
      - Add the file to the Runner target

   d. Install FlutterFire CLI:
      ```bash
      dart pub global activate flutterfire_cli
      ```

   e. Configure Firebase for Flutter:
      ```bash
      flutterfire configure
      ```
      This will create the firebase_options.dart file with proper configuration

4. Run the app with `flutter run`

## Dependencies

- Flutter SDK
- Firebase (Authentication, Firestore)
- SQLite for local storage
- Provider for state management
- Get_it for dependency injection
- Nodejs for server
