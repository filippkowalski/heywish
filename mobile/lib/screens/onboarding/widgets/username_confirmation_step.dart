import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';

class UsernameConfirmationStep extends StatefulWidget {
  const UsernameConfirmationStep({super.key});

  @override
  State<UsernameConfirmationStep> createState() => _UsernameConfirmationStepState();
}

class _UsernameConfirmationStepState extends State<UsernameConfirmationStep>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _scaleController;
  
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _backgroundScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create icon animations
    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut,
    ));

    // Create text animations
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Create background scale animation
    _backgroundScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start background scale
    _scaleController.forward();
    
    // Wait a bit then start icon animation
    await Future.delayed(const Duration(milliseconds: 200));
    _iconController.forward();

    // Start text animation shortly after icon
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Auto-transition after animations complete
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.read<OnboardingService>().nextStep();
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<OnboardingService>(
        builder: (context, onboardingService, child) {
          final username = onboardingService.data.username ?? 'there';
          
          return AnimatedBuilder(
            animation: _backgroundScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _backgroundScaleAnimation.value,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon
                      AnimatedBuilder(
                        animation: Listenable.merge([_iconScaleAnimation, _iconRotationAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: Transform.rotate(
                              angle: _iconRotationAnimation.value * 0.1,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.waving_hand,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Animated text
                      AnimatedBuilder(
                        animation: Listenable.merge([_textFadeAnimation, _textSlideAnimation]),
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _textFadeAnimation,
                            child: SlideTransition(
                              position: _textSlideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                child: Text(
                                  'Nice to meet you, $username!',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 32,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}