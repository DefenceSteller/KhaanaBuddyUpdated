import 'package:flutter/material.dart';
import 'package:khaanabuddy/screens/home_screen.dart';
import 'package:khaanabuddy/themes/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 🔹 Logo scale-in animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    // 🔹 Land new users straight on Home — browsing works as a guest,
    //    login is only asked for when saving a recipe.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: Stack(
        children: [
          // 🔹 Soft light + gold blobs
          Positioned(
            top: -90,
            right: -70,
            child: _blob(220, const Color(0x26FFFFFF)),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _blob(260, const Color(0x1A3D280A)),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: _blob(120, const Color(0x33F2A93B)),
          ),

          // 🔹 Center content
          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _animation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo card
                    Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x402E1408),
                            blurRadius: 40,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'lib/assets/CookMate_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "KhaanaBuddy",
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 800),
                          FontVariation('opsz', 72),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your AI Cooking Companion",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xE6FFFFFF),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w400,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 400),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading bar
                    SizedBox(
                      width: 130,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          minHeight: 6,
                          color: AppColors.accent,
                          backgroundColor: Color(0x4DFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
