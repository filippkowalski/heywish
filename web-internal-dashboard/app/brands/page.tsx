'use client';

import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { getBrandStats, type BrandStats } from '@/lib/api';
import useSWR from 'swr';
import { TrendingUp, Globe } from 'lucide-react';

export default function BrandsPage() {
  const { data, error, isLoading } = useSWR<BrandStats>('/admin/stats/brands?limit=50', () => getBrandStats(50), {
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

        {/* Brand Lists */}
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

            {/* Tables */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Domain List */}
              <Card>
                <CardHeader>
                  <CardTitle>Top Domains</CardTitle>
                  <CardDescription>Most popular websites where users find their wishes</CardDescription>
                </CardHeader>
                <CardContent>
                  {data.domains.length > 0 ? (
                    <div className="space-y-0 divide-y">
                      {data.domains.map((domain, index) => (
                        <div key={domain.domain} className="flex items-center justify-between py-3">
                          <div className="flex items-center gap-3">
                            <div className="text-sm font-semibold text-gray-400 w-8">
                              #{index + 1}
                            </div>
                            <div>
                              <p className="font-medium text-sm">{domain.domain}</p>
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
                  <CardTitle>Top Brands</CardTitle>
                  <CardDescription>Most mentioned brand names in wish titles</CardDescription>
                </CardHeader>
                <CardContent>
                  {data.brands.length > 0 ? (
                    <div className="space-y-0 divide-y">
                      {data.brands.map((brand, index) => (
                        <div key={brand.brand} className="flex items-center justify-between py-3">
                          <div className="flex items-center gap-3">
                            <div className="text-sm font-semibold text-gray-400 w-8">
                              #{index + 1}
                            </div>
                            <div>
                              <p className="font-medium text-sm">{brand.brand}</p>
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
