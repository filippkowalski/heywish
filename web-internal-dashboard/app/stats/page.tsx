'use client';

import { useState } from 'react';
import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { getGrowthStats, type GrowthStats } from '@/lib/api';
import useSWR from 'swr';
import { TrendingUp, Calendar } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const COLORS = {
  users: '#3b82f6',
  wishlists: '#8b5cf6',
  wishes: '#ec4899',
};

export default function StatsPage() {
  const [period, setPeriod] = useState<'day' | 'week' | 'month'>('month');

  const { data, error, isLoading } = useSWR<GrowthStats>(
    `/admin/stats/growth?period=${period}`,
    () => getGrowthStats(period),
    { refreshInterval: 60000 }
  );

  const getPeriodLabel = () => {
    switch (period) {
      case 'day':
        return 'Daily';
      case 'week':
        return 'Weekly';
      case 'month':
        return 'Monthly';
      default:
        return 'Monthly';
    }
  };

  // Combine data for multi-line chart
  const chartData = data ? data.users.map((userPeriod, index) => ({
    period: userPeriod.period,
    users: userPeriod.count,
    wishlists: data.wishlists[index]?.count || 0,
    wishes: data.wishes[index]?.count || 0,
  })) : [];

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Page header */}
        <div>
          <h1 className="text-3xl font-bold">Growth Analytics</h1>
          <p className="text-gray-500 mt-1">Track user, wishlist, and wish creation over time</p>
        </div>

        {/* Period Selector */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              Time Period
            </CardTitle>
            <CardDescription>Select the time period for growth analytics</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex gap-2">
              <Button
                variant={period === 'day' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPeriod('day')}
              >
                Daily
              </Button>
              <Button
                variant={period === 'week' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPeriod('week')}
              >
                Weekly
              </Button>
              <Button
                variant={period === 'month' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPeriod('month')}
              >
                Monthly
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Loading state */}
        {isLoading && (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
            <p className="mt-4 text-gray-600">Loading growth data...</p>
          </div>
        )}

        {/* Error state */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            Failed to load growth statistics. Please check your API connection.
          </div>
        )}

        {/* Growth Charts */}
        {data && (
          <>
            {/* Combined Growth Chart */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5" />
                  {getPeriodLabel()} Growth Trends
                </CardTitle>
                <CardDescription>
                  Users, wishlists, and wishes created over time (last 24 periods)
                </CardDescription>
              </CardHeader>
              <CardContent>
                {chartData.length > 0 ? (
                  <ResponsiveContainer width="100%" height={400}>
                    <LineChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis
                        dataKey="period"
                        angle={-45}
                        textAnchor="end"
                        height={80}
                        tick={{ fontSize: 12 }}
                      />
                      <YAxis />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'white',
                          border: '1px solid #e5e7eb',
                          borderRadius: '8px',
                          padding: '12px',
                        }}
                      />
                      <Legend />
                      <Line
                        type="monotone"
                        dataKey="users"
                        stroke={COLORS.users}
                        strokeWidth={2}
                        dot={{ r: 4 }}
                        activeDot={{ r: 6 }}
                        name="Users"
                      />
                      <Line
                        type="monotone"
                        dataKey="wishlists"
                        stroke={COLORS.wishlists}
                        strokeWidth={2}
                        dot={{ r: 4 }}
                        activeDot={{ r: 6 }}
                        name="Wishlists"
                      />
                      <Line
                        type="monotone"
                        dataKey="wishes"
                        stroke={COLORS.wishes}
                        strokeWidth={2}
                        dot={{ r: 4 }}
                        activeDot={{ r: 6 }}
                        name="Wishes"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="text-center py-12 text-gray-500">
                    No growth data available yet.
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Individual Metric Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Users Growth */}
              <Card>
                <CardHeader>
                  <CardTitle>User Signups</CardTitle>
                  <CardDescription>{getPeriodLabel()} new users</CardDescription>
                </CardHeader>
                <CardContent>
                  {data.users.length > 0 ? (
                    <>
                      <ResponsiveContainer width="100%" height={200}>
                        <LineChart data={data.users}>
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis dataKey="period" tick={{ fontSize: 10 }} />
                          <YAxis />
                          <Tooltip />
                          <Line
                            type="monotone"
                            dataKey="count"
                            stroke={COLORS.users}
                            strokeWidth={2}
                            dot={{ r: 3 }}
                          />
                        </LineChart>
                      </ResponsiveContainer>
                      <div className="mt-4 text-center">
                        <p className="text-2xl font-bold text-blue-600">
                          {data.users[data.users.length - 1]?.count || 0}
                        </p>
                        <p className="text-sm text-gray-500">Last {period}</p>
                      </div>
                    </>
                  ) : (
                    <div className="text-center py-8 text-gray-500">No data</div>
                  )}
                </CardContent>
              </Card>

              {/* Wishlists Growth */}
              <Card>
                <CardHeader>
                  <CardTitle>Wishlist Creation</CardTitle>
                  <CardDescription>{getPeriodLabel()} new wishlists</CardDescription>
                </CardHeader>
                <CardContent>
                  {data.wishlists.length > 0 ? (
                    <>
                      <ResponsiveContainer width="100%" height={200}>
                        <LineChart data={data.wishlists}>
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis dataKey="period" tick={{ fontSize: 10 }} />
                          <YAxis />
                          <Tooltip />
                          <Line
                            type="monotone"
                            dataKey="count"
                            stroke={COLORS.wishlists}
                            strokeWidth={2}
                            dot={{ r: 3 }}
                          />
                        </LineChart>
                      </ResponsiveContainer>
                      <div className="mt-4 text-center">
                        <p className="text-2xl font-bold text-purple-600">
                          {data.wishlists[data.wishlists.length - 1]?.count || 0}
                        </p>
                        <p className="text-sm text-gray-500">Last {period}</p>
                      </div>
                    </>
                  ) : (
                    <div className="text-center py-8 text-gray-500">No data</div>
                  )}
                </CardContent>
              </Card>

              {/* Wishes Growth */}
              <Card>
                <CardHeader>
                  <CardTitle>Wish Addition</CardTitle>
                  <CardDescription>{getPeriodLabel()} new wishes</CardDescription>
                </CardHeader>
                <CardContent>
                  {data.wishes.length > 0 ? (
                    <>
                      <ResponsiveContainer width="100%" height={200}>
                        <LineChart data={data.wishes}>
                          <CartesianGrid strokeDasharray="3 3" />
                          <XAxis dataKey="period" tick={{ fontSize: 10 }} />
                          <YAxis />
                          <Tooltip />
                          <Line
                            type="monotone"
                            dataKey="count"
                            stroke={COLORS.wishes}
                            strokeWidth={2}
                            dot={{ r: 3 }}
                          />
                        </LineChart>
                      </ResponsiveContainer>
                      <div className="mt-4 text-center">
                        <p className="text-2xl font-bold text-pink-600">
                          {data.wishes[data.wishes.length - 1]?.count || 0}
                        </p>
                        <p className="text-sm text-gray-500">Last {period}</p>
                      </div>
                    </>
                  ) : (
                    <div className="text-center py-8 text-gray-500">No data</div>
                  )}
                </CardContent>
              </Card>
            </div>
          </>
        )}
      </div>
    </DashboardLayout>
  );
}
