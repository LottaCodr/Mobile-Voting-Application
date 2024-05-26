import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_voting_application/components/customSearchClass.dart';

class TheSearchBar extends StatefulWidget {
  const TheSearchBar({super.key});

  @override
  State<TheSearchBar> createState() => _TheSearchBarState();
}

class _TheSearchBarState extends State<TheSearchBar> {
  String query = '';

  void onQueryChanged(String newQuery) {
    setState(() {
      query = newQuery;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(10),
        child: IconButton(
            onPressed: () {
              showSearch(context: context, delegate: CustomSearchClass());
            },
            icon: const Icon(Icons.search)));
  }
}



// TextField(
//         controller: TextEditingController(),
//         keyboardType: TextInputType.text,
//         // textCapitalization: TextCapitalization.none,
//         onChanged: onQueryChanged,
//         decoration: InputDecoration(
//             labelText: 'Search...',
//             prefixIcon: Icon(Icons.search),
//             border: OutlineInputBorder()),
//       ),