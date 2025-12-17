// lib/features/auth/presentation/pages/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/pages/health_metrics_dashboard.dart';
import 'package:bench_profile_app/features/auth/presentation/pages/sign_up_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    context
        .read<AuthBloc>()
        .add(SignInRequested(email: email, password: password));
  }

  void _openForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final _emailCtl = TextEditingController();
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
              controller: _emailCtl,
              decoration: const InputDecoration(labelText: 'Email')),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final email = _emailCtl.text.trim();
                if (email.isNotEmpty) {
                  context
                      .read<AuthBloc>()
                      .add(ForgotPasswordRequested(email: email));
                  Navigator.of(ctx).pop();
                } else {
                  // simple validation feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter email')));
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter an email';
    final email = v.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => const HealthMetricsDashboard()));
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Auth failed: ${state.message}')));
        } else if (state is AuthPasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password reset email sent')));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return Scaffold(
          body: Stack(
            children: [
              // Decorative circle top right
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Decorative circle bottom left
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text(
                            'SIGN IN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 48),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Username / email',
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: primary, width: 2),
                              ),
                            ),
                            validator: _validateEmail,
                          ),

                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: primary, width: 2),
                              ),
                            ),
                            validator: _validatePassword,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                onPressed: _openForgotPassword,
                                child: const Text('Forgot?')),
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('SIGN IN',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const SignUpPage())),
                                child: const Text('Sign up'),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
