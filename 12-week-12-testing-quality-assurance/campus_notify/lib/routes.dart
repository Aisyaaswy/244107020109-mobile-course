class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String announcement = '/pengumuman/:id';
  static const String notes = '/notes';
  static const String aiChat = '/ai-chat';

  // Helper untuk membuat rute pengumuman spesifik dengan ID
  static String announcementDetail(String id) => '/pengumuman/$id';
}
