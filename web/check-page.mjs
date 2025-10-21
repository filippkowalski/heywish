import { chromium } from 'playwright';

const browser = await chromium.launch();
const context = await browser.newContext();
const page = await context.newPage();

// Listen for console logs
page.on('console', msg => console.log('BROWSER LOG:', msg.text()));

// Listen for errors
page.on('pageerror', error => console.log('PAGE ERROR:', error.message));

// Listen for network failures
page.on('requestfailed', request => {
  console.log('REQUEST FAILED:', request.url(), request.failure().errorText);
});

try {
  console.log('Navigating to https://jinnie.co/jinnie...');
  const response = await page.goto('https://jinnie.co/jinnie', { 
    waitUntil: 'networkidle',
    timeout: 30000 
  });
  
  console.log('Response status:', response.status());
  console.log('Response URL:', response.url());
  
  // Wait a bit for any client-side errors
  await page.waitForTimeout(2000);
  
  // Get page content
  const content = await page.content();
  console.log('\n=== PAGE CONTENT (first 1500 chars) ===');
  console.log(content.substring(0, 1500));
  
  // Take screenshot
  await page.screenshot({ path: 'jinnie-screenshot.png', fullPage: true });
  console.log('\nScreenshot saved to jinnie-screenshot.png');
  
} catch (error) {
  console.error('ERROR:', error.message);
}

await browser.close();
