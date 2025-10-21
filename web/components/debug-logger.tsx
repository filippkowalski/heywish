'use client';

import { useEffect } from 'react';

export function DebugLogger() {
  useEffect(() => {
    console.log('=== JINNIE DEBUG INFO ===');
    console.log('NEXT_PUBLIC_API_BASE_URL:', process.env.NEXT_PUBLIC_API_BASE_URL);
    console.log('All NEXT_PUBLIC env vars:', Object.keys(process.env).filter(key => key.startsWith('NEXT_PUBLIC')));
    console.log('========================');
  }, []);

  return null;
}
