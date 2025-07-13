import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  String _email = '';
  String _password = '';

  Future<void> _trySubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();

    if (!isValid) return;

    _formKey.currentState?.save();

    setState(() => _isLoading = true);

    bool success;
    if (_isLogin) {
      success = await context.read<AuthProvider>().login(_email, _password);
    } else {
      success = await context.read<AuthProvider>().register(_email, _password);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please check your credentials and try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Sign up to get started',
                  style: textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  key: const ValueKey('email'),
                  validator: (value) => (value?.isEmpty ?? true) || !value!.contains('@') ? 'Please enter a valid email.' : null,
                  onSaved: (value) => _email = value ?? '',
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const ValueKey('password'),
                  validator: (value) => (value?.isEmpty ?? true) || value!.length < 7 ? 'Password must be at least 7 characters long.' : null,
                  onSaved: (value) => _password = value ?? '',
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _isLoading ? null : _trySubmit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLogin ? 'Login' : 'Sign Up'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Create new account' : 'I already have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 