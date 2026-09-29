part of "../../main.dart";

class AuthScreen extends StatefulWidget {
  final LokaleApi api;
  final ValueChanged<Map<String, dynamic>> onDone;
  const AuthScreen({super.key, required this.api, required this.onDone});
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool login = true, busy = false;
  String? error;
  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await widget.api.request(
        'POST',
        login ? '/api/auth/login' : '/api/auth/register',
        body: {
          if (!login) 'name': name.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
        },
      );
      await widget.api.saveToken(r['token']);
      widget.onDone(Map<String, dynamic>.from(r['user']));
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: BrandLogo(size: 76),
                ),
                const Text(
                  'Lokale',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: brand,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  login ? 'Welcome back' : 'Create your account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (!login)
                  TextField(
                    controller: name,
                    textInputAction: TextInputAction.next,
                    decoration: localizedInput(
                      context,
                      const InputDecoration(labelText: 'Name'),
                    ),
                  ),
                if (!login) const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Email'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: localizedInput(
                    context,
                    const InputDecoration(labelText: 'Password'),
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      busy
                          ? 'Please wait…'
                          : login
                          ? 'Sign in'
                          : 'Create account',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => login = !login),
                  child: Text(
                    login
                        ? 'New to Lokale? Create account'
                        : 'Already registered? Sign in',
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
