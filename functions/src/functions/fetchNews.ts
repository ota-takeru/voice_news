import { onRequest } from "firebase-functions/v2/https";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { db } from "../config/firestore";
import { httpsRequest } from "../utils/httpsRequest";
import { GNewsResponse } from "../types/news";
import { defineSecret } from "firebase-functions/params";

const GNEWS_API_KEY = defineSecret("GNEWS_API_KEY");

export const fetchnews = onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [GNEWS_API_KEY],
  },
  async (req, res) => {
    try {
      const time24HoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const formattedTime = time24HoursAgo.toISOString();

      const apiKey = GNEWS_API_KEY.value();
      console.log("GNEWS_API_KEY:", apiKey);
      if (!apiKey) {
        throw new Error("GNEWS_API_KEY not found in environment variables");
      }

      const url = `https://gnews.io/api/v4/top-headlines?lang=ja&country=jp&max=20&from=${formattedTime}&expand=content&apikey=${apiKey}`;

      const response = await httpsRequest<GNewsResponse>(url, 30000);
      const { articles } = response;

      console.log(`Received ${articles.length} articles from GNews API`);

      const batch = db.batch();
      const oneWeekFromNow = Timestamp.fromDate(
        new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      );

      articles.forEach((article) => {
        const docRef = db.collection("news").doc();
        batch.set(docRef, {
          title: article.title,
          url: article.url,
          content: article.content,
          source_name: article.source.name,
          source_url: article.source.url,
          published_at: article.publishedAt.split("T")[0],
          expires_at: oneWeekFromNow,
          created_at: FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

      res.status(200).json({
        message: "News data saved successfully.",
        count: articles.length,
      });
    } catch (error) {
      console.error("Error in fetchNews function:", error);

      if (error instanceof Error) {
        res.status(500).json({
          error: "Internal Server Error",
          message: error.message,
        });
      } else {
        res.status(500).json({ error: "Unknown Error" });
      }
    }
  }
);
