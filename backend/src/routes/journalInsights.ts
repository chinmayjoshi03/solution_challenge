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
    const { userId, mood, entry } = req.body;
    if (!userId || !entry) {
      return res.status(400).json({ error: "Missing userId or journal entry." });
    }

    console.log("🔹 Received journal entry from user:", entry);

    const today = new Date().toISOString().split("T")[0]; 
    const userRef = db.collection("users").doc(userId).collection("journalEntries").doc(today);

    await userRef.set({ mood: mood, entry: entry }, { merge: true });

    const prompt = `
      The user has written a journal entry and rated their mood as ${mood}/10.
      Based on this, provide a short AI-generated motivational insight (one sentence) to help them reflect.
      **Journal Entry:** "${entry}"
      **AI Insight:**
      (Reply as a psychologist or counselor)
    `;

    console.log("🔹 Sending this prompt to Gemini AI:", prompt);

    const chatSession = model.startChat({
      generationConfig,
      history: [{ role: "user", parts: [{ text: prompt }] }],
    });

    const result = await chatSession.sendMessage("Generate AI insights.");
    const aiInsights = result.response.text().trim();

    console.log("✅ AI Response:", aiInsights);

    await userRef.update({ ai_insights: aiInsights });

    res.json({ ai_insights: aiInsights });
  } catch (error) {
    console.error("❌ Error generating AI insight:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

export default router;