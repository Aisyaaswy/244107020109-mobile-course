class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String announcement = '/pengumuman/:id';

  // Helper untuk membuat rute pengumuman spesifik dengan ID
  static String announcementDetail(String id) => '/pengumuman/$id';
}