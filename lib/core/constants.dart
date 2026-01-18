class AppConstants {
  static const String supabaseUrl = 'https://njrsvguasgkeytuozaxu.supabase.co';
  // Usando anon key com RLS - admins autenticados tem acesso via policies
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qcnN2Z3Vhc2drZXl0dW96YXh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2Nzk1MDIsImV4cCI6MjA4NDI1NTUwMn0.k1UMzPC1uQ2gc_ofWZeOext07ueG0u3xZEwTwuvbvpI';
  // Service role key para criar usuarios (usado apenas no admin)
  static const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qcnN2Z3Vhc2drZXl0dW96YXh1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODY3OTUwMiwiZXhwIjoyMDg0MjU1NTAyfQ.maMnv0QySiXKOJqvTSbBxgKtPAEqtpKCisRFY6ebpsI';
  static const String appName = 'Seguro Pneu Pro - Admin';
}
