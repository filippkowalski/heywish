// Content script for HeyWish extension
// This script runs on all web pages and can extract product information

// Listen for messages from the extension popup or background script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'getProductData') {
    const productData = extractProductData();
    sendResponse(productData);
  } else if (request.action === 'highlightProduct') {
    highlightProductElements();
  }
  return true;
});

// Extract product data from the current page
function extractProductData() {
  const data = {
    url: window.location.href,
    title: null,
    price: null,
    image: null,
    description: null,
    currency: 'USD'
  };
  
  // Try to get structured data first (JSON-LD)
  const jsonLdScripts = document.querySelectorAll('script[type="application/ld+json"]');
  for (const script of jsonLdScripts) {
    try {
      const json = JSON.parse(script.textContent);
      if (json['@type'] === 'Product' || json['@type']?.includes('Product')) {
        data.title = json.name || data.title;
        data.description = json.description || data.description;
        data.image = json.image || data.image;
        
        if (json.offers) {
          const offers = Array.isArray(json.offers) ? json.offers[0] : json.offers;
          data.price = offers.price || data.price;
          data.currency = offers.priceCurrency || data.currency;
        }
      }
    } catch (e) {
      // Invalid JSON, skip
    }
  }
  
  // Fallback to Open Graph meta tags
  if (!data.title) {
    const ogTitle = document.querySelector('meta[property="og:title"]');
    data.title = ogTitle?.content || document.title;
  }
  
  if (!data.image) {
    const ogImage = document.querySelector('meta[property="og:image"]');
    data.image = ogImage?.content;
  }
  
  if (!data.description) {
    const ogDescription = document.querySelector('meta[property="og:description"]');
    data.description = ogDescription?.content;
  }
  
  // Try to find price if not found in structured data
  if (!data.price) {
    data.price = findPrice();
  }
  
  // Clean up the data
  if (data.title) {
    data.title = data.title.trim().substring(0, 200);
  }
  
  if (data.description) {
    data.description = data.description.trim().substring(0, 500);
  }
  
  if (data.price && typeof data.price === 'string') {
    // Extract numeric value from price string
    const priceMatch = data.price.match(/[\d,]+\.?\d*/);
    if (priceMatch) {
      data.price = parseFloat(priceMatch[0].replace(',', ''));
    }
  }
  
  return data;
}

// Find price on the page using various heuristics
function findPrice() {
  const pricePatterns = [
    /\$[\d,]+\.?\d*/,
    /USD\s*[\d,]+\.?\d*/,
    /[\d,]+\.?\d*\s*USD/,
    /£[\d,]+\.?\d*/,
    /€[\d,]+\.?\d*/
  ];
  
  // Check meta tags for price
  const priceMetaTags = [
    'meta[property="product:price:amount"]',
    'meta[property="og:price:amount"]',
    'meta[itemprop="price"]',
    'meta[name="twitter:data1"]'
  ];
  
  for (const selector of priceMetaTags) {
    const tag = document.querySelector(selector);
    if (tag?.content) {
      return tag.content;
    }
  }
  
  // Check common price selectors
  const priceSelectors = [
    '[itemprop="price"]',
    '[data-price]',
    '.price',
    '.product-price',
    '.sale-price',
    '.regular-price',
    '[class*="price-now"]',
    '[class*="price-sale"]',
    '[class*="product-price"]',
    '[class*="item-price"]',
    '[id*="price"]',
    'span[class*="price"]',
    'div[class*="price"]',
    'p[class*="price"]'
  ];
  
  for (const selector of priceSelectors) {
    const elements = document.querySelectorAll(selector);
    for (const element of elements) {
      const text = element.textContent || element.getAttribute('content') || element.getAttribute('data-price');
      if (text) {
        for (const pattern of pricePatterns) {
          const match = text.match(pattern);
          if (match) {
            return match[0];
          }
        }
      }
    }
  }
  
  return null;
}

// Highlight product elements on the page (for visual feedback)
function highlightProductElements() {
  const style = document.createElement('style');
  style.textContent = `
    @keyframes heywish-pulse {
      0% { box-shadow: 0 0 0 0 rgba(139, 92, 246, 0.7); }
      70% { box-shadow: 0 0 0 10px rgba(139, 92, 246, 0); }
      100% { box-shadow: 0 0 0 0 rgba(139, 92, 246, 0); }
    }
    
    .heywish-highlight {
      animation: heywish-pulse 2s;
      border: 2px solid #8B5CF6 !important;
    }
  `;
  document.head.appendChild(style);
  
  // Find and highlight main product image
  const imageSelectors = [
    '[itemprop="image"]',
    '.product-image',
    '.product-photo',
    '[class*="product-image"]',
    '[class*="product-photo"]',
    '[class*="main-image"]'
  ];
  
  for (const selector of imageSelectors) {
    const element = document.querySelector(selector);
    if (element) {
      element.classList.add('heywish-highlight');
      break;
    }
  }
  
  // Remove highlight after animation
  setTimeout(() => {
    document.querySelectorAll('.heywish-highlight').forEach(el => {
      el.classList.remove('heywish-highlight');
    });
  }, 2000);
}

// Check if we're on the HeyWish website for auth sync
if (window.location.hostname === 'localhost' || window.location.hostname === 'heywish.app') {
  // Listen for auth events
  window.addEventListener('message', (event) => {
    if (event.data.type === 'HEYWISH_AUTH_SUCCESS') {
      // Send auth data to extension
      chrome.runtime.sendMessage({
        type: 'AUTH_SUCCESS',
        token: event.data.token,
        email: event.data.email
      });
    }
  });
  
  // Inject a script to capture auth data
  const script = document.createElement('script');
  script.textContent = `
    // Listen for successful authentication
    const originalFetch = window.fetch;
    window.fetch = async function(...args) {
      const response = await originalFetch.apply(this, args);
      
      // Check if this is an auth sync request
      if (args[0]?.includes('/api/auth/sync') && response.ok) {
        const clonedResponse = response.clone();
        const data = await clonedResponse.json();
        
        if (data.token && data.user) {
          window.postMessage({
            type: 'HEYWISH_AUTH_SUCCESS',
            token: data.token,
            email: data.user.email
          }, '*');
        }
      }
      
      return response;
    };
  `;
  document.documentElement.appendChild(script);
  script.remove();
}