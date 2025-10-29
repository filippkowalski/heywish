'use client';

import { useState, useEffect } from 'react';
import { Sparkles, Heart, Users, Gift } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { detectPlatform, getAppStoreUrl, type Platform } from '@/lib/platform-detection';

interface AppDownloadModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const features = [
  {
    icon: Heart,
    title: 'Create Your Wishlists',
    description: 'Build and organize multiple wishlists for any occasion',
  },
  {
    icon: Users,
    title: 'Share with Friends',
    description: 'Let friends and family know exactly what you want',
  },
  {
    icon: Gift,
    title: 'Reserve Gifts',
    description: 'Coordinate gift-giving without spoiling surprises',
  },
  {
    icon: Sparkles,
    title: 'Discover Products',
    description: 'Find and add products from anywhere on the web',
  },
];

export function AppDownloadModal({ open, onOpenChange }: AppDownloadModalProps) {
  const [platform, setPlatform] = useState<Platform>('other');

  useEffect(() => {
    const info = detectPlatform();
    setPlatform(info.platform);
  }, []);

  const handleDownload = () => {
    const url = getAppStoreUrl(platform);
    window.location.href = url;
    onOpenChange(false);
  };

  const platformName = platform === 'android' ? 'Android' : 'iPhone';
  const storeName = platform === 'android' ? 'Google Play' : 'App Store';

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <div className="mx-auto mb-4">
            <img
              src="/apple-touch-icon.png"
              alt="Jinnie"
              className="w-20 h-20 rounded-2xl shadow-md"
            />
          </div>
          <DialogTitle className="text-center text-2xl">
            Get Jinnie for {platformName}
          </DialogTitle>
          <DialogDescription className="text-center text-base">
            Download the app to create your account and start building your wishlists
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Features */}
          <div className="space-y-3">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <div key={index} className="flex items-start gap-3">
                  <div className="flex-shrink-0 w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center">
                    <Icon className="w-5 h-5 text-gray-700" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className="text-sm font-semibold text-black">
                      {feature.title}
                    </h4>
                    <p className="text-xs text-gray-600 mt-0.5">
                      {feature.description}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Download Button */}
          <button
            onClick={handleDownload}
            className="w-full mt-6 px-6 py-3 bg-black text-white text-base font-semibold rounded-lg hover:bg-gray-800 transition-colors"
          >
            Download from {storeName}
          </button>

          {/* Footer note */}
          <p className="text-center text-xs text-gray-500">
            Free to download • Available on iOS and Android
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}
