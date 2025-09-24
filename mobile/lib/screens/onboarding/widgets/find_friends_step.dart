import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/contacts_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/skeleton_loading.dart';

class FindFriendsStep extends StatefulWidget {
  const FindFriendsStep({super.key});

  @override
  State<FindFriendsStep> createState() => _FindFriendsStepState();
}

class _FindFriendsStepState extends State<FindFriendsStep> {
  late ContactsService _contactsService;
  bool _hasRequestedPermission = false;
  bool _contactPermissionGranted = false;
  bool _isSearchingFriends = false;

  @override
  void initState() {
    super.initState();
    _contactsService = ContactsService();
  }

  @override
  void dispose() {
    _contactsService.dispose();
    super.dispose();
  }

  Future<void> _requestContactsAndFindFriends() async {
    setState(() {
      _hasRequestedPermission = true;
      _isSearchingFriends = true;
    });

    try {
      // Request contact permission
      final permissionGranted = await _contactsService.requestContactPermission();
      
      setState(() {
        _contactPermissionGranted = permissionGranted;
      });

      final onboardingService = context.read<OnboardingService>();
      onboardingService.updateContactPermission(permissionGranted);

      if (permissionGranted) {
        // Privacy-first friend discovery (only phone numbers sent to server)
        final success = await _contactsService.findFriendsFromContacts();
        
        if (success) {
          // Update onboarding service with friend suggestions
          onboardingService.updateFriendSuggestions(_contactsService.friendSuggestions);
        }
      }
    } catch (e) {
      debugPrint('Error during friend discovery: $e');
    } finally {
      setState(() {
        _isSearchingFriends = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _contactsService,
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Find your friends',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Connect with friends who are already using HeyWish',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (!_hasRequestedPermission) ...[
              // Contact Permission Request Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outline,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Privacy-first friend discovery',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'We\'ll check your contacts locally and only send phone numbers to find matches',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Privacy points
                    _buildPrivacyPoint(
                      '🔒 Contact names stay on your device',
                      'We never see your contact names or other personal info',
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildPrivacyPoint(
                      '📱 Only phone numbers are checked',
                      'We only send normalized phone numbers for matching',
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildPrivacyPoint(
                      '👥 You control your visibility',
                      'Others can only find you if you allow it',
                    ),
                  ],
                ),
              ),
            ] else if (_isSearchingFriends) ...[
              // Loading state with skeleton
              if (_contactPermissionGranted) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Finding your friends...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Checking phone numbers privately',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Skeleton loading for friend suggestions
                    ...List.generate(3, (index) => 
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SkeletonFriendItem(),
                      )
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.block,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Permission denied',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cannot find friends without contact access',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Results
              Consumer<ContactsService>(
                builder: (context, contactsService, child) {
                  return Consumer<OnboardingService>(
                    builder: (context, onboardingService, child) {
                      final friendSuggestions = onboardingService.data.friendSuggestions;
                      
                      if (!_contactPermissionGranted) {
                        return _buildNoPermissionResult();
                      } else if (friendSuggestions.isEmpty) {
                        return _buildNoFriendsFoundResult();
                      } else {
                        return _buildFriendSuggestions(friendSuggestions);
                      }
                    },
                  );
                },
              ),
            ],
            
            const SizedBox(height: 40), // Less spacing since button is now fixed
                  ],
                ),
              ),
            ),
          ),
          
          // Fixed bottom section
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
            child: Column(
              children: [
                // Action Buttons
                if (!_hasRequestedPermission) ...[
                  PrimaryButton(
                    text: 'Find Friends (Privacy-First)',
                    onPressed: _requestContactsAndFindFriends,
                    isLoading: _isSearchingFriends,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  TextButton(
                    onPressed: () {
                      context.read<OnboardingService>().nextStep();
                    },
                    child: Text(
                      'Skip for now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ] else ...[
                  Consumer<OnboardingService>(
                    builder: (context, onboardingService, child) {
                      return PrimaryButton(
                        text: 'Continue',
                        onPressed: onboardingService.nextStep,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user,
          size: 20,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoPermissionResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Contact access not granted',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can still add friends manually later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoFriendsFoundResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No friends found yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite your friends to join HeyWish and start sharing wishlists!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendSuggestions(List<Map<String, dynamic>> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Friends found! 🎉',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'We found ${suggestions.length} friends who are already on HeyWish',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final friend = suggestions[index];
            return _buildFriendSuggestionItem(friend);
          },
        ),
      ],
    );
  }

  Widget _buildFriendSuggestionItem(Map<String, dynamic> friend) {
    final name = friend['full_name'] ?? friend['username'] ?? 'Unknown';
    final username = friend['username'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.person_add_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}