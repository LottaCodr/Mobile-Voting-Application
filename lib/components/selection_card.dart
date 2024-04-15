import 'package:flutter/material.dart';

import '../utilities/colors.dart';

// ignore: must_be_immutable
class SelectionCard extends StatefulWidget {
  final String header;
  final List<String> electionSelected;
  late String selected;
  SelectionCard(
      {super.key,
      required this.header,
      required this.electionSelected,
      required this.selected});

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.header),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: MVAColors.primaryColor),
          width: 150,
          height: 50,
          child: DropdownButton(
              iconEnabledColor: Colors.white,
              borderRadius: BorderRadius.circular(5),
              underline: Container(),
              padding: EdgeInsets.only(left: 20),
              dropdownColor: MVAColors.primaryColor,
              itemHeight: 50,
              value: widget.selected,
              items: widget.electionSelected.map((value) {
                return DropdownMenuItem(
                    alignment: AlignmentDirectional.center,
                    value: value,
                    child: Center(
                      child: Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  widget.selected = newValue!;
                });
              }),
        )
      ],
    );
  }
}
