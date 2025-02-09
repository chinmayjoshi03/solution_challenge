// routes/dailyTask.ts
import express, { Request, Response, NextFunction } from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { db } from '../services/firebaseadmin';
// import admin from "firebase-admin";
import dotenv from "dotenv";

dotenv.config();

const router = express.Router();
// const db = admin.firestore();

// Initialize Gemini AI
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

router.post("/", async (req: Request, res: Response) => {
  try {
    const { userId, message } = req.body;
    // if (!userId || !message) {
    //   return res.status(400).json({ error: "Missing userId or message." });
    // }

    console.log("🔹 User's Question:", message);

    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.exists ? userDoc.data() : {};
    const addictionType = userData?.addictionType || "substance addiction";

    const prompt = `
      You are an addiction recovery coach assisting a user overcoming ${addictionType}.
      Provide a **short and actionable** response in a **supportive and motivating** tone.
      User's Question: "${message}"
      AI Recovery Coach:
    `;

    console.log("🔹 Sending Prompt to Gemini AI:", prompt);

    const chatSession = model.startChat({
      generationConfig,
      history: [{ role: "user", parts: [{ text: prompt }] }],
    });

    const result = await chatSession.sendMessage("Generate AI response.");
    const aiResponse = result.response.text().trim();

    console.log("✅ AI Coach Response:", aiResponse);

    res.json({ response: aiResponse });
  } catch (error) {
    console.error("❌ Error generating AI response:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

export default router;