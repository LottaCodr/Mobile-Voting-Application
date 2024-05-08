import 'package:flutter/material.dart';

class CustomSearchClass extends SearchDelegate {
  List<String> data = ['Mr. Barka', 'Worthy', 'Jiggy', 'Emmanuel', 'Peter Obi'];

  @override
  List<Widget> buildActions(BuildContext context) {
    //add the action needed for the search later, and a clear button

    //this will show clear query button
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear))
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    //add leading actions to be shown before the search

    //adding a back button to close the search

    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    //build the search results widget and its view

    //clear the old search list

    var filteredData =
        data.where((element) => element.startsWith(query)).toList();

    //view a list view with the search result

    return Container(
      margin: EdgeInsets.all(20),
      child: ListView(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          scrollDirection: Axis.vertical,
          children: List.generate(data.length, (index) {
            var item = filteredData[index];
            return Card(
              color: Colors.white,
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(item),
              ),
            );
          })),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    //show suggestions before search

    return Container();
  }
}
