import * as functions from "firebase-functions";
import * as https from "https";
import * as admin from "firebase-admin";

import { setGlobalOptions } from "firebase-functions/v2";
setGlobalOptions({
  region: "asia-northeast1",
});

admin.initializeApp();
const db = admin.firestore();

interface Article {
  title: string;
  url: string;
  content: string;
  source: {
    name: string;
    url: string;
  };
  publishedAt: string;
  expiresAt: string;
}

interface GNewsResponse {
  articles: Article[];
}

function httpsRequest<T>(url: string, timeout: number = 30000): Promise<T> {
  return new Promise((resolve, reject) => {
    const request = https.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`HTTP status code ${response.statusCode}`));
        return;
      }

      let data = "";
      response.on("data", (chunk) => (data += chunk));
      response.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error("Failed to parse JSON response"));
        }
      });
    });

    request.setTimeout(timeout, () => {
      request.destroy();
      reject(new Error(`Request timed out after ${timeout}ms`));
    });

    request.on("error", reject);
  });
}

export const fetchNews = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .https.onRequest(
    async (req: functions.https.Request, res: functions.Response) => {
      try {
        const time24HoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const formattedTime = time24HoursAgo.toISOString();

        const apiKey = functions.config().gnews.apikey;
        if (!apiKey) {
          throw new Error("GNEWS_API_KEY not found in environment variables");
        }

        const url = `https://gnews.io/api/v4/top-headlines?lang=ja&country=jp&max=20&from=${formattedTime}&expand=content&apikey=${apiKey}`;

        const response = await httpsRequest<GNewsResponse>(url, 30000);
        const { articles } = response;

        console.log(`Received ${articles.length} articles from GNews API`);

        const batch = db.batch();
        const oneWeekFromNow = admin.firestore.Timestamp.fromDate(
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
            published_at: article.publishedAt,
            expires_at: oneWeekFromNow,
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
          res
            .status(500)
            .json({ error: "Internal Server Error", message: error.message });
        } else {
          res.status(500).json({ error: "Unknown Error" });
        }
      }
    }
  );
