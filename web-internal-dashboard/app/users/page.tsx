'use client';

import { useState } from 'react';
import { DashboardLayout } from '@/components/dashboard-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { listUsers, type User, type UserListResponse } from '@/lib/api';
import useSWR from 'swr';
import { Users as UsersIcon, Filter, ChevronLeft, ChevronRight, Edit } from 'lucide-react';
import Link from 'next/link';

export default function UsersPage() {
  const [page, setPage] = useState(1);
  const [fakeOnly, setFakeOnly] = useState(false);
  const [signUpMethod, setSignUpMethod] = useState<string>('');
  const limit = 20;

  const { data, error, isLoading, mutate } = useSWR<UserListResponse>(
    `/admin/users/list?page=${page}&limit=${limit}&fake_only=${fakeOnly}&sign_up_method=${signUpMethod}`,
    () => listUsers({ page, limit, fake_only: fakeOnly, sign_up_method: signUpMethod }),
    { refreshInterval: 30000 }
  );

  const handleFilterChange = (newFakeOnly: boolean, newSignUpMethod: string) => {
    setFakeOnly(newFakeOnly);
    setSignUpMethod(newSignUpMethod);
    setPage(1); // Reset to first page when filters change
  };

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Page header */}
        <div>
          <h1 className="text-3xl font-bold">User Management</h1>
          <p className="text-gray-500 mt-1">Browse and manage users</p>
        </div>

        {/* Filters */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Filter className="h-5 w-5" />
              Filters
            </CardTitle>
            <CardDescription>Filter users by type and sign-up method</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-4">
              {/* User Type Filter */}
              <div className="flex gap-2">
                <Button
                  variant={!fakeOnly ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleFilterChange(false, signUpMethod)}
                >
                  All Users
                </Button>
                <Button
                  variant={fakeOnly ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleFilterChange(true, signUpMethod)}
                >
                  Fake Users Only
                </Button>
              </div>

              {/* Sign-up Method Filter */}
              <div className="flex gap-2">
                <Button
                  variant={signUpMethod === '' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleFilterChange(fakeOnly, '')}
                >
                  All Methods
                </Button>
                <Button
                  variant={signUpMethod === 'google' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleFilterChange(fakeOnly, 'google')}
                >
                  Google
                </Button>
                <Button
                  variant={signUpMethod === 'apple' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleFilterChange(fakeOnly, 'apple')}
                >
                  Apple
                </Button>
                <Button
                  variant={signUpMethod === 'anonymous' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleFilterChange(fakeOnly, 'anonymous')}
                >
                  Anonymous
                </Button>
                <Button
                  variant={signUpMethod === 'email' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => handleFilterChange(fakeOnly, 'email')}
                >
                  Email
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Loading state */}
        {isLoading && (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
            <p className="mt-4 text-gray-600">Loading users...</p>
          </div>
        )}

        {/* Error state */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            Failed to load users. Please check your API connection.
          </div>
        )}

        {/* User List */}
        {data && (
          <>
            {/* Summary */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center gap-2">
                      <UsersIcon className="h-5 w-5" />
                      Users ({data.pagination.total})
                    </CardTitle>
                    <CardDescription>
                      Page {data.pagination.page} of {data.pagination.totalPages}
                    </CardDescription>
                  </div>
                  <div className="text-sm text-gray-500">
                    Showing {data.users.length} users
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                {data.users.length > 0 ? (
                  <div className="space-y-4">
                    {data.users.map((user) => (
                      <div
                        key={user.id}
                        className="flex items-start gap-4 p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                      >
                        {/* Avatar */}
                        <div className="flex-shrink-0">
                          {user.avatar_url ? (
                            <img
                              src={user.avatar_url}
                              alt={user.username}
                              className="w-12 h-12 rounded-full object-cover"
                            />
                          ) : (
                            <div className="w-12 h-12 rounded-full bg-gray-200 flex items-center justify-center">
                              <UsersIcon className="h-6 w-6 text-gray-400" />
                            </div>
                          )}
                        </div>

                        {/* User Info */}
                        <div className="flex-grow min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h3 className="font-semibold text-lg">@{user.username}</h3>
                            {user.is_fake && (
                              <span className="px-2 py-0.5 text-xs font-medium bg-orange-100 text-orange-800 rounded">
                                Fake
                              </span>
                            )}
                            <span className="px-2 py-0.5 text-xs font-medium bg-blue-100 text-blue-800 rounded capitalize">
                              {user.sign_up_method || 'unknown'}
                            </span>
                          </div>

                          {user.full_name && (
                            <p className="text-gray-700 mb-1">{user.full_name}</p>
                          )}

                          {user.email && (
                            <p className="text-sm text-gray-500 mb-1">{user.email}</p>
                          )}

                          {user.bio && (
                            <p className="text-sm text-gray-600 mt-2">{user.bio}</p>
                          )}

                          <div className="flex flex-wrap gap-4 mt-2 text-xs text-gray-500">
                            {user.location && (
                              <span>📍 {user.location}</span>
                            )}
                            {user.birthdate && (
                              <span>🎂 {new Date(user.birthdate).toLocaleDateString()}</span>
                            )}
                            {user.gender && (
                              <span className="capitalize">⚧ {user.gender}</span>
                            )}
                            <span>
                              Joined {new Date(user.created_at).toLocaleDateString()}
                            </span>
                          </div>
                        </div>

                        {/* Actions */}
                        <div className="flex-shrink-0">
                          <Link href={`/users/${user.id}/edit`}>
                            <Button variant="outline" size="sm">
                              <Edit className="h-4 w-4 mr-1" />
                              Edit
                            </Button>
                          </Link>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-12 text-gray-500">
                    No users found matching your filters.
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
          </>
        )}
      </div>
    </DashboardLayout>
  );
}
