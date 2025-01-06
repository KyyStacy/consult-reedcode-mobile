import 'package:flutter/material.dart';
import 'home.dart';

class MentalHealthQuizPage extends StatefulWidget {
  const MentalHealthQuizPage({super.key});

  @override
  MentalHealthQuizPageState createState() => MentalHealthQuizPageState();
}

class MentalHealthQuizPageState extends State<MentalHealthQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, int?> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'question':
          'Seberapa sering Anda merasa cemas atau khawatir dalam dua minggu terakhir?',
      'id': 'q1',
    },
    {
      'question':
          'Seberapa sering Anda merasa sedih atau tertekan dalam dua minggu terakhir?',
      'id': 'q2',
    },
    {
      'question':
          'Seberapa sering Anda merasa lelah atau tidak berenergi dalam dua minggu terakhir?',
      'id': 'q3',
    },
    {
      'question':
          'Seberapa sering Anda mengalami kesulitan tidur atau tidur berlebihan dalam dua minggu terakhir?',
      'id': 'q4',
    },
    {
      'question':
          'Seberapa sering Anda merasa tidak tertarik atau tidak menikmati aktivitas yang biasanya Anda sukai dalam dua minggu terakhir?',
      'id': 'q5',
    },
    {
      'question':
          'Seberapa sering Anda merasa gugup, gelisah, atau tegang dalam dua minggu terakhir?',
      'id': 'q6',
    },
    {
      'question':
          'Seberapa sering Anda mengalami kesulitan berkonsentrasi pada hal-hal, seperti membaca koran atau menonton televisi dalam dua minggu terakhir?',
      'id': 'q7',
    },
    {
      'question':
          'Seberapa sering Anda merasa bahwa Anda tidak berharga atau merasa bersalah dalam dua minggu terakhir?',
      'id': 'q8',
    },
    {
      'question':
          'Seberapa sering Anda berpikir bahwa Anda lebih baik mati atau ingin menyakiti diri sendiri dengan cara tertentu dalam dua minggu terakhir?',
      'id': 'q9',
    },
    {
      'question':
          'Seberapa sering Anda merasa sulit untuk mengontrol perasaan marah atau frustrasi dalam dua minggu terakhir?',
      'id': 'q10',
    },
  ];

  final List<String> _options = [
    'Tidak pernah',
    'Beberapa hari',
    'Lebih dari setengah hari',
    'Hampir setiap hari',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis Kesehatan Mental',
            style: TextStyle(
                color: Color(0xFF0097A7), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0097A7)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Silakan jawab pertanyaan berikut tentang bagaimana perasaan Anda selama dua minggu terakhir:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ..._questions.map((question) => _buildQuestionWidget(question)),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0097A7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Kirim', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF0097A7), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _options.length,
              (index) => RadioListTile<int>(
                title: Text(_options[index]),
                value: index,
                groupValue: _answers[question['id']],
                onChanged: (value) {
                  setState(() {
                    _answers[question['id']] = value;
                  });
                },
                activeColor: const Color(0xFF0097A7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitQuiz() {
    if (_formKey.currentState!.validate()) {
      if (_answers.length != _questions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan jawab semua pertanyaan'),
            backgroundColor: Color(0xFF0097A7),
          ),
        );
        return;
      }

      int totalScore =
          _answers.values.fold(0, (sum, value) => sum + (value ?? 0));

      String hasil = '';
      if (totalScore >= 0 && totalScore <= 5) {
        hasil =
            'Anda memiliki kesehatan mental yang baik. Tetap jaga kesehatan mental Anda dengan melakukan aktivitas yang menyenangkan dan bermanfaat.';
      } else if (totalScore >= 6 && totalScore <= 10) {
        hasil =
            'Anda mungkin mengalami gejala gangguan mental ringan. Disarankan untuk lebih memperhatikan kesehatan mental Anda dan melakukan aktivitas yang dapat mengurangi stres.';
      } else if (totalScore >= 11 && totalScore <= 20) {
        hasil =
            'Anda mungkin mengalami gejala gangguan mental sedang. Disarankan untuk berkonsultasi dengan psikolog atau profesional kesehatan mental untuk mendapatkan dukungan dan penanganan yang tepat.';
      } else {
        hasil =
            'Anda kemungkinan mengalami gejala gangguan mental yang signifikan. Sangat disarankan untuk segera mencari bantuan profesional dari psikolog atau profesional kesehatan mental untuk mendapatkan penanganan yang tepat.';
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Hasil Kuis'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hasil),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Lanjutkan',
                    style: TextStyle(color: Color(0xFF0097A7))),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }
}
