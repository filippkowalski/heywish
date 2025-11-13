#!/usr/bin/env node

// Quick diagnostic script to test jinnie.co connectivity
// Run with: node tmp.mjs

console.log('Testing jinnie.co connectivity...\n');

const tests = [
  { name: 'Homepage', url: 'https://jinnie.co' },
  { name: 'Profile Page', url: 'https://jinnie.co/jinnie' },
  { name: 'API Health', url: 'https://jinnie.co/api/health' },
];

for (const test of tests) {
  try {
    const start = Date.now();
    const response = await fetch(test.url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15'
      }
    });
    const duration = Date.now() - start;

    console.log(`✓ ${test.name}: ${response.status} (${duration}ms)`);
    console.log(`  Headers: ${response.headers.get('cf-ray')}`);
    console.log(`  Cache: ${response.headers.get('cf-cache-status')}\n`);
  } catch (error) {
    console.log(`✗ ${test.name}: ${error.message}\n`);
  }
}
