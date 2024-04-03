import 'package:flutter/material.dart';

import '../utilities/colors.dart';

class UserTextInput extends StatelessWidget {
  final String labelName;
  final TextInputType textInputType;
  final TextEditingController textController;
  const UserTextInput({
    super.key,
    required this.labelName,
    required this.textInputType, required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              floatingLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, color: MVAColors.primaryColor),
              label: Text(
                labelName,
                style: const TextStyle(color: MVAColors.textColor),
              )),
          keyboardType: textInputType,
          controller: textController,
        ),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}
