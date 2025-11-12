'use client';

import { useState } from 'react';
import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { browseWishes, type WishListResponse } from '@/lib/api';
import useSWR from 'swr';
import { Gift, Filter, ChevronLeft, ChevronRight, Search, ExternalLink } from 'lucide-react';

export default function WishesPage() {
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState<string>('');
  const [usernameFilter, setUsernameFilter] = useState<string>('');
  const [searchInput, setSearchInput] = useState<string>('');
  const limit = 20;

  const { data, error, isLoading } = useSWR<WishListResponse>(
    `/admin/wishes/browse?page=${page}&limit=${limit}&status=${status}&username=${usernameFilter}`,
    () => browseWishes({ page, limit, status, username: usernameFilter }),
    { refreshInterval: 30000 }
  );

  const handleStatusChange = (newStatus: string) => {
    setStatus(newStatus);
    setPage(1);
  };

  const handleSearch = () => {
    setUsernameFilter(searchInput);
    setPage(1);
  };

  const handleClearSearch = () => {
    setSearchInput('');
    setUsernameFilter('');
    setPage(1);
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Page header */}
        <div>
          <h1 className="text-3xl font-bold">Wish Management</h1>
          <p className="text-gray-500 mt-1">Browse and manage wishes across all users</p>
        </div>

        {/* Filters */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Filter className="h-5 w-5" />
              Filters
            </CardTitle>
            <CardDescription>Filter wishes by status and username</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {/* Status Filter */}
              <div>
                <label className="text-sm font-medium mb-2 block">Status</label>
                <div className="flex flex-wrap gap-2">
                  <Button
                    variant={status === '' ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => handleStatusChange('')}
                  >
                    All Wishes
                  </Button>
                  <Button
                    variant={status === 'available' ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => handleStatusChange('available')}
                  >
                    Available
                  </Button>
                  <Button
                    variant={status === 'reserved' ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => handleStatusChange('reserved')}
                  >
                    Reserved
                  </Button>
                  <Button
                    variant={status === 'purchased' ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => handleStatusChange('purchased')}
                  >
                    Purchased
                  </Button>
                </div>
              </div>

              {/* Username Search */}
              <div>
                <label className="text-sm font-medium mb-2 block">Username</label>
                <div className="flex gap-2">
                  <div className="relative flex-grow max-w-md">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      type="text"
                      placeholder="Search by username..."
                      value={searchInput}
                      onChange={(e) => setSearchInput(e.target.value)}
                      onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                      className="pl-10"
                    />
                  </div>
                  <Button onClick={handleSearch}>Search</Button>
                  {usernameFilter && (
                    <Button variant="outline" onClick={handleClearSearch}>
                      Clear
                    </Button>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Loading state */}
        {isLoading && (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
            <p className="mt-4 text-gray-600">Loading wishes...</p>
          </div>
        )}

        {/* Error state */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            Failed to load wishes. Please check your API connection.
          </div>
        )}

        {/* Wishes List */}
        {data && (
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Gift className="h-5 w-5" />
                    Wishes ({data.pagination.total})
                  </CardTitle>
                  <CardDescription>
                    Page {data.pagination.page} of {data.pagination.totalPages}
                  </CardDescription>
                </div>
                <div className="text-sm text-gray-500">
                  Showing {data.wishes.length} wishes
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {data.wishes.length > 0 ? (
                <div className="space-y-4">
                  {data.wishes.map((wish) => (
                    <div
                      key={wish.id}
                      className="flex items-start gap-4 p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                    >
                      {/* Image */}
                      <div className="flex-shrink-0">
                        {wish.images && wish.images.length > 0 ? (
                          <img
                            src={wish.images[0]}
                            alt={wish.title}
                            className="w-20 h-20 rounded-lg object-cover"
                          />
                        ) : (
                          <div className="w-20 h-20 rounded-lg bg-gray-200 flex items-center justify-center">
                            <Gift className="h-8 w-8 text-gray-400" />
                          </div>
                        )}
                      </div>

                      {/* Wish Info */}
                      <div className="flex-grow min-w-0">
                        <div className="flex items-start justify-between gap-2 mb-2">
                          <div className="flex-grow">
                            <h3 className="font-semibold text-lg mb-1">{wish.title}</h3>
                            {wish.description && (
                              <p className="text-sm text-gray-600 mb-2 line-clamp-2">
                                {wish.description}
                              </p>
                            )}
                          </div>
                          {wish.price && (
                            <div className="text-right flex-shrink-0">
                              <p className="font-semibold text-lg">
                                ${wish.price.toFixed(2)}
                              </p>
                              {wish.currency && wish.currency !== 'USD' && (
                                <p className="text-xs text-gray-500">{wish.currency}</p>
                              )}
                            </div>
                          )}
                        </div>

                        <div className="flex flex-wrap items-center gap-3 text-sm">
                          <span className="text-gray-600">
                            by <span className="font-medium">@{wish.username}</span>
                          </span>
                          <span className="text-gray-400">•</span>
                          <span className="text-gray-600">
                            in <span className="font-medium">{wish.wishlist_name}</span>
                          </span>
                          <span className="text-gray-400">•</span>
                          <span
                            className={`px-2 py-0.5 text-xs font-medium rounded capitalize ${
                              wish.status === 'available'
                                ? 'bg-green-100 text-green-800'
                                : wish.status === 'reserved'
                                ? 'bg-yellow-100 text-yellow-800'
                                : 'bg-blue-100 text-blue-800'
                            }`}
                          >
                            {wish.status}
                          </span>
                          {wish.quantity > 1 && (
                            <>
                              <span className="text-gray-400">•</span>
                              <span className="text-gray-600">Qty: {wish.quantity}</span>
                            </>
                          )}
                          {wish.priority && (
                            <>
                              <span className="text-gray-400">•</span>
                              <span className="text-gray-600">
                                Priority: {'⭐'.repeat(wish.priority)}
                              </span>
                            </>
                          )}
                        </div>

                        {wish.url && (
                          <div className="mt-2">
                            <a
                              href={wish.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1"
                            >
                              <ExternalLink className="h-3 w-3" />
                              View product
                            </a>
                          </div>
                        )}

                        <div className="mt-2 text-xs text-gray-500">
                          Added {new Date(wish.added_at).toLocaleDateString()}
                          {wish.reserved_at && (
                            <> • Reserved {new Date(wish.reserved_at).toLocaleDateString()}</>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-12 text-gray-500">
                  No wishes found matching your filters.
                </div>
              )}

              {/* Pagination */}
              {data.pagination.totalPages > 1 && (
                <div className="flex items-center justify-between mt-6 pt-6 border-t">
                  <div className="text-sm text-gray-500">
                    Page {data.pagination.page} of {data.pagination.totalPages}
                  </div>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setPage(page - 1)}
                      disabled={page === 1}
                    >
                      <ChevronLeft className="h-4 w-4 mr-1" />
                      Previous
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setPage(page + 1)}
                      disabled={page === data.pagination.totalPages}
                    >
                      Next
                      <ChevronRight className="h-4 w-4 ml-1" />
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>
    </DashboardLayout>
  );
}
