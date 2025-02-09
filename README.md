# 🏆 Google Solution Challenge - Addiction Recovery App

This is a **Flutter-based mobile app** for addiction recovery, using **AI-powered support, progress tracking, guided meditation, community chat, and more**. The app connects to a **Node.js backend** with Firebase authentication and Google Gemini AI.

---

## 🚀 Features
✅ **User Authentication** (Firebase)  
✅ **Daily Recovery Tasks** (AI-powered)  
✅ **Progress Tracking**  
✅ **AI Journal & Mood Tracking**  
✅ **Personalized AI Recovery Plans**  
✅ **Guided Meditation & Breathing**  
✅ **AI Trigger Prediction**  
✅ **Community Support Chat**  
✅ **Emergency Help**  

---

## 📌 Getting Started

### **1️⃣ Clone the Repository**
```sh
git clone https://github.com/your-username/your-repo.git
cd solution_challenge
```

### **2️⃣ Set Up the Backend**
```sh
cd backend
npm install  # Install dependencies
cp .env.example .env  # Create .env file and add Firebase & Gemini API keys
tsc  # Compile TypeScript
node dist/index.js  # Run backend server
```
**🛠 Dependencies:** Node.js, Firebase Admin SDK, TypeScript

### **3️⃣ Set Up the Frontend (Flutter)**
```sh
cd ../frontend
flutter pub get  # Install dependencies
flutter run  # Run the app on emulator or device
```
**🛠 Dependencies:** Flutter, Firebase SDK, HTTP package

---

## 🔑 Environment Variables (`.env`)
```env
GEMINI_API_KEY=your-gemini-api-key
FIREBASE_PROJECT_ID=your-project-id
```
👉 **Do not share your `.env` or Firebase service account keys!**

---

## 🛠 Folder Structure
```
solution_challenge/
│── backend/            # Node.js Backend (Express, Firebase, AI)
│── frontend/           # Flutter Mobile App
│── build/              # Build Artifacts (Ignored in Git)
│── .gitignore          # Ignore Unnecessary Files
│── README.md           # This File! 📝
```

---

## 🤝 Contributing
1. Fork the repo  
2. Create a feature branch: `git checkout -b feature-name`  
3. Commit changes: `git commit -m "Added new feature"`  
4. Push and open a Pull Request 🚀  

---

## 📧 Contact & Support
For questions, feel free to open an **issue** or contact me at **chinmayjoshi003@gmail.com** 📩

---



