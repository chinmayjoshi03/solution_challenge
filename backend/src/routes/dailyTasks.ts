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

router.post("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { userId } = req.body;
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data();
    const addictionType = userData?.addictionType || "substance addiction";
    const triggersArray: string[] = userData?.triggers || ["stress", "loneliness"];
    const triggers = triggersArray.join(", ");

    const chatSession = model.startChat({
      generationConfig,
      history: [
        {
          role: "user",
          parts: [
            {
              text: " Generate a structured daily recovery to-do list for a person recovering from alcohol. \n    The tasks should be short, concise (one line each), and actionable.\n    Format them as a numbered list. Example:\n    \n    1. Morning Meditation (5 min)\n    2. Drink a glass of water\n    3. Journaling - Write one positive thought\n    4. Exercise for 10 minutes\n    5. Connect with a support group\n    \n    Do NOT include extra descriptions or explanations.\nI have to render these tasks in my app like a to-do list \n",
            },
          ],
        },
        {
          role: "model",
          parts: [
            {
              text: "1. Morning Meditation (5 min)\n2. Drink a glass of water\n3. Read one page of recovery literature\n4. Exercise for 15 minutes\n5. Call your sponsor or support person\n6. Attend a meeting\n7. Write down three things you're grateful for\n8. Eat a nutritious meal\n9. Engage in a hobby for 30 minutes\n10. Practice deep breathing exercises (5 min)\n11. Avoid triggering environments\n12. Plan a sober activity for the evening\n13. Review your recovery goals\n14. Reflect on your day\n15. Get 7-8 hours of sleep\n",
            },
          ],
        },
        {
          role: "user",
          parts: [{ text: "do not give any starting explanation, also only tasks\n" }],
        },
        {
          role: "model",
          parts: [
            {
              text: "1. Morning Meditation (5 min)\n2. Drink a glass of water\n3. Read one page of recovery literature\n4. Exercise for 15 minutes\n5. Call your sponsor or support person\n6. Attend a meeting\n7. Write down three things you're grateful for\n8. Eat a nutritious meal\n9. Engage in a hobby for 30 minutes\n10. Practice deep breathing exercises (5 min)\n11. Avoid triggering environments\n12. Plan a sober activity for the evening\n13. Review your recovery goals\n14. Reflect on your day\n15. Get 7-8 hours of sleep\n",
            },
          ],
        },
      ],
    });

    const result = await chatSession.sendMessage("Generate daily tasks.");
    const generatedTasks = result.response.text().trim();

    console.log("✅ Generated Tasks:", generatedTasks);

    await db.collection("users").doc(userId).set({ dailyTask: generatedTasks }, { merge: true });

    res.json({ dailyTask: generatedTasks });
  } catch (error) {
    console.error("❌ Error generating daily tasks:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

export default router;
