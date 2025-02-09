// routes/dailyTask.ts
import express, { Request, Response, NextFunction } from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { db } from '../services/firebaseadmin';
// import admin from "firebase-admin";
import dotenv from "dotenv";

dotenv.config();

const router = express.Router();
// const db = admin.firestore();

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

router.post("/", async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: "Missing userId in request body." });
    }

    console.log("🔹 Checking if AI recovery plan needs updating for:", userId);

    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();
    const userData = userDoc.exists ? userDoc.data() || {}: {};
    const lastGenerated = userData?.lastGenerated || null;

    
    const today = new Date();
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(today.getDate() - 7);

    if (lastGenerated && new Date(lastGenerated) > oneWeekAgo) {
      console.log("✅ Plan is still valid, returning existing plan.");
      return res.json({ recoveryPlan: userData.recoveryPlan });
    }

    console.log("🔹 Generating a new AI recovery plan...");

    const addictionType = userData?.addictionType || "substance addiction";
    const triggers = userData?.triggers?.join(", ") || "stress, loneliness";

    const prompt = `
      Create a **7-day personalized recovery plan** for a user recovering from ${addictionType}.
      The user experiences triggers such as ${triggers}.
      Each day should include **3 actionable tasks** focusing on **mental, physical, and emotional recovery**.
      Format output as valid JSON:
      {
        "day1": ["Task 1", "Task 2", "Task 3"],
        "day2": ["Task 1", "Task 2", "Task 3"],
        ...
        "day7": ["Task 1", "Task 2", "Task 3"]
      }
      Do NOT include explanations, only return JSON.
    `;

    console.log("🔹 Sending prompt to Gemini AI:", prompt);

    const chatSession = model.startChat({
      generationConfig,
      history: [{ role: "user", parts: [{ text: prompt }] }],
    });

    const result = await chatSession.sendMessage("Generate AI recovery plan.");
    let planResponse = result.response.text().trim();

    planResponse = planResponse.replace(/```json/g, "").replace(/```/g, "").trim();
    console.log("✅ Cleaned JSON Response:", planResponse);

    const recoveryPlan = JSON.parse(planResponse);

    await userRef.set(
      {
        recoveryPlan,
        lastGenerated: today.toISOString(), 
      },
      { merge: true }
    );

    res.json({ recoveryPlan });
  } catch (error) {
    console.error("❌ Error generating AI recovery plan:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

export default router;

