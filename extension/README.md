# HeyWish Chrome Extension

Save products from any website to your HeyWish wishlists.

## Features

- 🛍️ Save products from any website with one click
- 🔍 Automatic product detection and information extraction
- 📝 Add notes to saved items
- 📁 Organize items into different wishlists
- 🔐 Secure authentication with your HeyWish account
- 👤 Support for anonymous usage

## Installation

### Development Mode

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" in the top right
3. Click "Load unpacked"
4. Select the `/extension` directory from this project

### Production (Coming Soon)

The extension will be available on the Chrome Web Store.

## Development

### Project Structure

```
extension/
├── manifest.json        # Extension manifest
├── assets/             # Icons and images
├── public/             # Popup HTML/CSS/JS
│   ├── popup.html
│   ├── popup.css
│   └── popup.js
└── src/                # Content and background scripts
    ├── background.js   # Service worker
    ├── content.js      # Content script
    └── content.css     # Content styles
```

### Building

Currently, the extension runs directly from source. A webpack build configuration is planned for production builds.

### Icons Required

The extension needs icon files in the following sizes:
- `assets/icon16.png` - 16x16px
- `assets/icon32.png` - 32x32px  
- `assets/icon48.png` - 48x48px
- `assets/icon128.png` - 128x128px

For the popup, also add:
- `public/icons/icon48.png` - Used in the popup header

## Usage

1. **First Time Setup**: Click the extension icon and sign in with your HeyWish account
2. **Save Products**: Navigate to any product page and click the extension icon
3. **Add to Wishlist**: Select a wishlist, add optional notes, and click "Save"
4. **Context Menu**: Right-click on any page, image, or link to save via context menu

## API Integration

The extension communicates with the HeyWish API at:
- Development: `http://localhost:3000`
- Production: `https://heywish.app`

## Permissions

The extension requires the following permissions:
- `activeTab`: To extract product information from the current tab
- `storage`: To store authentication tokens and user preferences
- `contextMenus`: To add right-click save functionality
- `scripting`: To inject content scripts for product detection
- `tabs`: To manage tab interactions

## Testing

1. Load the extension in development mode
2. Navigate to a product page (e.g., Amazon, eBay, etc.)
3. Click the extension icon
4. Verify product information is detected
5. Test saving to wishlist
6. Test authentication flow

## Known Issues

- Icons are placeholder and need to be replaced with actual HeyWish branding
- Some websites may block content script injection
- Price detection may not work on all e-commerce sites

## Contributing

See the main project README for contribution guidelines.