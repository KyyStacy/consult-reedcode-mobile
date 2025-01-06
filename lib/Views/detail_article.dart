import 'package:flutter/material.dart';

class Article {
  final String title;
  final String summary;
  final String content;

  Article({required this.title, required this.summary, required this.content});
}

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title,
            style: const TextStyle(
                color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0097A7)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Using Text.rich to allow for justified text
              Text(
                article.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.justify, // Justified alignment
              ),
            ],
          ),
        ),
      ),
    );
  }
}
