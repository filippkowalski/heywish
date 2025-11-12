'use client';

import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { getOverviewStats, getDemographicsStats, type OverviewStats, type DemographicsStats } from '@/lib/api';
import useSWR from 'swr';
import { Users, ShoppingBag, Gift, Activity } from 'lucide-react';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';

// Color palette for charts
const COLORS = ['#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4', '#6366f1'];

export default function DashboardPage() {
  const { data, error, isLoading } = useSWR<OverviewStats>('/admin/stats/overview', getOverviewStats, {
    refreshInterval: 30000, // Refresh every 30 seconds
  });

  const { data: demographics, error: demoError, isLoading: demoLoading } = useSWR<DemographicsStats>(
    '/admin/stats/demographics',
    getDemographicsStats,
    { refreshInterval: 60000 } // Refresh every 60 seconds
  );

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Page header */}
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-gray-500 mt-1">Overview of key metrics and statistics</p>
        </div>

        {/* Loading state */}
        {isLoading && (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
            <p className="mt-4 text-gray-600">Loading statistics...</p>
          </div>
        )}

        {/* Error state */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            Failed to load statistics. Please check your API connection.
          </div>
        )}

        {/* Stats grid */}
        {data && (
          <>
            {/* User Stats */}
            <div>
              <h2 className="text-xl font-semibold mb-4">User Statistics</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total Users</CardTitle>
                    <Users className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.users.total_users}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {data.users.fake_users} fake users
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Google Users</CardTitle>
                    <Users className="h-4 w-4 text-green-600" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.users.google_users}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {((data.users.google_users / data.users.total_users) * 100).toFixed(1)}% of total
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Apple Users</CardTitle>
                    <Users className="h-4 w-4 text-gray-600" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.users.apple_users}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {((data.users.apple_users / data.users.total_users) * 100).toFixed(1)}% of total
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Anonymous Users</CardTitle>
                    <Users className="h-4 w-4 text-orange-600" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.users.anonymous_users}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {((data.users.anonymous_users / data.users.total_users) * 100).toFixed(1)}% of total
                    </p>
                  </CardContent>
                </Card>
              </div>
            </div>

            {/* Profile Completion */}
            <div>
              <h2 className="text-xl font-semibold mb-4">Profile Completion</h2>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">With Email</CardTitle>
                    <Activity className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.users.users_with_email}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {((data.users.users_with_email / data.users.total_users) * 100).toFixed(1)}% of users
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">With Birthdate</CardTitle>
                    <Activity className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.users.users_with_birthdate}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {((data.users.users_with_birthdate / data.users.total_users) * 100).toFixed(1)}% of users
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">With Gender</CardTitle>
                    <Activity className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.users.users_with_gender}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {((data.users.users_with_gender / data.users.total_users) * 100).toFixed(1)}% of users
                    </p>
                  </CardContent>
                </Card>
              </div>
            </div>

            {/* Wishlist & Wish Stats */}
            <div>
              <h2 className="text-xl font-semibold mb-4">Content Statistics</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total Wishlists</CardTitle>
                    <ShoppingBag className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.wishlists.total_wishlists}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {data.wishlists.public_wishlists} public, {data.wishlists.private_wishlists} private
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total Wishes</CardTitle>
                    <Gift className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{data.wishes.total_wishes}</div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {data.wishes.available_wishes} available, {data.wishes.reserved_wishes} reserved
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Average Price</CardTitle>
                    <Gift className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      ${Number(data.wishes.avg_price).toFixed(2)}
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      Across all wishes
                    </p>
                  </CardContent>
                </Card>
              </div>
            </div>

            {/* Demographics Section */}
            <div>
              <h2 className="text-xl font-semibold mb-4">Demographics</h2>

              {demoLoading && (
                <div className="text-center py-12">
                  <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
                  <p className="mt-4 text-gray-600">Loading demographics...</p>
                </div>
              )}

              {demoError && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
                  Failed to load demographics data.
                </div>
              )}

              {demographics && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Age Distribution Pie Chart */}
                  <Card>
                    <CardHeader>
                      <CardTitle>Age Distribution</CardTitle>
                      <CardDescription>
                        Users by age group (based on {demographics.age_groups.reduce((sum, group) => sum + group.count, 0)} users with birthdate)
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <ResponsiveContainer width="100%" height={350}>
                        <PieChart>
                          <Pie
                            data={demographics.age_groups.map(group => ({
                              name: group.age_group,
                              value: group.count
                            }))}
                            cx="50%"
                            cy="45%"
                            labelLine={false}
                            label={false}
                            outerRadius={90}
                            fill="#8884d8"
                            dataKey="value"
                          >
                            {demographics.age_groups.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                            ))}
                          </Pie>
                          <Tooltip formatter={(value, name, props) => [`${value} users (${((props.payload.value / demographics.age_groups.reduce((sum, g) => sum + g.count, 0)) * 100).toFixed(1)}%)`, name]} />
                          <Legend verticalAlign="bottom" height={36} />
                        </PieChart>
                      </ResponsiveContainer>
                    </CardContent>
                  </Card>

                  {/* Gender Distribution Pie Chart */}
                  <Card>
                    <CardHeader>
                      <CardTitle>Gender Distribution</CardTitle>
                      <CardDescription>
                        Users by gender (based on {demographics.gender.reduce((sum, g) => sum + g.count, 0)} users with gender)
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <ResponsiveContainer width="100%" height={350}>
                        <PieChart>
                          <Pie
                            data={demographics.gender.map(g => ({
                              name: g.gender.charAt(0).toUpperCase() + g.gender.slice(1),
                              value: g.count
                            }))}
                            cx="50%"
                            cy="45%"
                            labelLine={false}
                            label={false}
                            outerRadius={90}
                            fill="#8884d8"
                            dataKey="value"
                          >
                            {demographics.gender.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                            ))}
                          </Pie>
                          <Tooltip formatter={(value, name, props) => [`${value} users (${((props.payload.value / demographics.gender.reduce((sum, g) => sum + g.count, 0)) * 100).toFixed(1)}%)`, name]} />
                          <Legend verticalAlign="bottom" height={36} />
                        </PieChart>
                      </ResponsiveContainer>
                    </CardContent>
                  </Card>
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </DashboardLayout>
  );
}
