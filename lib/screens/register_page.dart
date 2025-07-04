import 'package:flutter/material.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  // Store registered credentials in static variables
  static String? registeredEmail;
  static String? registeredPassword;

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 200, height: 200),
              const SizedBox(height: 24),
              const Text(
                'Stockly',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, color: Color(0xFFB0B3B8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Full Name',
                        hintStyle: const TextStyle(color: Color(0xFFB0B3B8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Email address',
                        hintStyle: const TextStyle(color: Color(0xFFB0B3B8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Color(0xFFB0B3B8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );
                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            setState(() {
                              _error = 'All fields are required';
                            });
                            return;
                          }
                          if (!emailRegex.hasMatch(email)) {
                            setState(() {
                              _error = 'Invalid email format';
                            });
                            return;
                          }
                          if (RegisterPage.registeredEmail == email) {
                            setState(() {
                              _error = 'Email is already registered';
                            });
                            return;
                          }
                          RegisterPage.registeredEmail = email;
                          RegisterPage.registeredPassword = password;
                          UserSession.username = name;
                          UserSession.email = email;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Color(0xFFB0B3B8)),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Login here',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
