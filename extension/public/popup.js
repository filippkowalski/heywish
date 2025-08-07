// State management
let currentUser = null;
let wishlists = [];
let productData = null;

// Initialize popup
document.addEventListener('DOMContentLoaded', async () => {
  await checkAuthState();
  await detectProduct();
  setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
  document.getElementById('loginBtn')?.addEventListener('click', handleLogin);
  document.getElementById('continueAnonymous')?.addEventListener('click', handleAnonymousLogin);
  document.getElementById('saveBtn')?.addEventListener('click', handleSave);
  document.getElementById('settingsBtn')?.addEventListener('click', showSettings);
  document.getElementById('backBtn')?.addEventListener('click', hideSettings);
  document.getElementById('dashboardBtn')?.addEventListener('click', openDashboard);
  document.getElementById('logoutBtn')?.addEventListener('click', handleLogout);
  document.getElementById('manualAddBtn')?.addEventListener('click', handleManualAdd);
}

// Check authentication state
async function checkAuthState() {
  try {
    const result = await chrome.storage.local.get(['authToken', 'userEmail']);
    
    if (result.authToken) {
      currentUser = {
        token: result.authToken,
        email: result.userEmail || 'Anonymous User'
      };
      
      // Update user email in settings
      const userEmailElement = document.getElementById('userEmail');
      if (userEmailElement) {
        userEmailElement.textContent = currentUser.email;
      }
      
      await loadWishlists();
    }
  } catch (error) {
    console.error('Error checking auth state:', error);
  }
}

// Load user's wishlists
async function loadWishlists() {
  try {
    const response = await fetch('http://localhost:3000/api/wishlists', {
      headers: {
        'Authorization': `Bearer ${currentUser.token}`
      }
    });
    
    if (response.ok) {
      const data = await response.json();
      wishlists = data.wishlists;
      updateWishlistSelect();
    }
  } catch (error) {
    console.error('Error loading wishlists:', error);
  }
}

// Update wishlist dropdown
function updateWishlistSelect() {
  const select = document.getElementById('wishlistSelect');
  if (!select) return;
  
  select.innerHTML = '';
  
  if (wishlists.length === 0) {
    select.innerHTML = '<option value="">No wishlists found</option>';
    select.innerHTML += '<option value="new">+ Create new wishlist</option>';
  } else {
    wishlists.forEach(wishlist => {
      const option = document.createElement('option');
      option.value = wishlist.id;
      option.textContent = wishlist.title;
      select.appendChild(option);
    });
    
    const newOption = document.createElement('option');
    newOption.value = 'new';
    newOption.textContent = '+ Create new wishlist';
    select.appendChild(newOption);
  }
}

// Detect product on current page
async function detectProduct() {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    
    // Inject content script to scrape product data
    const results = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: scrapeProductData
    });
    
    productData = results[0].result;
    
    if (productData && productData.title) {
      showProductView();
    } else {
      showNoProductView();
    }
  } catch (error) {
    console.error('Error detecting product:', error);
    showNoProductView();
  }
}

// Scrape product data from the page
function scrapeProductData() {
  const data = {
    url: window.location.href,
    title: null,
    price: null,
    image: null,
    description: null
  };
  
  // Try to get Open Graph meta tags first
  const ogTitle = document.querySelector('meta[property="og:title"]');
  const ogImage = document.querySelector('meta[property="og:image"]');
  const ogDescription = document.querySelector('meta[property="og:description"]');
  
  data.title = ogTitle?.content || document.title;
  data.image = ogImage?.content;
  data.description = ogDescription?.content;
  
  // Try to find price
  const pricePatterns = [
    /\$[\d,]+\.?\d*/,
    /USD\s*[\d,]+\.?\d*/,
    /[\d,]+\.?\d*\s*USD/
  ];
  
  // Check meta tags for price
  const priceMetaTags = [
    'meta[property="product:price:amount"]',
    'meta[property="og:price:amount"]',
    'meta[itemprop="price"]'
  ];
  
  for (const selector of priceMetaTags) {
    const tag = document.querySelector(selector);
    if (tag?.content) {
      data.price = tag.content;
      break;
    }
  }
  
  // If no price in meta tags, search in common price selectors
  if (!data.price) {
    const priceSelectors = [
      '.price',
      '[class*="price"]',
      '[id*="price"]',
      'span[itemprop="price"]',
      '.product-price',
      '.sale-price'
    ];
    
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
  }
  
  return data;
}

