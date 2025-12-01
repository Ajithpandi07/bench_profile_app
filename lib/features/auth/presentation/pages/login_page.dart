import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
// Auth repository and bloc are provided by the app root via BlocProvider.
import 'sign_up_page.dart';
import '../../../health_metrics/presentation/pages/navigation_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Dispatch sign in request to the AuthBloc provided by the widget tree.
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      context.read<AuthBloc>().add(SignInRequested(email: email, password: password));
    }
  }

  void _openForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final _emailCtl = TextEditingController();
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(controller: _emailCtl, decoration: const InputDecoration(labelText: 'Email')),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            TextButton(onPressed: () {
              final email = _emailCtl.text.trim();
              if (email.isNotEmpty) {
                context.read<AuthBloc>().add(ForgotPasswordRequested(email: email));
                Navigator.of(ctx).pop();
              }
            }, child: const Text('Send'))
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NavigationContainer()));
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth failed: ${state.message}')));
        } else if (state is AuthPasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to continue your fitness journey',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => (value?.isEmpty ?? true) ? 'Please enter an email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a password' : null,
                      ),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _openForgotPassword, child: const Text('Forgot?'))),
                      const SizedBox(height: 8),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final loading = state is AuthLoading;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Log In', style: TextStyle(fontSize: 16)),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text("Don't have an account?"),
                        TextButton(
                            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignUpPage())),
                            child: const Text('Sign Up'))
                      ])
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}
