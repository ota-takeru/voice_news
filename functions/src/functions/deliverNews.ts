import { onRequest } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firestore";
import { NewsData } from "../types/news";

export const delivernews = onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (req, res) => {
    try {
      const time22HoursAgo = new Date(Date.now() - 22 * 60 * 60 * 1000);
      const formattedTime = Timestamp.fromDate(time22HoursAgo);

      const newsQuery = db
        .collection("news")
        .where("created_at", ">=", formattedTime)
        .orderBy("created_at", "desc");

      const snapshot = await newsQuery.get();

      if (snapshot.empty) {
        console.log("ニュースデータが見つかりませんでした。");
        res.status(200).json({
          data: {
            message: "No recent news found.",
            news: [],
          },
        });
        return;
      }

      const newsData: NewsData[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        newsData.push({
          id: doc.id,
          title: data.title,
          url: data.url,
          content: data.content,
          source_name: data.source_name,
          source_url: data.source_url,
          published_at: data.published_at,
          expires_at: data.expires_at,
        });
      });

      res.status(200).json({
        data: {
          message: "Recent news data retrieved successfully.",
          news: newsData,
        },
      });
    } catch (error) {
      console.error("Error retrieving news data:", error);

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
