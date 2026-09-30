import 'package:flutter/material.dart';

import '../data/questions.dart';
import '../screens/sleep_timer_page.dart';
import '../widgets/questionnaire_form.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.lightBlue.shade100,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: Container(height: 6.0, color: Colors.lightBlueAccent),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  ...appQuestions.map((q) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SleepTimerPage(question: q),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        q,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Tippe hier, um die Zeit zu erfassen',
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  const QuestionnaireForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
