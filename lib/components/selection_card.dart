import 'package:flutter/material.dart';

import '../utilities/colors.dart';

// ignore: must_be_immutable
class SelectionCard extends StatefulWidget {
  final String header;
  final List<String> electionSelected;
  late String selected;
  final Color textColor;
  final Color bgColor;
  final double textSize;
  final double dropDownWidth;

  SelectionCard(
      {super.key,
      required this.header,
      required this.electionSelected,
      required this.selected,
      required this.textColor,
      required this.bgColor,
      required this.textSize,
      required this.dropDownWidth});

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
              borderRadius: BorderRadius.circular(8), color: widget.bgColor),
          width: widget.dropDownWidth,
          height: 50,
          child: DropdownButton(
              iconEnabledColor: widget.textColor,
              borderRadius: BorderRadius.circular(5),
              // underline: Container(),
              padding: EdgeInsets.only(left: 20),
              dropdownColor: MVAColors.accentColor,
              itemHeight: 50,
              value: widget.selected,
              items: widget.electionSelected.map((value) {
                return DropdownMenuItem(
                    alignment: AlignmentDirectional.center,
                    value: value,
                    child: Center(
                      child: Text(value,
                          style: TextStyle(
                              color: widget.textColor,
                              fontSize: widget.textSize,
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
