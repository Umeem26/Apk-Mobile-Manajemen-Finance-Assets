import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page.dart';
import 'main.dart'; // Untuk akses HomePage

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    // Tunggu 2 detik biar logonya tampil (Estetika)
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final String? ownerName = prefs.getString('owner_name');

    if (!mounted) return;

    // LOGIKA PENGECEKAN:
    if (ownerName != null && ownerName.isNotEmpty) {
      // Jika Nama SUDAH ADA -> Langsung ke Dashboard (HomePage)
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const HomePage())
      );
    } else {
      // Jika Nama BELUM ADA -> Ke Halaman Input Nama (Onboarding)
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const OnboardingPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E549F), // Warna Biru Polban
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO APLIKASI (Pastikan file assets/icon_ayam.png sudah ada)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/icon_ayam.png', width: 100),
            ),
            const SizedBox(height: 20),
            const Text(
              "SiKaya App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}