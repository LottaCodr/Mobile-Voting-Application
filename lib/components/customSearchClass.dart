import 'package:flutter/material.dart';

class CustomSearchClass extends SearchDelegate {
  List<String> data = ['Mr. Barka', 'Worthy', 'Jiggy', 'Emmanuel', 'Peter Obi'];

  @override
  List<Widget> buildActions(BuildContext context) {
    // Action to clear the search query
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // Back button to close the search
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Clear the old search list
    var filteredData =
        data.where((element) => element.startsWith(query)).toList();

    // Display search results with a clear message if no results found
    return Container(
      margin: const EdgeInsets.all(20),
      child: filteredData.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              scrollDirection: Axis.vertical,
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                var item = filteredData[index];
                return Card(
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(item),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                'No results found for "$query"',
                style: TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show suggestions before search (optional, you can remove this)
    var filteredData =
        data.where((element) => element.startsWith(query)).toList();

    // Display search results with a clear message if no results found
    return Container(
      margin: const EdgeInsets.all(20),
      child: filteredData.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              scrollDirection: Axis.vertical,
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                var item = filteredData[index];
                return Card(
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(item),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                'No results found for "$query"',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    // Customize the search bar appearance
    final themeData = super.appBarTheme(context);
    return themeData.copyWith(
      hintColor: Colors.grey,
      textTheme: themeData.textTheme.copyWith(
        titleLarge: TextStyle(
          color: Colors.black,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
