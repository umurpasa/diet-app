import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../utils/error_messages.dart';

/// Kayıt ve giriş ekranı.
///
/// Supabase e-posta + şifre auth kullanır. Tek ekranda "Giriş yap" ve
/// "Kayıt ol" modları arasında geçiş yapılır. Oturum açıldığında yönlendirmeyi
/// `AuthGate` (main.dart) `onAuthStateChange` üzerinden otomatik yapar; bu
/// ekranın kendisi navigasyonla uğraşmaz.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true; // true: giriş, false: kayıt
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // await'lerden sonra context kullanmamak için metinler baştan alınır.
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final client = Supabase.instance.client;

    try {
      if (_isLogin) {
        await client.auth.signInWithPassword(email: email, password: password);
        // Başarılıysa AuthGate HomeScreen'e yönlendirir.
      } else {
        final res = await client.auth.signUp(email: email, password: password);
        // E-posta doğrulaması açıksa oturum hemen açılmaz.
        if (mounted && res.session == null) {
          _showMessage(l10n.authSignupSuccess);
          setState(() => _isLogin = true);
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } catch (e) {
      if (mounted) {
        _showMessage(
          isNetworkError(e)
              ? l10n.connectionError
              : l10n.unexpectedError(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.eco, size: 72, color: Colors.green.shade600),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? l10n.authWelcomeBack : l10n.authCreateAccount,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? l10n.authLoginSubtitle : l10n.authSignupSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.authEmailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return l10n.authEmailRequired;
                      if (!v.contains('@') || !v.contains('.')) {
                        return l10n.authEmailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) _submit();
                    },
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: l10n.authPasswordLabel,
                      helperText: l10n.authPasswordHelper,
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) return l10n.authPasswordRequired;
                      if (v.length < 6) return l10n.authPasswordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isLogin
                            ? l10n.authLoginButton
                            : l10n.authSignupButton),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? l10n.authToggleToSignup
                          : l10n.authToggleToLogin,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
