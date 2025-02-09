import express, { Request, Response, NextFunction } from "express";
import bodyParser from "body-parser";
import cors from "cors";
import admin from "firebase-admin";
import dotenv from "dotenv";
import path from "path";
import { GoogleGenerativeAI } from "@google/generative-ai";

dotenv.config();
const PORT = process.env.PORT || 3000;

const serviceAccountPath = path.resolve(__dirname, "../src/services/solution-challenge-704ed-firebase-adminsdk-fbsvc-f60341b406.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
  });
}
const db = admin.firestore();

const app = express();
app.use(cors());
app.use(bodyParser.json());

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "YOUR_GEMINI_API_KEY";
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

const generationConfig = {
  temperature: 1,
  topP: 0.95,
  topK: 40,
  maxOutputTokens: 8192,
  responseMimeType: "text/plain",
};

app.get("/", (req, res) => {
  res.send("API is running!");
});

import journalInsightsRoute from "./routes/journalInsights";
import recoveryCoachRoute from "./routes/recoveryCoach";
import recoveryPlanRoute from "./routes/recoveryPlan";
import triggerPredictionRoute from "./routes/triggerPrediction";
import dailyTaskRoute from "./routes/dailyTasks";

console.log("✅ Registering routes...");

app.use("/api/dailyTask", dailyTaskRoute);
console.log("✅ /api/dailyTask route loaded");

app.use("/api/journalInsights", journalInsightsRoute);
console.log("✅ /api/journalInsights route loaded");

app.use("/api/recoveryCoach", recoveryCoachRoute);
console.log("✅ /api/recoveryCoach route loaded");

app.use("/api/recoveryPlan", recoveryPlanRoute);
console.log("✅ /api/recoveryPlan route loaded");

app.use("/api/triggerPrediction", triggerPredictionRoute);
console.log("✅ /api/triggerPrediction route loaded");

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
