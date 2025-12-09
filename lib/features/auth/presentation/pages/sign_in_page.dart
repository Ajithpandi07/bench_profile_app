import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/pages/navigation_container.dart';
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
  final _email = TextEditingController();
  final _password = TextEditingController();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _email.text.trim();
      final password = _password.text;
      context
          .read<AuthBloc>()
          .add(SignInRequested(email: email, password: password));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        (value?.isEmpty ?? true) ? 'Please enter an email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) => (value?.length ?? 0) < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (state is AuthLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(onPressed: _submit, child: const Text('Sign In')),
                  TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage())), child: const Text('Don\'t have an account? Sign Up'))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}