import '../../core/supabase_client.dart';

class AuthService {
  Future<bool> loginAsAdmin(String email, String password) async {
    final res = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) return false;

    final data = await SupabaseService.client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return data['role'] == 'admin';
  }

  Future<void> logout() async {
    await SupabaseService.client.auth.signOut();
  }
}
