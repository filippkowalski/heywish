'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Heart, Plus, Gift, Users, ArrowLeft, Loader2 } from 'lucide-react';

export default function WebAppPage() {
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState(null);

  useEffect(() => {
    // Simulate checking for existing authentication
    // In a real app, this would check Firebase auth state
    const checkAuth = async () => {
      setIsLoading(true);
      // Simulate API call delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // For demo purposes, no user is authenticated initially
      // This is where we'd check for existing Firebase auth
      setUser(null);
      setIsLoading(false);
    };

    checkAuth();
  }, []);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background">
        {/* Navigation */}
        <nav className="border-b bg-white/80 backdrop-blur-sm">
          <div className="container mx-auto px-4 py-4">
            <div className="flex items-center justify-between">
              <Link href="/" className="flex items-center space-x-2">
                <Heart className="h-8 w-8 text-primary" />
                <span className="text-2xl font-bold font-poppins">HeyWish</span>
              </Link>
              <Button variant="ghost" size="sm" asChild>
                <Link href="/">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Home
                </Link>
              </Button>
            </div>
          </div>
        </nav>

        {/* Loading State */}
        <div className="flex items-center justify-center min-h-[80vh]">
          <div className="text-center">
            <Loader2 className="h-12 w-12 text-primary animate-spin mx-auto mb-4" />
            <p className="text-muted-foreground">Loading HeyWish...</p>
          </div>
        </div>
      </div>
    );
  }

  // Anonymous user flow - show welcome screen
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <Link href="/" className="flex items-center space-x-2">
              <Heart className="h-8 w-8 text-primary" />
              <span className="text-2xl font-bold font-poppins">HeyWish</span>
            </Link>
            <div className="flex items-center space-x-4">
              <Button variant="ghost" size="sm" asChild>
                <Link href="/">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Home
                </Link>
              </Button>
              <Button variant="outline" size="sm">
                Sign In
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Welcome Section */}
      <section className="py-16 bg-gradient-to-br from-primary/5 via-purple-500/5 to-primary/5">
        <div className="container mx-auto px-4 text-center">
          <Badge className="mb-6" variant="outline">
            <Gift className="w-3 h-3 mr-1" />
            Welcome to HeyWish
          </Badge>
          <h1 className="text-4xl lg:text-5xl font-bold font-poppins mb-6">
            Ready to create your first{" "}
            <span className="bg-gradient-to-r from-primary via-purple-500 to-primary bg-clip-text text-transparent">
              wishlist?
            </span>
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto mb-8">
            Get started instantly with our anonymous wishlist creation. You can create and share 
            wishlists without signing up, then save your account later when you're ready.
          </p>
        </div>
      </section>

      {/* Quick Actions */}
      <section className="py-16">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto">
            <div className="grid md:grid-cols-2 gap-6 max-w-2xl mx-auto">
              
              {/* Create Wishlist */}
              <Card className="border-2 border-dashed border-primary/20 hover:border-primary/40 transition-colors cursor-pointer group">
                <CardHeader className="text-center pb-2">
                  <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4 group-hover:bg-primary/20 transition-colors">
                    <Plus className="h-8 w-8 text-primary" />
                  </div>
                  <CardTitle className="font-poppins">Create New Wishlist</CardTitle>
                </CardHeader>
                <CardContent>
                  <CardDescription className="text-center mb-4">
                    Start building your first wishlist. Add items, set preferences, and share with friends and family.
                  </CardDescription>
                  <Button className="w-full" asChild>
                    <Link href="/app/create">Create Wishlist</Link>
                  </Button>
                </CardContent>
              </Card>

              {/* Coming Soon Features */}
              <Card className="border-dashed border-muted-foreground/30">
                <CardContent className="p-8 text-center">
                  <div className="w-16 h-16 bg-muted/50 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Gift className="h-8 w-8 text-muted-foreground" />
                  </div>
                  <h3 className="text-lg font-semibold font-poppins mb-2">More Features Coming Soon!</h3>
                  <p className="text-muted-foreground text-sm">
                    Templates, family groups, and advanced sharing options are in development.
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </section>

      {/* How it Works */}
      <section className="py-16 bg-muted/30">
        <div className="container mx-auto px-4">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold font-poppins mb-4">How HeyWish Works</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Simple, intuitive wishlist creation and sharing in just a few steps.
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <div className="grid md:grid-cols-3 gap-8">
              <div className="text-center">
                <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-lg font-bold text-primary">1</span>
                </div>
                <h3 className="text-lg font-semibold font-poppins mb-2">Create & Customize</h3>
                <p className="text-muted-foreground">
                  Add items from any website, describe what you want, and set your preferences.
                </p>
              </div>
              
              <div className="text-center">
                <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-lg font-bold text-primary">2</span>
                </div>
                <h3 className="text-lg font-semibold font-poppins mb-2">Share Easily</h3>
                <p className="text-muted-foreground">
                  Generate a beautiful shareable link that works perfectly on any device.
                </p>
              </div>
              
              <div className="text-center">
                <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-lg font-bold text-primary">3</span>
                </div>
                <h3 className="text-lg font-semibold font-poppins mb-2">Receive Great Gifts</h3>
                <p className="text-muted-foreground">
                  Friends and family can see exactly what you want and coordinate gifts seamlessly.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Account Benefits */}
      <section className="py-16">
        <div className="container mx-auto px-4">
          <Card className="max-w-4xl mx-auto bg-gradient-to-r from-primary/5 via-purple-500/5 to-primary/5 border-primary/20">
            <CardContent className="p-8">
              <div className="text-center">
                <h3 className="text-2xl font-bold font-poppins mb-4">
                  Ready to save your wishlists?
                </h3>
                <p className="text-muted-foreground mb-6 max-w-2xl mx-auto">
                  Create an account to save your wishlists, sync across devices, and unlock advanced 
                  features like custom themes and family sharing.
                </p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <Button size="lg">
                    Create Account
                  </Button>
                  <Button variant="outline" size="lg">
                    Continue Without Account
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground mt-4">
                  No credit card required • Free to start • Keep your anonymous wishlists
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>
    </div>
  );
}