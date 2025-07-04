import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Image.asset('assets/logo.png', width: 200, height: 200),
            const SizedBox(height: 48),
            const Text(
              'Welcome to Stockly',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your personal gateway to smarter investing',
              style: TextStyle(fontSize: 16, color: Color(0xFFB0B3B8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 300,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Let's Go",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_right_alt, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
