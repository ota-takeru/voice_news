import * as https from "https";

export function httpsRequest<T>(
  url: string,
  timeout: number = 30000
): Promise<T> {
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

export function httpsPostRequest<T>(
  url: string,
  options: https.RequestOptions,
  postData?: string,
  timeout: number = 30000
): Promise<T> {
  return new Promise((resolve, reject) => {
    const request = https.request(url, options, (response) => {
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

    if (postData) {
      request.write(postData);
    }

    request.setTimeout(timeout, () => {
      request.destroy();
      reject(new Error(`Request timed out after ${timeout}ms`));
    });

    request.on("error", reject);
    request.end();
  });
}