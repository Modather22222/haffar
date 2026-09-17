import 'package:flutter/material.dart';
import '../design_system/colors.dart';



class SignInLoadingScreen extends StatelessWidget {
  const SignInLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/character/character (7).png', width: 160, height: 200),
            const SizedBox(height: 24),
            Text('جارٍ تسجيل الدخول...', style: TextStyle(fontFamily: 'DIN2014Rounded', fontSize: 18, fontWeight: FontWeight.w600, color: HaffarColors.grey3, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
