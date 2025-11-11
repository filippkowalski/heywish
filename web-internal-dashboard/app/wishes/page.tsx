'use client';

import { DashboardLayout } from '@/components/dashboard-layout';
import { Card } from '@/components/ui/card';

export default function WishesPage() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold">Wish Management</h1>
          <p className="text-gray-500 mt-1">Browse and create wishes</p>
        </div>

        <Card className="p-12 text-center">
          <p className="text-gray-500">Wish management interface coming soon...</p>
          <p className="text-sm text-gray-400 mt-2">
            This page will allow you to browse wishes, filter by user/status, and insert wishes for any user.
          </p>
        </Card>
      </div>
    </DashboardLayout>
  );
}
