import 'package:flutter/material.dart';

import '../../components/button.dart';

class home extends StatelessWidget {
  const home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Button(
          text: 'Create an Account',
          onPressed: () {},
        ),
      ),
    );
  }
}
