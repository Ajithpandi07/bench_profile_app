import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/auth_event.dart';
import '../../presentation/bloc/auth_state.dart';
// Auth repository and bloc are provided by the app root via BlocProvider.

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  String _debugState = 'Unknown';

  void _submit() {
    // Dispatch sign in request to the AuthBloc provided by the widget tree.
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    context.read<AuthBloc>().add(SignInRequested(email: email, password: password));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // update visible debug state for quick feedback in the UI
        setState(() {
          _debugState = state.runtimeType.toString();
        });
        if (state is Authenticated) {
          // show an obvious SnackBar so auth success is visible on-device
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Authenticated: ${state.user.uid}')));
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => _LoggedInPage(userId: state.user.uid, email: state.user.email)));
        }
        if (state is AuthFailure) {
          // surface the failure both inline and via SnackBar
          setState(() {
            _error = state.message;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth failed: ${state.message}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign in')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // small debug banner so state transitions are visible on device
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Colors.yellow[100],
                child: Text('Debug state: $_debugState', style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 8),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return ElevatedButton(onPressed: loading ? null : _submit, child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoggedInPage extends StatelessWidget {
  final String userId;
  final String? email;
  const _LoggedInPage({required this.userId, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(child: Text('Welcome ${email ?? userId}')),
    );
  }
}
