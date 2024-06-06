class GoogleFeature {
  Future<void> calendar() async {
    final title = '';
    final description = '';
    final start_time = DateTime.now().add(Duration(minutes: 30)).toString();
    final end_time = DateTime.now().add(Duration(minutes: 30)).toString();

    final url = 'http:/calendar.google.com/Calendar(render?action= CREATE)';
  }
}
