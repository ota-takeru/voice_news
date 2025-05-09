class NewsItem {
  final String title;
  final String content;
  final String? sourceName;
  final String? sourceUrl;
  final String? url;
  final String? publishedAt;

  NewsItem({
    required this.title,
    required this.content,
    this.sourceName,
    this.sourceUrl,
    this.url,
    required this.publishedAt,
  });

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      title: map['title'] ?? '不明なタイトル',
      content: map['content'] ?? '内容がありません',
      sourceName: map['source_name'],
      sourceUrl: map['source_url'],
      url: map['url'],
      publishedAt: map['published_at'] != null
          ? DateTime.parse(map['published_at']).toLocal().toString()
          : null,
    );
  }
}
