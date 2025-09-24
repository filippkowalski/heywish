import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';

class WelcomeStep extends StatefulWidget {
  const WelcomeStep({super.key});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  late Animation<double> _helloFadeAnimation;
  late Animation<double> _heyWishFadeAnimation;
  late Animation<Offset> _helloSlideAnimation;
  late Animation<Offset> _heyWishSlideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create fade animations
    _helloFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _heyWishFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
    ));

    // Create slide animations
    _helloSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _heyWishSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.4, 0.9, curve: Curves.elasticOut),
    ));

    // Create scale animation for background
    _scaleAnimation = Tween<double>(
      begin: 1.1,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start background scale animation
    _scaleController.forward();
    
    // Wait a bit then start text animations
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _slideController.forward();

    // Auto-transition after animations complete
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      context.read<OnboardingService>().nextStep();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with scale animation
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: screenSize.width,
                  height: screenSize.height,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/image/bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),


          // Animated Text Content
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // "Hello," text
                        AnimatedBuilder(
                          animation: Listenable.merge([_helloFadeAnimation, _helloSlideAnimation]),
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _helloFadeAnimation,
                              child: SlideTransition(
                                position: _helloSlideAnimation,
                                child: AutoSizeText(
                                  'Hello,',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black87,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  minFontSize: 24,
                                  maxFontSize: 48,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // "I'm HeyWish" text
                        AnimatedBuilder(
                          animation: Listenable.merge([_heyWishFadeAnimation, _heyWishSlideAnimation]),
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _heyWishFadeAnimation,
                              child: SlideTransition(
                                position: _heyWishSlideAnimation,
                                child: AutoSizeText(
                                  'I\'m HeyWish',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  minFontSize: 24,
                                  maxFontSize: 48,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}