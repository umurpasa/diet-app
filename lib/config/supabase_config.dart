/// Supabase bağlantı ayarları.
///
/// Not: anon key herkese açık olacak şekilde tasarlanmıştır (istemciye gömülür).
/// Güvenlik RLS ile sağlanır. GİZLİ olan `service_role` anahtarı BURAYA KONMAZ,
/// yalnızca sunucu tarafında (Edge Functions) kullanılır.
class SupabaseConfig {
  static const String url = 'https://myzcqjjdzjreomcnxche.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im15emNxampkempyZW9tY254Y2hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MDM5MTgsImV4cCI6MjA5ODQ3OTkxOH0.xX-xRw0gpKCmSZmNnHxcaycC0amhoPOOOJuJk66hzvE';
}
