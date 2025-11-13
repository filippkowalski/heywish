'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { Toaster } from 'sonner';
import {
  LayoutDashboard,
  Users,
  Gift,
  TrendingUp,
  BarChart3,
  UserPlus,
  Plus,
  LogOut,
  Zap
} from 'lucide-react';

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    // Check authentication via cookie on mount
    fetch('/api/auth/verify')
      .then((res) => {
        if (!res.ok) {
          router.push('/');
        }
      })
      .catch(() => {
        router.push('/');
      });
  }, [router]);

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
    } finally {
      router.push('/');
    }
  };

  const overviewItems = [
    { href: '/dashboard', label: 'Overview', icon: LayoutDashboard },
  ];

  const actionItems = [
    { href: '/create-user', label: 'Create User', icon: UserPlus },
    { href: '/add-wish', label: 'Add Wish', icon: Plus },
  ];

  const analyticsItems = [
    { href: '/users', label: 'Users', icon: Users },
    { href: '/wishes', label: 'Wishes', icon: Gift },
    { href: '/brands', label: 'Brands', icon: TrendingUp },
    { href: '/stats', label: 'Growth', icon: BarChart3 },
  ];

  const renderNavSection = (title: string, items: typeof overviewItems, icon?: React.ReactNode) => (
    <div className="space-y-1">
      <div className="flex items-center gap-2 px-3 mb-2">
        {icon}
        <h4 className="text-xs font-semibold text-zinc-500 uppercase tracking-wider">
          {title}
        </h4>
      </div>
      {items.map((item) => {
        const Icon = item.icon;
        const isActive = pathname === item.href;

        return (
          <Link key={item.href} href={item.href}>
            <div
              className={`flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-zinc-800 text-white'
                  : 'text-zinc-400 hover:bg-zinc-800/50 hover:text-white'
              }`}
            >
              <Icon className="h-4 w-4" />
              <span>{item.label}</span>
            </div>
          </Link>
        );
      })}
    </div>
  );

  return (
    <div className="min-h-screen bg-zinc-950">
      {/* Sidebar */}
      <div className="fixed inset-y-0 left-0 w-64 border-r border-zinc-800 bg-zinc-900">
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="px-6 py-5 border-b border-zinc-800">
            <h1 className="text-xl font-bold tracking-tight text-white">Jinnie Admin</h1>
            <p className="text-sm text-zinc-400 mt-0.5">Internal Dashboard</p>
          </div>

          {/* Navigation */}
          <nav className="flex-1 overflow-y-auto p-4 space-y-6">
            {renderNavSection('Overview', overviewItems)}

            <Separator className="bg-zinc-800" />

            {renderNavSection('Actions', actionItems, <Zap className="h-3 w-3 text-zinc-500" />)}

            <Separator className="bg-zinc-800" />

            {renderNavSection('Analytics', analyticsItems, <BarChart3 className="h-3 w-3 text-zinc-500" />)}
          </nav>

          {/* Logout button */}
          <div className="p-4 border-t border-zinc-800">
            <Button
              variant="ghost"
              className="w-full justify-start gap-3 h-9 text-zinc-400 hover:text-white hover:bg-zinc-800"
              onClick={handleLogout}
            >
              <LogOut className="h-4 w-4" />
              <span className="text-sm font-medium">Logout</span>
            </Button>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="ml-64">
        <div className="container py-6 px-8">
          {children}
        </div>
      </div>

      {/* Toast notifications */}
      <Toaster position="top-right" richColors closeButton />
    </div>
  );
}
