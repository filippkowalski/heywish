'use client';

import { useState } from 'react';
import { SmartAppBanner } from './smart-app-banner';
import { AppDownloadModal } from './app-download-modal';

/**
 * Wrapper component that coordinates the smart app banner and modal
 * This handles the flow: Banner -> Modal -> App Store
 */
export function AppDownloadBannerWrapper() {
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleOpenModal = () => {
    setIsModalOpen(true);
  };

  return (
    <>
      <SmartAppBanner onOpenModal={handleOpenModal} />
      <AppDownloadModal open={isModalOpen} onOpenChange={setIsModalOpen} />
    </>
  );
}
