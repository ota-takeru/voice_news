
export interface Article {
  title: string;
  url: string;
  content: string;
  source: {
    name: string;
    url: string;
  };
  publishedAt: string;
}

export interface GNewsResponse {
  articles: Article[];
}

export interface NewsData {
  id: string;
  title: string;
  url: string;
  content: string;
  source_name: string;
  source_url: string;
  published_at: string;
  expires_at: string;
}
