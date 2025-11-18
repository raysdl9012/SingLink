# SignLink - Real-Time Sign Language Translator

<div align="center">

![iOS](https://img.shields.io/badge/iOS-15%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.5-orange) ![ML](https://img.shields.io/badge/Machine%20Learning-Core%20ML-green) ![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20Services-lightgrey)

**Accessibility solution that uses computer vision to translate sign language on iOS devices**

</div>

---

## 📖 Overview

SignLink is an iOS application designed to translate sign language into text in real time directly on the device. It is built for critical environments (healthcare, emergencies, public services, education, and retail) where instant and private communication is essential.

The project is optimized for Apple’s native technologies: **Vision** (hand pose detection), **Core ML** (Neural Engine–optimized inference), **ARKit** (optional enhanced 3D tracking), and **AVFoundation** (video capture). All processing is performed **offline**, ensuring user privacy.

---

## 🎯 Project Objectives

* Translate sign language to text with high accuracy (>85%) and low latency (<100ms) on supported devices.
* Provide an offline-first solution that guarantees privacy and functionality in areas with limited connectivity.
* Offer tools for training and expanding specialized vocabularies (medical, legal, educational) for B2B and B2G use cases.

---

## 🧭 Target Users & Use Cases

* **People with hearing impairments** needing communication support in medical visits, offices, or daily interactions.
* **Medical and emergency personnel** requiring fast translation for decision-making.
* **Public institutions and schools** that need accessibility without relying on in-person interpreters.
* **Retail and customer service environments** offering inclusive communication channels.

---

## 📦 Requirements

* **Xcode 14+**
* **iOS 15+**
* **Swift 5.5+**
* Device with **Neural Engine** (recommended for fast inference)

Optional dependencies:

* Swift Package Manager: logging utilities, UI helpers, testing tools.

---

## 🏗 Architecture

The project follows **MVVM + Services**, ensuring clean separation of responsibilities, scalability, and testability.

* **Views (SwiftUI)**: `MainTranslatorView`, `ConversationHistoryView`, `LearningView`, `SettingsView`, `ProfileView`
* **ViewModels**: Manage UI state and actions (e.g., `TranslatorViewModel`).
* **Services**:

  * `CameraService` — wrapper around `AVCaptureSession`.
  * `VisionService` — runs `VNDetectHumanHandPoseRequest` and normalizes keypoints.
  * `MLService` — handles Core ML model inference.
  * `StorageService` — encrypted storage for histories and datasets.
* **Utilities**: pose preprocessing, iCloud sync, analytics (opt-in).

---

## 🔬 Key Components & Implementation

### Video Capture

* High-frame-rate `AVCaptureSession` setup.
* Frame buffering via `CMSampleBuffer`, dispatched to `VisionService` on a background queue.

### Hand Detection

* Use of `VNDetectHumanHandPoseRequest` to extract hand landmarks.
* Coordinate normalization for device-independent input.
* Support for **multiple hands** with tracking IDs.

### ML Pipeline

* Preprocessing: keypoint vectorization + temporal normalization (sliding window).
* Models:

  * Static sign classifier (Core ML) for isolated gestures.
  * Sequence recognition using lightweight LSTM/Transformer models converted to Core ML.
* Optimizations: pruning, quantization, and Neural Engine support.

### Interface & Accessibility

* Camera overlay with hand keypoints and confidence bars.
* Real-time translated text with adjustable font and contrast.
* Full VoiceOver support + switch control.
* "Large display mode" for showing responses clearly to the signer.

### Privacy & Security

* 100% on-device processing by default.
* Encrypted storage for histories and datasets (Keychain / File Protection).
* Minimal permission requests.

---

## 🧪 Dataset & Training

* **Initial Dataset**: combination of public datasets (ASL/LSE where legally allowed) and custom expert-labeled collections.
* **Labeling**: multiple annotators for quality assurance.
* **Tools**: Create ML for prototyping, Core ML Tools for converting PyTorch/TensorFlow models.
* **Pipeline**:

  1. Data collection (capture app / workstation)
  2. Cleaning & balancing (illumination, angles, hand shapes)
  3. Train/val/test split
  4. Iterative training, pruning & quantization
  5. Evaluation: accuracy, class-level precision/recall, on-device latency

---

## 📈 Evaluation Metrics

* **Global accuracy** target > 85%
* **Latency (p99)** < 100ms on Neural Engine devices
* **Robustness**: consistent performance under varied lighting and hand shapes
* **Usability**: validation with real deaf community users

---

## 📲 Typical User Flow

1. User opens the app and points the camera toward the signer.
2. System detects and tracks hands with overlaid landmarks.
3. The model outputs real-time text translation.
4. User can validate or correct the translation; conversation is saved automatically.
5. For responses, the user can type or speak, and display the message clearly to the signer.

---

## 🧭 Roadmap & Future Features

* Support for additional sign languages (LSE, ASL, BSL, etc.)
* Medical and legal mode with specialized vocabulary
* Sequence recognition with multimodal models (hands + face)
* B2B on-premise deployments and optional iCloud sync
* In-app annotation tool for user-consented dataset collection

---

## 🛠 Local Development & Testing

1. Clone the repository

```bash
git clone git@github.com:your-org/signlink.git
cd signlink
```

2. Open `SignLink.xcodeproj` in Xcode
3. Run on a real device (recommended for camera + Neural Engine)

**Note**: The simulator does not support real camera input or Neural Engine hardware.

---

## 🧾 Legal & Ethical Considerations

* Collect sign language data only with **informed consent**.
* Ensure anonymization and encryption of all recordings.
* Document model limitations and advise human confirmation in critical scenarios (e.g., healthcare).

---

## 🤝 Contributing

Contributions are welcome. For collaboration or B2B/G proposals, contact the development team and review the `CONTRIBUTING.md` guidelines.

---

## ⚖️ License

MIT or organization-specific license (update based on project needs).

---

## 📞 Contact

* Maintainer: SignLink Team
* Email: [reinner.leiva@gmail.com](mailto:reinner.leiva@gmail.com) 

---

> *This README serves as a professional baseline for development, presentations, and stakeholder communication. Ask if you’d like additional documentation such as `CONTRIBUTING.md`, `ARCHITECTURE.md`, test suites, or a Security & Privacy manual.*
