import {
  onDocumentCreated,
  FirestoreEvent,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";
4;
import * as admin from "firebase-admin";
import * as superagent from "superagent";
import * as fs from "fs";
import * as path from "path";
import * as util from "util";
import * as os from "os";
import * as ffmpeg from "fluent-ffmpeg";
import * as functions from "firebase-functions";
import { NewsData } from "../types/news";

const bucket = admin.storage().bucket();
const writeFile = util.promisify(fs.writeFile);
const unlinkFile = util.promisify(fs.unlink);

interface AudioQueryResponse {
  [key: string]: any;
}

export const generateAudioForNews = onDocumentCreated(
  "news/{newsId}",
  async (
    event: FirestoreEvent<QueryDocumentSnapshot | undefined, { newsId: string }>
  ) => {
    const snap = event.data;

    if (!snap) {
      functions.logger.error("No data found in event");
      return;
    }

    const newsData = snap.data() as NewsData;
    if (!newsData) {
      functions.logger.error("No news data found in snapshot");
      return;
    }

    // ニュースタイトルとコンテンツを1文ずつ分割
    const sentences = `${newsData.title}。 ${newsData.content}`.split(
      /(?<=。|\.|!|\?)\s*/
    );

    const tempFiles: string[] = [];
    const finalFilePath = path.join("/tmp", `${event.params.newsId}.mp3`);
    try {
      const concurrencyLimit = 1; // 並列処理の最大数
      const generateAudio = async (sentence: string, index: number) => {
        const queryJson = await generateAudioQuery(sentence);
        const synthesisRes = await superagent
          .post(
            "https://voicevox-engine-674516299039.asia-northeast1.run.app/synthesis"
          )
          .query({ speaker: 1 })
          .send(queryJson)
          .responseType("blob")
          .timeout({ response: 600000, deadline: 600000 });

        if (!synthesisRes || !synthesisRes.body) {
          throw new Error("Failed to generate audio content");
        }

        const tempFilePath = path.join(
          os.tmpdir(),
          `${event.params.newsId}_${index}.mp3`
        );
        await writeFile(tempFilePath, synthesisRes.body, "binary");
        tempFiles.push(tempFilePath);
      };

      // 並列に処理し、1度に処理する数を制限
      const promises: Promise<void>[] = [];
      for (let i = 0; i < sentences.length; i++) {
        promises.push(generateAudio(sentences[i], i));
        if (promises.length >= concurrencyLimit) {
          await Promise.all(promises);
          promises.length = 0; // 配列をクリア
        }
      }
      // 残りのPromiseを処理
      if (promises.length > 0) {
        await Promise.all(promises);
      }

      // 音声ファイルを結合
      const tempFolderPath = os.tmpdir();
      await new Promise((resolve, reject) => {
        const ffmpegCommand = ffmpeg();
        tempFiles.forEach((file) => ffmpegCommand.input(file));
        ffmpegCommand
          .on("end", resolve)
          .on("error", reject)
          .mergeToFile(finalFilePath, tempFolderPath);
      });

      // Cloud Storageにアップロード
      const fileName = `${event.params.newsId}.mp3`;
      await bucket.upload(finalFilePath, {
        destination: `audio/${fileName}`,
      });

      // Firestoreのニュースデータにaudio_urlを追加
      const audioUrl = `https://storage.googleapis.com/${bucket.name}/audio/${fileName}`;
      await snap.ref.set({ audio_url: audioUrl }, { merge: true }); // mergeオプションを追加
    } catch (error) {
      functions.logger.error("Error generating audio:", error);
    } finally {
      // 一時ファイルを削除
      const deleteFilePromises = tempFiles.map((tempFile) =>
        unlinkFile(tempFile).catch((err) =>
          functions.logger.warn(`Failed to delete temp file ${tempFile}:`, err)
        )
      );
      deleteFilePromises.push(
        unlinkFile(finalFilePath).catch((err) =>
          functions.logger.warn(
            `Failed to delete final file ${finalFilePath}:`,
            err
          )
        )
      );

      await Promise.all(deleteFilePromises);
    }
  }
);

async function generateAudioQuery(
  sentence: string
): Promise<AudioQueryResponse> {
  const res = await superagent
    .post(
      "https://voicevox-engine-674516299039.asia-northeast1.run.app/audio_query"
    )
    .query({ speaker: 1, text: sentence })
    .timeout({ response: 600000, deadline: 600000 });

  if (!res || !res.body) {
    throw new Error("Failed to generate query for audio");
  }
  return res.body;
}
