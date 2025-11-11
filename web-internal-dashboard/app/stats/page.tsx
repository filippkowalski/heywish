'use client';

import { DashboardLayout } from '@/components/dashboard-layout';
import { Card } from '@/components/ui/card';

export default function StatsPage() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold">Detailed Statistics</h1>
          <p className="text-gray-500 mt-1">Demographics and growth analytics</p>
        </div>

        <Card className="p-12 text-center">
          <p className="text-gray-500">Detailed statistics coming soon...</p>
          <p className="text-sm text-gray-400 mt-2">
            This page will show age demographics, gender breakdown, notification preferences, and growth charts.
          </p>
        </Card>
      </div>
    </DashboardLayout>
  );
}
