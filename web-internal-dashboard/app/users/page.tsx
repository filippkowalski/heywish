'use client';

import { DashboardLayout } from '@/components/dashboard-layout';
import { Card } from '@/components/ui/card';

export default function UsersPage() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold">User Management</h1>
          <p className="text-gray-500 mt-1">Create and manage users</p>
        </div>

        <Card className="p-12 text-center">
          <p className="text-gray-500">User management interface coming soon...</p>
          <p className="text-sm text-gray-400 mt-2">
            This page will allow you to create fake users, browse all users, and edit user details.
          </p>
        </Card>
      </div>
    </DashboardLayout>
  );
}
