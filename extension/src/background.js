// Background service worker for HeyWish extension

// Listen for extension installation
chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    // Open welcome page on first install
    chrome.tabs.create({
      url: 'http://localhost:3000/auth/login?extension=welcome'
    });
  }
  
  // Create context menu item
  chrome.contextMenus.create({
    id: 'save-to-heywish',
    title: 'Save to HeyWish',
    contexts: ['page', 'image', 'link']
  });
});

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === 'save-to-heywish') {
    handleContextMenuSave(info, tab);
  }
});

// Handle context menu save
async function handleContextMenuSave(info, tab) {
  let productData = {
    url: info.pageUrl,
    title: tab.title,
    image: null,
    price: null,
    description: null
  };
  
  // If right-clicked on an image, use that as the product image
  if (info.mediaType === 'image') {
    productData.image = info.srcUrl;
  }
  
  // If right-clicked on a link, save the linked page instead
  if (info.linkUrl) {
    productData.url = info.linkUrl;
    // Try to extract title from link text
    const results = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: (linkUrl) => {
        const link = document.querySelector(`a[href="${linkUrl}"]`);
        return link?.textContent?.trim();
      },
      args: [info.linkUrl]
    });
    
    if (results[0]?.result) {
      productData.title = results[0].result;
    }
  }
  
  // Try to get more product data from the page
  const pageData = await chrome.scripting.executeScript({
    target: { tabId: tab.id },
    func: extractProductData
  });
  
  if (pageData[0]?.result) {
    productData = { ...productData, ...pageData[0].result };
  }
  
  // Save to storage for popup to use
  await chrome.storage.local.set({ pendingProduct: productData });
  
  // Open the popup
  chrome.action.openPopup();
}

// Extract product data function (same as in content script)
function extractProductData() {
  const data = {
    url: window.location.href,
    title: null,
    price: null,
    image: null,
    description: null
  };
  
  // Try Open Graph meta tags
  const ogTitle = document.querySelector('meta[property="og:title"]');
  const ogImage = document.querySelector('meta[property="og:image"]');
  const ogDescription = document.querySelector('meta[property="og:description"]');
  
  data.title = ogTitle?.content || document.title;
  data.image = ogImage?.content;
  data.description = ogDescription?.content;
  
  // Try to find price
  const pricePatterns = [/\$[\d,]+\.?\d*/, /USD\s*[\d,]+\.?\d*/];
  const priceSelectors = ['.price', '[class*="price"]', '[itemprop="price"]'];
  
  for (const selector of priceSelectors) {
    const element = document.querySelector(selector);
    if (element) {
      const text = element.textContent;
      for (const pattern of pricePatterns) {
        const match = text.match(pattern);
        if (match) {
          data.price = match[0];
          break;
        }
      }
      if (data.price) break;
    }
  }
  
  return data;
}

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'AUTH_SUCCESS') {
    // Store auth data
    chrome.storage.local.set({
      authToken: message.token,
      userEmail: message.email
    });
    
    // Notify all tabs
    chrome.tabs.query({}, (tabs) => {
      tabs.forEach(tab => {
        chrome.tabs.sendMessage(tab.id, {
          type: 'AUTH_UPDATE',
          authenticated: true
        }).catch(() => {
          // Tab doesn't have content script, ignore
        });
      });
    });
  } else if (message.type === 'GET_PRODUCT_DATA') {
    // Get product data from current tab
    chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
      if (tabs[0]) {
        const results = await chrome.scripting.executeScript({
          target: { tabId: tabs[0].id },
          func: extractProductData
        });
        sendResponse(results[0]?.result);
      }
    });
    return true; // Keep message channel open
  }
});

// Handle auth flow
chrome.webNavigation.onCompleted.addListener(
  async (details) => {
    // Check if this is our auth callback
    const url = new URL(details.url);
    if (url.pathname === '/auth/extension-callback') {
      const token = url.searchParams.get('token');
      const email = url.searchParams.get('email');
      
      if (token && email) {
        // Store auth data
        await chrome.storage.local.set({
          authToken: token,
          userEmail: email
        });
        
        // Close the auth tab
        chrome.tabs.remove(details.tabId);
        
        // Open success page or return to previous tab
        chrome.tabs.create({
          url: 'http://localhost:3000/dashboard?extension=success'
        });
      }
    }
  },
  {
    url: [
      { hostEquals: 'localhost', pathPrefix: '/auth/extension-callback' },
      { hostEquals: 'heywish.app', pathPrefix: '/auth/extension-callback' }
    ]
  }
);

// Handle alarm for periodic tasks (like checking auth status)
chrome.alarms.create('checkAuth', { periodInMinutes: 60 });

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === 'checkAuth') {
    const { authToken } = await chrome.storage.local.get('authToken');
    if (authToken && authToken !== 'anonymous') {
      // Verify token is still valid
      try {
        const response = await fetch('http://localhost:3000/api/auth/verify', {
          headers: {
            'Authorization': `Bearer ${authToken}`
          }
        });
        
        if (!response.ok) {
          // Token is invalid, clear auth
          await chrome.storage.local.remove(['authToken', 'userEmail']);
        }
      } catch (error) {
        console.error('Error verifying auth:', error);
      }
    }
  }
});