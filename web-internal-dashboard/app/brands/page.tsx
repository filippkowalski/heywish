'use client';

import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { getBrandStats, type BrandStats } from '@/lib/api';
import useSWR from 'swr';
import { TrendingUp, Globe } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';

// Color palette for charts
const COLORS = ['#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#06b6d4', '#6366f1', '#ef4444', '#14b8a6', '#f97316'];

export default function BrandsPage() {
  const { data, error, isLoading } = useSWR<BrandStats>('/admin/stats/brands?limit=20', () => getBrandStats(20), {
    refreshInterval: 60000, // Refresh every 60 seconds
  });

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Page header */}
        <div>
          <h1 className="text-3xl font-bold">Brand Analytics</h1>
          <p className="text-gray-500 mt-1">Popular domains and brands from user wishlists</p>
        </div>

        {/* Loading state */}
        {isLoading && (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
            <p className="mt-4 text-gray-600">Loading brand statistics...</p>
          </div>
        )}

        {/* Error state */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            Failed to load brand statistics. Please check your API connection.
          </div>
        )}

        {/* Charts */}
        {data && (
          <>
            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Top Domains</CardTitle>
                  <Globe className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{data.domains.length}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Unique domains identified
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Brand Names</CardTitle>
                  <TrendingUp className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{data.brands.length}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Popular brands extracted
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Domain Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Top Domains</CardTitle>
                <CardDescription>
                  Most popular websites where users find their wishes
                </CardDescription>
              </CardHeader>
              <CardContent>
                {data.domains.length > 0 ? (
                  <ResponsiveContainer width="100%" height={400}>
                    <BarChart
                      data={data.domains}
                      layout="vertical"
                      margin={{ top: 5, right: 30, left: 100, bottom: 5 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis type="number" />
                      <YAxis type="category" dataKey="domain" width={90} />
                      <Tooltip
                        content={({ active, payload }) => {
                          if (active && payload && payload.length) {
                            return (
                              <div className="bg-white p-3 border border-gray-200 rounded-lg shadow-lg">
                                <p className="font-semibold">{payload[0].payload.domain}</p>
                                <p className="text-sm text-gray-600">
                                  {payload[0].value} wishes
                                </p>
                              </div>
                            );
                          }
                          return null;
                        }}
                      />
                      <Bar dataKey="count" radius={[0, 8, 8, 0]}>
                        {data.domains.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="text-center py-12 text-gray-500">
                    No domain data available yet. Users need to add wishes with URLs.
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Brand Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Top Brands</CardTitle>
                <CardDescription>
                  Most mentioned brand names in wish titles
                </CardDescription>
              </CardHeader>
              <CardContent>
                {data.brands.length > 0 ? (
                  <ResponsiveContainer width="100%" height={400}>
                    <BarChart
                      data={data.brands}
                      layout="vertical"
                      margin={{ top: 5, right: 30, left: 80, bottom: 5 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis type="number" />
                      <YAxis type="category" dataKey="brand" width={70} />
                      <Tooltip
                        content={({ active, payload }) => {
                          if (active && payload && payload.length) {
                            return (
                              <div className="bg-white p-3 border border-gray-200 rounded-lg shadow-lg">
                                <p className="font-semibold">{payload[0].payload.brand}</p>
                                <p className="text-sm text-gray-600">
                                  {payload[0].value} mentions
                                </p>
                              </div>
                            );
                          }
                          return null;
                        }}
                      />
                      <Bar dataKey="count" radius={[0, 8, 8, 0]}>
                        {data.brands.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="text-center py-12 text-gray-500">
                    No brand data available yet. Users need to add wishes with brand names in titles.
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Top Lists Side by Side */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Domain List */}
              <Card>
                <CardHeader>
                  <CardTitle>Domain Rankings</CardTitle>
                  <CardDescription>Complete list of domains</CardDescription>
                </CardHeader>
                <CardContent>
                  {data.domains.length > 0 ? (
                    <div className="space-y-2">
                      {data.domains.map((domain, index) => (
                        <div key={domain.domain} className="flex items-center justify-between py-2 border-b last:border-0">
                          <div className="flex items-center gap-3">
                            <div className="text-lg font-semibold text-gray-400 w-6">
                              #{index + 1}
                            </div>
                            <div>
                              <p className="font-medium">{domain.domain}</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="font-semibold">{domain.count}</p>
                            <p className="text-xs text-gray-500">wishes</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-center text-gray-500 py-8">No domains yet</p>
                  )}
                </CardContent>
              </Card>

              {/* Brand List */}
              <Card>
                <CardHeader>
                  <CardTitle>Brand Rankings</CardTitle>
                  <CardDescription>Complete list of brands</CardDescription>
                </CardHeader>
                <CardContent>
                  {data.brands.length > 0 ? (
                    <div className="space-y-2">
                      {data.brands.map((brand, index) => (
                        <div key={brand.brand} className="flex items-center justify-between py-2 border-b last:border-0">
                          <div className="flex items-center gap-3">
                            <div className="text-lg font-semibold text-gray-400 w-6">
                              #{index + 1}
                            </div>
                            <div>
                              <p className="font-medium">{brand.brand}</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="font-semibold">{brand.count}</p>
                            <p className="text-xs text-gray-500">mentions</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-center text-gray-500 py-8">No brands yet</p>
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
