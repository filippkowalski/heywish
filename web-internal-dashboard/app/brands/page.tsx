'use client';

import { DashboardLayout } from '@/components/dashboard-layout';
import { Card } from '@/components/ui/card';

export default function BrandsPage() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold">Brand Analytics</h1>
          <p className="text-gray-500 mt-1">Popular domains and brands</p>
        </div>

        <Card className="p-12 text-center">
          <p className="text-gray-500">Brand analytics coming soon...</p>
          <p className="text-sm text-gray-400 mt-2">
            This page will show top domains from wish URLs and extracted brand names with charts.
          </p>
        </Card>
      </div>
    </DashboardLayout>
  );
}
