import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService? authService;
  final ApiService? apiService;

  const HomeScreen({
    super.key,
    this.authService,
    this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    final isAnonymous = authService?.currentUser?.isAnonymous ?? true;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to HeyWish',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save, Share & Discover Perfect Gifts',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isAnonymous) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Start creating wishlists instantly!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (isAnonymous) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/wishlists');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Create Your First Wishlist',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'Sign Up to Save',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('Already have an account? Log In'),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/dashboard');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Go to Dashboard',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Features
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why HeyWish?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      Icons.add_shopping_cart,
                      'Save from Anywhere',
                      'Add items from any website with just a tap',
                    ),
                    _buildFeatureCard(
                      Icons.share,
                      'Share with Friends',
                      'Send your wishlist to anyone easily',
                    ),
                    _buildFeatureCard(
                      Icons.lock_outline,
                      'Secret Reservations',
                      'Friends can reserve gifts without you knowing',
                    ),
                    _buildFeatureCard(
                      Icons.trending_down,
                      'Price Tracking',
                      'Get notified when prices drop',
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

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B5CF6)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
      ),
    );
  }
}