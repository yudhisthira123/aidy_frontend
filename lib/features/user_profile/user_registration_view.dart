

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/user_profile/registration_provider.dart';

import '../../main.dart';
import '../brand_log.dart';

class UserRegistrationView extends ConsumerStatefulWidget {

  const UserRegistrationView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _UserRegistrationViewState();
  }

}

class _UserRegistrationViewState extends ConsumerState<UserRegistrationView> {

  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();

  bool isLoginMode = false,
      isButtonEnabled = false;

  Future<void> submit() async {
    setState(() {
      isButtonEnabled = false;
    });

    try {

      print(email.text);
      print(password.text);

    }catch(e) {

    }finally {
      isButtonEnabled = false;
    }
  }

  bool isEmpty() {
    setState(() {
      if (isLoginMode && (email.text.trim() != "") && (password.text.trim() != "")) {
        isButtonEnabled = true;

      } else if (!isLoginMode && (email.text.trim() != "") && (password.text.trim() != "") && (name.text.trim() != "")) {
        isButtonEnabled = true;
      }
      else {
        isButtonEnabled = false;
      }
    });

    return isButtonEnabled;
  }

  @override
  void initState() {
    if ((email.text.trim() != "") && (password.text.trim() != "")) {
      isButtonEnabled = true;
    } else {
      isButtonEnabled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
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
                  isLoginMode ? 'Welcome back' : 'Create your account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if(!isLoginMode)
                TextField(
                  onChanged: (val){
                    isEmpty();
                  },
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val){
                    isEmpty();
                  },
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val){
                    isEmpty();
                  },
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),

                const SizedBox(height: 18),
                FilledButton(
                  onPressed: isButtonEnabled ? submit : null,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      isLoginMode
                      ? 'Sign in'
                      : 'Create account',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLoginMode = !isLoginMode;
                    });
                  },
                  child: Text(
                    isLoginMode
                    ? 'New to Lokale? Create account'
                    : 'Already registered? Sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}