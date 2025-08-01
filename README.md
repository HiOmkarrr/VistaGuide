# VistaGuide

## Overview

VistaGuide is a cross-platform mobile application developed as a final year BTech project. It aims to provide users with a comprehensive guide to explore landmarks, events, and destinations in various cities. The application is built using Flutter, enabling deployment to Android, iOS, Web, and Desktop platforms from a single codebase.

## Project Structure

The project follows a modular structure to ensure maintainability and scalability. Key directories and files include:

-   `android/`: Contains Android-specific configuration files, build scripts, and resources.
-   `ios/`: Contains iOS-specific configuration files, build scripts, and resources.
-   `lib/`: Contains the main Dart source code for the Flutter application.
    -   `core/`: Houses core functionalities such as navigation and theming.
        -   `navigation/`: Defines the app's routing logic and navigation paths.
        -   `theme/`: Defines the app's color scheme, text styles, and overall theme.
    -   `features/`: Contains modules for different features of the application.
        -   `emergency_reporting/`: Manages emergency contact information and reporting functionalities.
        -   `event_alerts/`: Provides information about local events and allows users to filter them.
        -   `home/`: Implements the main home screen with quick access options and destination recommendations.
        -   `landmark_recognition/`: Integrates camera functionality for recognizing landmarks and providing related information.
        -   `profile/`: Manages user profiles and settings.
    -   `main.dart`: The entry point of the Flutter application.
    -   `shared/`: Includes reusable widgets and components.
        -   `widgets/`: Custom widgets like `CustomAppBar`, `CustomButton`, and `CustomSearchBar`.
-   `assets/`: Stores static assets such as images and models.
-   `pubspec.yaml`: Lists project dependencies and metadata.
-   `README.md`: Provides an overview of the project (this file).

## Packages and Dependencies

The project leverages the following key Flutter packages:

-   **cupertino_icons**: Provides iOS-style icons.
-   **google_maps_flutter**: Enables integration of Google Maps.
-   **image_picker**: Allows users to select images from their device's gallery or camera.
-   **http**: Used for making HTTP requests to external APIs.
-   **provider**: Manages the application's state using the Provider pattern.
-   **shared_preferences**: Provides a persistent storage solution for user preferences.
-   **camera**: Enables access to the device's camera.

Additional dependencies are listed in the `pubspec.yaml` file. To install all dependencies, run `flutter pub get` in the project root.

## Getting Started

1.  Clone the repository.
2.  Ensure Flutter is installed and configured on your machine.
3.  Run `flutter pub get` to install dependencies.
4.  Run `flutter run` to launch the application on a connected device or emulator.

## Contributing

Contributions are welcome! Please follow these steps:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Commit your changes with descriptive commit messages.
4.  Push your changes to your fork.
5.  Submit a pull request.