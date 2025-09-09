# Smart Irrigation System 🌱💧

A Flutter-based Smart Irrigation System developed for the **Smart India Hackathon 2025**. This project aims to provide an intelligent, automated, and user-friendly solution for modern agriculture, featuring real-time monitoring, multi-language support, and AI-powered assistance.

## ✨ Key Features

-   **Real-Time Monitoring**: Live data from sensors for soil moisture, temperature, humidity, and water tank levels.
-   **Automated Irrigation**: Intelligent system that automatically controls water pumps based on sensor readings and weather forecasts.
-   **Multi-Language Support**: Fully functional in both **English** and **Hindi**, with on-the-fly translation for dynamic content.
-   **Weather Integration**: Provides real-time weather data and irrigation recommendations from the OpenWeatherMap API.
-   **System Notifications**: Receive real-time push notifications for critical alerts like low battery, water needed, or extreme weather conditions.
-   **AI Chatbot**: An in-app assistant powered by Google's Generative AI to help users with queries and support.

## 🚀 Technology Stack

Our project is built on a modern, scalable, and cross-platform technology stack:

-   **Mobile App (Frontend)**:
    -   **Framework**: Flutter & Dart
    -   **State Management**: Provider
-   **Backend & Cloud Services**:
    -   **Platform**: Google Firebase
    -   **Authentication**: Firebase Authentication (Phone Number)
    -   **Database**: Cloud Firestore / Realtime Database
-   **APIs & External Services**:
    -   **Weather**: OpenWeatherMap API
    -   **Geolocation**: OpenStreetMap (Nominatim)
    -   **Notifications**: Firebase Cloud Messaging (FCM) & Flutter Local Notifications
    -   **AI**: Google Generative AI

## 🛠️ Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

-   Flutter SDK installed (version 3.0.0 or higher).
-   An Android or iOS emulator/device.

### Installation

1.  **Clone the repo**
    ```
    git clone https://github.com/RedxHarshit/haritkranti.git
    ```
2.  **Navigate to the project directory**
    ```
    cd haritkranti
    ```
3.  **Install dependencies**
    ```
    flutter pub get
    ```
4.  **Set up API Keys**
    -   Create a `.env` file in the root of the project.
    -   Add your API keys to the file:
        ```
        OPENWEATHER_API_KEY=your_key_here
        GEMINI_API_KEY=your_key_here
        ```
5.  **Run the app**
    ```
    flutter run
    ```

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

This `README.md` provides a comprehensive overview of your project, making it easy for anyone (including hackathon judges) to understand its purpose, features, and how to get it running.
