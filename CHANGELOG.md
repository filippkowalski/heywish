# Changelog

## [1.13.1+31] - 2025-11-25

### Added
- add in-app notification banner for foreground FCM notifications
- improve edit/delete button visibility in add wish page
- smart clipboard paste, iOS share extension, and bug fixes
- improve share tip timing - show after first successful add

### Changed
- remove grid/list view toggle from profile page

### Fixed
- add middleware to redirect broken multi-segment wishlist URLs
- prevent infinite refresh loop on authenticated page visits
- redirect to profile instead of 404 for invalid wishlist URLs
- prevent Apple Private Relay emails as usernames
- remove Center wrapper causing 'New List' button text truncation
- properly slugify wishlist names in share URLs
- prevent infinite wishlists fetch loop
- improve bulk wish import with smart image fallback
- Fix onboarding glitch: remove redundant loader in flow screen
- fix API key path resolution for iOS upload
- fix wish detail layout and share tip display issues
- improve error handling and prevent app crashes


All notable changes to Jinnie will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.12.1] - 2025-11-20

### Mobile App - Fixed
- **Wish Detail UI**: Fixed menu button not appearing for wishes without images - menu and close buttons now properly display in the same row for all wishes
- **Share Tip Display**: Resolved issue where first-time share extension tip wasn't showing after adding first wish from homepage
- **Context Stability**: Added proper timing delay to ensure UI context is stable when showing bottom sheets after navigation
- **Button Spacing**: Increased top spacing in wish detail sheets to prevent buttons from overlaying title text
- **Error Handling**: Improved app stability with better error handling to prevent crashes during wish operations

### Mobile App - Improved
- **Wish Detail Layout**: Enhanced layout for wishes without images with proper minimum height (140px) and spacing (80px top margin)
- **Share Tip UX**: Share extension tip now appears reliably after first successful wish creation with improved context checking
- **Debug Logging**: Added comprehensive debug logging for troubleshooting share tip and UI issues
- **UI Polish**: Refined wish card and detail screen UI for better visual consistency

### Build System - Fixed
- **Fastlane Configuration**: Fixed App Store Connect API key handling in iOS release pipeline
- **CI/CD**: Improved lane context management for more reliable automated builds

---

## [1.12.0] - 2025-11-19

### Mobile App - Added
- **Deep Linking for Add Wish**: Added comprehensive deep link support to open the add wish screen directly from App Store campaigns, marketing campaigns, and external sources
  - Universal links: `https://jinnie.app/add-wish`
  - Custom URL scheme: `jinnie://add-wish`
  - Supports optional query parameters for pre-filling product details (url, title, description, price, currency, wishlistId)
  - Enables seamless user onboarding from marketing campaigns to wish creation
  - Perfect for App Store In-App Events and promotional campaigns

### Mobile App - Improved
- **Image Optimization**: Converted PNG onboarding images to WebP format for 60-70% smaller file sizes and faster app loading
- **Onboarding Assets**: Optimized all onboarding screen images resulting in significant app size reduction
- **Deep Link Architecture**: Enhanced deep link service with better parameter handling and navigation stack management

---

## [1.11.0] - 2025-11-19

### Mobile App - Added
- **Enhanced Onboarding Experience**: Added entertaining rotating loading messages during user status checks across all supported languages
- **Image Cropping**: Users can now crop images when uploading wish or profile pictures for perfect framing
- **Wishlist Memory**: App now remembers your last used wishlist when adding new wishes for faster item entry
- **Public Profile Improvements**: Enhanced public profile UI with beautiful shared masonry card component
- **Feed Card Previews**: Description previews now visible on activity feed cards for better context
- **Dynamic Image Heights**: Implemented smart image height calculations for feed and wishlist grids, creating more visually appealing layouts
- **Username Generation API**: Integrated backend API for automatic username suggestions during onboarding

### Mobile App - Fixed
- **Loading Messages Bug**: Resolved TypeError in rotating loading messages during onboarding status checks
- **FCM Token Management**: Prevented premature API calls and duplicate Firebase Cloud Messaging token registrations
- **Image Display**: Fixed rounded corners issue on feed card images for cleaner appearance
- **Landscape Images**: Corrected image scaling for landscape-oriented images in masonry grid using contain fit
- **URL Launcher**: Improved reliability with canLaunchUrl checks and proper Android query intents configuration

### Mobile App - Improved
- **Wishlist Deletion**: Added clear warning messages when deleting wishlists to prevent accidental data loss
- **In-App Reviews**: Enhanced review prompt triggers for better user engagement timing
- **Image Compression**: Optimized image compression and upload performance for faster uploads
- **Fullscreen Viewer**: Made fullscreen image viewer dismissible with native transitions
- **Edit Wishlist UX**: Improved keyboard dismissal behavior and moved save button to AppBar for better accessibility

### Web Platform - Added
- **Gift Guides**: Launched comprehensive gift guides feature with 87+ hand-curated items across all categories
- **Inspiration Page**: New "Inspo" page featuring 40+ curated gift ideas for browsing and discovery
- **Browse Page**: Added dedicated browse page with header navigation link
- **Add to Wishlist**: Users can now add items directly to their wishlist from wish detail dialogs with prefilled data
- **Affiliate Tracking**: Integrated Skimlinks affiliate tracking for monetization
- **Analytics**: Added simple analytics script for user behavior insights

### Web Platform - Improved
- **Gift Guide Layout**: Enabled 5-column layout for gift guides on extra-large screens
- **Categorization**: Improved gift guide categorization with strict filtering logic
- **Data Quality**: Removed duplicate items from gift guides for cleaner browsing
- **Inspo Card UX**: Enhanced styling and user experience for inspiration cards

### Internal Dashboard - Added
- **Dark Mode**: Complete conversion to dark mode theme for reduced eye strain
- **Edit Wish Page**: New page for editing wish details directly from dashboard
- **URL Scraping**: Automated URL scraping functionality for bulk wish imports
- **Bulk Delete**: Added bulk delete features for efficient content management
- **Toast Notifications**: Implemented toast notifications across dashboard for better error visibility and feedback

### Developer Tools - Added
- **Fastlane Automation**: Comprehensive Fastlane setup for streamlined iOS and Android releases
- **Release Command**: New `/fastlane-release` slash command for complete release workflow
- **Version Management**: Simplified version management with Flutter variables
- **Android Release Lane**: Automated Android AAB building with automatic folder opening for easy upload

### Developer Tools - Improved
- **Error Logging**: Enhanced error logging throughout scraping process with detailed debug information
- **Upload Endpoints**: Improved upload reliability by using admin endpoints for scraping operations

---

## [1.10.0] - Previous Release

Initial release with core wishlist functionality, social features, and cross-platform support.
