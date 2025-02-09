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

    console.log("🔹 Fetching journal entries for:", userId);

    const journalRef = db.collection("users").doc(userId).collection("journalEntries");
    const journalSnapshot = await journalRef.orderBy("date", "desc").limit(10).get();

    let journalData: { date: string; mood: number; entry: string }[] = [];

    journalSnapshot.forEach((doc) => {
      const entryData = doc.data();
      if (entryData.entry && entryData.mood) {
        journalData.push({
          date: entryData.date || "",
          mood: entryData.mood || 0,
          entry: entryData.entry || "",
        });
      }
    });

    if (journalData.length === 0) {
      console.log("❌ No journal entries found for analysis.");
      return res.json({
        triggerPrediction: {
          predictedTriggers: ["Unknown (Insufficient Data)"],
          riskLevel: "Low",
          suggestedCopingStrategies: [
            "Start tracking your mood and journal daily.",
            "Identify what situations make you feel cravings.",
            "Practice mindfulness to better understand your emotions."
          ],
        },
      });
    }

    const prompt = `
      Analyze the following journal entries and mood ratings. Identify patterns that indicate high-risk situations for relapse.
      Predict which triggers are most likely to cause cravings, and suggest coping strategies.
      Format the output as JSON:
      {
        "predictedTriggers": ["Trigger 1", "Trigger 2", "Trigger 3"],
        "riskLevel": "Low/Medium/High",
        "suggestedCopingStrategies": ["Strategy 1", "Strategy 2", "Strategy 3"]
      }
      Journal Data: ${JSON.stringify(journalData)}
    `;

    console.log("🔹 Sending prompt to Gemini AI:", prompt);

    const chatSession = model.startChat({
      generationConfig,
      history: [{ role: "user", parts: [{ text: prompt }] }],
    });

    const result = await chatSession.sendMessage("Generate trigger prediction.");
    let predictionResponse = result.response.text().trim();

    predictionResponse = predictionResponse.replace(/```json/g, "").replace(/```/g, "").trim();
    console.log("✅ Cleaned JSON Response:", predictionResponse);

    const triggerPrediction = JSON.parse(predictionResponse);

    await db.collection("users").doc(userId).set(
      {
        triggerPrediction,
      },
      { merge: true }
    );

    res.json({ triggerPrediction });
  } catch (error) {
    console.error("❌ Error generating AI trigger prediction:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

export default router;