# ArogyaSOS+

![ArogyaSOS+ Logo](https://via.placeholder.com/150) ArogyaSOS+ is a comprehensive emergency assistance mobile application built with Flutter. It aims to provide immediate help in critical situations by allowing users to quickly send SOS alerts, access emergency contacts, find nearby medical resources, and consult first-aid guides.

## Features

* **Emergency SOS Alert**: One-tap SOS button with a countdown to send automated SMS alerts to predefined emergency contacts, including current location and basic medical information.
* **Location Tracking**: Displays the user's current location (address and coordinates) to assist emergency services.
* **Quick Emergency Calls**: Direct calling functionality for crucial emergency numbers (e.g., Police, Ambulance).
* **Medicine Finder**: (Placeholder for future implementation) A dedicated section to help users locate medicines or pharmacies.
* **First Aid Guides**: Provides quick access to essential first aid instructions for common medical emergencies.
* **Profile Management**: Allows users to manage their personal and emergency contact details.
* **Intuitive Navigation**: Easy-to-use bottom navigation bar for seamless switching between app sections.

## Technologies Used

* **Flutter**: UI Toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
* **Dart**: Programming language used by Flutter.
* **`geolocator`**: For accessing device's geographic location.
* **`geocoding`**: For converting geographic coordinates into a human-readable address and vice-versa.
* **`url_launcher`**: For launching URLs (e.g., making phone calls, sending SMS).
* **`shared_preferences`**: For persisting simple key-value data locally (e.g., storing emergency contacts, profile details).

## Installation and Setup

Follow these steps to get a local copy of the project up and running on your machine.

### Prerequisites

* **Flutter SDK**: Ensure you have Flutter installed. Follow the official Flutter installation guide: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
* **Git**: For cloning the repository.
* **Android Studio / VS Code**: Recommended IDEs for Flutter development.

### Steps

1.  **Clone the repository:**
    ```bash
    git clone [YOUR_REPOSITORY_URL_HERE]
    cd arogya_sos_app
    ```
    *(Replace `[YOUR_REPOSITORY_URL_HERE]` with the actual URL of your Git repository)*

2.  **Install dependencies:**
    Navigate to the project root directory (`arogya_sos_app`) and run:
    ```bash
    flutter pub get
    ```

3.  **Ensure Fonts are Present:**
    Make sure you have the `Inter-Regular.ttf` and `Inter-Bold.ttf` font files in the `fonts/` directory at the project root. Your project structure should look like this:
    ```
    arogya_sos_app/
    ├── lib/
    ├── fonts/
    │   ├── Inter-Regular.ttf
    │   └── Inter-Bold.ttf
    ├── pubspec.yaml
    └── ...
    ```

4.  **Run the application:**

    * **For Android/iOS (Mobile):**
        Connect a device or start an emulator, then run:
        ```bash
        flutter run
        ```

    * **For Web (Chrome):**
        It's recommended to use the HTML renderer for better compatibility during development:
        ```bash
        flutter run -d chrome --web-renderer html
        ```
        If you encounter issues, try a clean build:
        ```bash
        flutter clean
        flutter pub get
        flutter build web --web-renderer html --no-sound-null-safety
        flutter run -d chrome --web-renderer html
        ```

### Permissions (for Mobile Devices)

For the location, calling, and SMS functionalities to work, you will need to ensure appropriate permissions are granted on the device. Flutter handles requesting these, but users will need to accept them.

* **Android:** Permissions are typically handled in `android/app/src/main/AndroidManifest.xml`. Flutter plugins usually add necessary entries automatically.
* **iOS:** Permissions are handled in `ios/Runner/Info.plist`.

## Usage

* **SOS Screen**: Tap the large SOS button to initiate an emergency alert countdown. You can cancel the countdown if it was an accident.
* **Location Display**: Your current location will be fetched and displayed on the SOS screen.
* **Quick Contacts**: Use the dedicated "108 Ambulance" and "100 Police" buttons for immediate calls.
* **Medicine / Guides / Profile**: Navigate through the bottom bar to access other features.

## Contact

For any inquiries or feedback, please contact:
* [ANIKET YELAMELI/aniketyelameli26@gmail.com]
---