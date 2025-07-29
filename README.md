# Flutter-IoT-Smart-Device-Controller

A Flutter app for configuring and controlling IoT devices via Bluetooth and MQTT.

## 🎯 Key Features

- ✅ **BLE Configuration**: Scan, connect, and send encrypted WiFi credentials via BLE (AES-256 encrypted).
  
- 📡 **MQTT Device Communication**: Real-time control and telemetry over MQTT (subscribe/publish, auto-reconnect, error handling).
  
- 🎛️ **Custom Mode Programming**: Users can configure up to three-step device control modes (power & duration).
  
- 📈 **Live Device Feedback**: Network metrics, power usage, temperature, RSSI, and more—updated live.
  
- 🧠 **Robust State Management**: Built with `flutter_bloc` and Cubit for clear, testable state transitions.
  
- 📸 **User Profile Support**: Handles user ID, device binding, and profile picture storage.
  
- 🌍 **Localization Ready**: Dynamic locale management with easy translation support.
  

## 🚀 Getting Started

### 📦 Requirements

- Flutter SDK ≥ 3.10.0
  
- Dart ≥ 2.17.0

- Android Studio / Xcode

- Physical device or emulator

- MQTT broker URL (e.g., Mosquitto, HiveMQ)

### 🔐 Security

- Encryption: BLE credentials (WiFi SSID/password) are encrypted using AES CBC mode before transmission.

- MQTT Topics: Dynamic topic structure based on userID and deviceID to isolate messages per device.

- Error Handling: Graceful handling of MQTT disconnects, parsing failures, permission denials, and BLE scan/connect timeouts.

### 🧩 Built With

| Package                                                             | Purpose                       |
| ------------------------------------------------------------------- | ----------------------------- |
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc)             | State management              |
| [`mqtt_client`](https://pub.dev/packages/mqtt_client)               | MQTT communication            |
| [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus)   | BLE scanning & connection     |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | Runtime permissions           |
| [`dio`](https://pub.dev/packages/dio)                               | HTTP requests                 |
| [`encrypt`](https://pub.dev/packages/encrypt)                       | AES encryption                |
| [`provider`](https://pub.dev/packages/provider)                     | Optional DI and state support |
| [`http`](https://pub.dev/packages/http)                             | RESTful API communication     |

## 📃 License

This project is licensed under the MIT License — see the LICENSE file for details.
