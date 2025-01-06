import 'package:flutter/material.dart';
import 'detail_article.dart'; // Make sure to import the file containing ArticleDetailPage

class ArticleListPage extends StatelessWidget {
  ArticleListPage({super.key});

  final List<Article> articles = [
    Article(
      title: "Understanding Anxiety: Causes, Symptoms, and Coping Strategies",
      summary:
          "Learn about the common causes of anxiety, how to recognize its symptoms, and effective ways to manage it in daily life.",
      content:
          "Anxiety is a normal human emotion that everyone experiences from time to time. However, when anxiety becomes persistent and interferes with daily activities, it may be classified as an anxiety disorder. Common causes of anxiety include stress, traumatic experiences, and genetic factors. Symptoms can range from physical manifestations like rapid heartbeat and sweating to psychological effects such as excessive worry and difficulty concentrating. Coping strategies include practicing mindfulness, regular exercise, maintaining a healthy diet, and seeking professional help when needed. Cognitive Behavioral Therapy (CBT) and medication are often effective treatments for managing anxiety disorders.",
    ),
    Article(
      title: "The Importance of Self-Care in Mental Health",
      summary:
          "Discover why self-care is crucial for maintaining good mental health and learn practical self-care techniques.",
      content:
          "Self-care is an essential aspect of maintaining good mental health. It involves taking deliberate actions to care for your physical, emotional, and mental well-being. Regular self-care practices can help reduce stress, improve mood, and increase resilience to life's challenges. Some effective self-care techniques include setting boundaries, practicing mindfulness or meditation, engaging in hobbies, getting adequate sleep, and maintaining a balanced diet. It's important to remember that self-care looks different for everyone, and what works for one person may not work for another. The key is to find activities that genuinely help you relax and recharge.",
    ),
    Article(
      title: "Breaking the Stigma: Mental Health in the Workplace",
      summary:
          "Explore the importance of addressing mental health in professional settings and strategies for creating a supportive work environment.",
      content:
          "Mental health in the workplace is an increasingly important topic as more organizations recognize the impact of employee well-being on productivity and overall workplace culture. Breaking the stigma surrounding mental health is crucial for creating an environment where employees feel comfortable seeking help when needed. Employers can promote mental health awareness through education programs, providing access to mental health resources, and implementing policies that support work-life balance. It's also important for leaders to model healthy behaviors and encourage open conversations about mental health. By prioritizing mental health, organizations can create a more inclusive, supportive, and productive work environment for all employees.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Articles',
            style: TextStyle(
                color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0097A7)),
      ),
      body: ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF0097A7), width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                articles[index].title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(articles[index].summary),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ArticleDetailPage(article: articles[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
