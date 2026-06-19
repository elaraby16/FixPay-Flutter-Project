# FixPay - Service Marketplace Application 🚀

FixPay is a comprehensive service marketplace mobile application developed as a graduation project for a Bachelor of Computer Science. The platform connects customers with independent workers, facilitating real-time task creation, bidding, location-based matching, and secure communication.

## 👨‍💻 My Role: Mobile Application Developer
**Name:** Mohamed Elaraby
I was responsible for developing the full mobile client using Flutter and Dart. My primary focus was on implementing the user interface, managing the global application state, handling complex navigation logic based on user roles, and seamlessly integrating robust backend RESTful APIs.

## 🛠️ Tech Stack & Architecture
* **Framework:** Flutter
* **Language:** Dart
* **Architecture:** Layered / Component-based architecture
* **State Management:** Provider
* **Networking:** HTTP & Dio
* **Local Storage:** Shared Preferences (for JWT & Session Caching)

## 🌟 Key Technical Implementations
* **Role-Based Authentication:** Implemented a secure JWT-based login/registration system with distinct UI routing and capabilities for 'Customers' vs. 'Workers'.
* **Dynamic Task Engine:** Engineered CRUD operations for task management, allowing users to create, track, and close tasks.
* **Real-Time Bidding System:** Built the front-end logic for a complex offer system where workers can bid on open tasks, and customers can accept or decline offers dynamically.
* **Location Services:** Integrated `Geolocator` and `flutter_map` (OpenStreetMap) to provide an interactive map overlay for precise coordinate picking.
* **Identity & Verification Pipeline:** Developed a multi-step verification process handling multipart image uploads (via `image_picker`) and secure OTP inputs (via `pinput`).
* **Direct Chat Interface:** Built a peer-to-peer messaging UI to facilitate real-time text exchange between matched users and workers.



