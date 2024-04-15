import 'package:flutter/material.dart';
import 'package:mobile_voting_application/components/button.dart';
import 'package:mobile_voting_application/utilities/colors.dart';

class CandidateScreen extends StatelessWidget {
  final String? name;
  const CandidateScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          name ?? 'Loading...',
          style: const TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
        child: Button(
            text: "Vote Now", color: MVAColors.primaryColor, onPressed: () {}),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: MVAColors.primaryColor,
                      borderRadius: BorderRadius.circular(20)),
                  width: MediaQuery.of(context).size.width,
                  height: 300,
                ),
                const SizedBox(
                  height: 15,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [CircleAvatar(), Text(' Party Name')],
                    ),
                    Row(
                      children: [
                        Text(
                          ' 30.5K',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: MVAColors.primaryColor),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text('People Voted')
                      ],
                    )
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                    "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum. It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