// Show different views
function showProductView() {
  hideAllViews();
  
  if (!currentUser) {
    document.getElementById('login').classList.remove('hidden');
    return;
  }
  
  const productView = document.getElementById('product');
  productView.classList.remove('hidden');
  
  // Update product info
  if (productData) {
    document.getElementById('productTitle').textContent = productData.title || 'Unknown Product';
    document.getElementById('productPrice').textContent = productData.price || 'Price not available';
    
    const productImage = document.getElementById('productImage');
    if (productData.image) {
      productImage.src = productData.image;
      productImage.style.display = 'block';
    } else {
      productImage.style.display = 'none';
    }
  }
}

function showNoProductView() {
  hideAllViews();
  
  if (!currentUser) {
    document.getElementById('login').classList.remove('hidden');
    return;
  }
  
  document.getElementById('noProduct').classList.remove('hidden');
}

function showSettings() {
  hideAllViews();
  document.getElementById('settings').classList.remove('hidden');
}

function hideSettings() {
  document.getElementById('settings').classList.add('hidden');
  if (productData && productData.title) {
    showProductView();
  } else {
    showNoProductView();
  }
}

function hideAllViews() {
  document.getElementById('loading').classList.add('hidden');
  document.getElementById('login').classList.add('hidden');
  document.getElementById('product').classList.add('hidden');
  document.getElementById('noProduct').classList.add('hidden');
  document.getElementById('settings').classList.add('hidden');
}

// Handle authentication
async function handleLogin() {
  chrome.tabs.create({ url: 'http://localhost:3000/auth/login?extension=true' });
  window.close();
}

async function handleAnonymousLogin() {
  // For now, just proceed without auth
  currentUser = {
    token: 'anonymous',
    email: 'Anonymous User'
  };
  
  await chrome.storage.local.set({
    authToken: 'anonymous',
    userEmail: 'Anonymous User'
  });
  
  if (productData && productData.title) {
    showProductView();
  } else {
    showNoProductView();
  }
}

async function handleLogout() {
  await chrome.storage.local.remove(['authToken', 'userEmail']);
  currentUser = null;
  wishlists = [];
  hideSettings();
  document.getElementById('login').classList.remove('hidden');
}

// Handle saving product
async function handleSave() {
  const wishlistId = document.getElementById('wishlistSelect').value;
  const notes = document.getElementById('notes').value;
  
  if (!wishlistId || wishlistId === 'new') {
    // Handle creating new wishlist
    const title = prompt('Enter wishlist name:');
    if (!title) return;
    
    try {
      const response = await fetch('http://localhost:3000/api/wishlists', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${currentUser.token}`
        },
        body: JSON.stringify({
          title,
          description: '',
          is_public: false
        })
      });
      
      if (response.ok) {
        const newWishlist = await response.json();
        wishlists.push(newWishlist);
        updateWishlistSelect();
        document.getElementById('wishlistSelect').value = newWishlist.id;
        // Continue to save the item
      } else {
        alert('Failed to create wishlist');
        return;
      }
    } catch (error) {
      console.error('Error creating wishlist:', error);
      alert('Failed to create wishlist');
      return;
    }
  }
  
  // Save the item
  try {
    const saveBtn = document.getElementById('saveBtn');
    saveBtn.disabled = true;
    saveBtn.textContent = 'Saving...';
    
    const response = await fetch('http://localhost:3000/api/wishes', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${currentUser.token}`
      },
      body: JSON.stringify({
        wishlist_id: document.getElementById('wishlistSelect').value,
        title: productData.title,
        url: productData.url,
        price: parseFloat(productData.price?.replace(/[^0-9.]/g, '')) || null,
        image_url: productData.image,
        notes: notes || null
      })
    });
    
    if (response.ok) {
      document.getElementById('successMessage').classList.remove('hidden');
      document.getElementById('notes').value = '';
      
      setTimeout(() => {
        document.getElementById('successMessage').classList.add('hidden');
      }, 3000);
    } else {
      alert('Failed to save item');
    }
  } catch (error) {
    console.error('Error saving item:', error);
    alert('Failed to save item');
  } finally {
    const saveBtn = document.getElementById('saveBtn');
    saveBtn.disabled = false;
    saveBtn.textContent = 'Save to Wishlist';
  }
}

// Handle manual add
function handleManualAdd() {
  chrome.tabs.create({ url: 'http://localhost:3000/wishlists' });
  window.close();
}

// Open dashboard
function openDashboard() {
  chrome.tabs.create({ url: 'http://localhost:3000/dashboard' });
  window.close();
}

// Listen for auth updates from the website
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'AUTH_SUCCESS') {
    chrome.storage.local.set({
      authToken: message.token,
      userEmail: message.email
    });
    currentUser = {
      token: message.token,
      email: message.email
    };
    loadWishlists();
  }
});