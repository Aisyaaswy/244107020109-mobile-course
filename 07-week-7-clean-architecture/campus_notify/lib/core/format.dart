String formatDate(DateTime dateTime) {
  final year = dateTime.year;
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String parseAnnouncementRoute(String path) {
  if (path.startsWith('/pengumuman/')) {
    return path.replaceFirst('/pengumuman/', '');
  }
  return '';
}
