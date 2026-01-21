class AppConstants {
  static const String supabaseUrl = 'https://njrsvguasgkeytuozaxu.supabase.co';

  // Anon key com RLS - admins autenticados tem acesso via policies
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qcnN2Z3Vhc2drZXl0dW96YXh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2Nzk1MDIsImV4cCI6MjA4NDI1NTUwMn0.k1UMzPC1uQ2gc_ofWZeOext07ueG0u3xZEwTwuvbvpI';

  // IMPORTANTE: A service role key foi removida do frontend por seguranca.
  // Operacoes administrativas agora sao feitas via Edge Functions.
  // A service key esta configurada apenas no servidor Supabase (environment variables).

  static const String appName = 'Seguro Pneu Pro - Admin';
}
