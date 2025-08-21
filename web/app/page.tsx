import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Heart, Gift, Share2, Smartphone, Users, Shield, Zap, CheckCircle, Star, ArrowRight, Play } from "lucide-react";
import Link from "next/link";
import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Heart className="h-8 w-8 text-primary" />
              <span className="text-2xl font-bold font-poppins">HeyWish</span>
            </div>
            <div className="hidden md:flex items-center space-x-6">
              <Link href="#features" className="text-sm font-medium hover:text-primary transition-colors">Features</Link>
              <Link href="/blog" className="text-sm font-medium hover:text-primary transition-colors">Blog</Link>
              <Link href="/about" className="text-sm font-medium hover:text-primary transition-colors">About</Link>
              <Button variant="ghost" size="sm">Sign In</Button>
              <Button size="sm" asChild>
                <Link href="/app">Open on Web</Link>
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 lg:py-32 relative overflow-hidden">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto text-center">
            <Badge className="mb-6" variant="outline">
              <Zap className="w-3 h-3 mr-1" />
              Now Available on Web & Mobile
            </Badge>
            <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold font-poppins mb-6 leading-tight">
              Making gifting{" "}
              <span className="bg-gradient-to-r from-primary via-purple-500 to-primary bg-clip-text text-transparent">
                delightful
              </span>
            </h1>
            <p className="text-xl lg:text-2xl text-muted-foreground mb-10 max-w-3xl mx-auto leading-relaxed">
              Create beautiful wishlists, share them with friends and family, and never miss the perfect gift again. 
              The modern wishlist platform for thoughtful gifting.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
              <Button size="lg" className="text-lg px-8 py-6">
                <Smartphone className="h-5 w-5 mr-2" />
                Download Mobile App
              </Button>
              <Button variant="outline" size="lg" className="text-lg px-8 py-6" asChild>
                <Link href="/app">
                  Open on Web
                  <ArrowRight className="h-5 w-5 ml-2" />
                </Link>
              </Button>
            </div>
            
            {/* Social Proof */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-6 text-sm text-muted-foreground">
              <div className="flex items-center">
                <div className="flex -space-x-2 mr-3">
                  {[1,2,3,4,5].map((i) => (
                    <div key={i} className="w-8 h-8 rounded-full bg-gradient-to-r from-primary/20 to-purple-500/20 border-2 border-background flex items-center justify-center">
                      <Heart className="w-3 h-3 text-primary" />
                    </div>
                  ))}
                </div>
                <span>Join 1000+ happy gift givers</span>
              </div>
              <div className="flex items-center">
                <div className="flex text-yellow-400 mr-2">
                  {[1,2,3,4,5].map((i) => (
                    <Star key={i} className="w-4 h-4 fill-current" />
                  ))}
                </div>
                <span>4.9/5 rating</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 lg:py-32 bg-muted/30">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-5xl font-bold font-poppins mb-4">Why thousands choose HeyWish</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Everything you need to create, share, and manage wishlists that bring joy to both gift givers and receivers.
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 mb-16">
            <Card className="border-0 shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center pb-4">
                <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Heart className="h-8 w-8 text-primary" />
                </div>
                <CardTitle className="text-xl font-poppins">Easy Wishlist Creation</CardTitle>
              </CardHeader>
              <CardContent className="text-center">
                <CardDescription className="text-base">
                  Add items from any website with a simple URL. Our smart scraper fetches all the details automatically.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center pb-4">
                <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Share2 className="h-8 w-8 text-primary" />
                </div>
                <CardTitle className="text-xl font-poppins">Beautiful Sharing</CardTitle>
              </CardHeader>
              <CardContent className="text-center">
                <CardDescription className="text-base">
                  Share your wishlists with elegant, mobile-friendly links. Friends can view and reserve items instantly.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center pb-4">
                <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Gift className="h-8 w-8 text-primary" />
                </div>
                <CardTitle className="text-xl font-poppins">Gift Coordination</CardTitle>
              </CardHeader>
              <CardContent className="text-center">
                <CardDescription className="text-base">
                  No more duplicate gifts! Reserved items are hidden from the wishlist owner but visible to gift givers.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center pb-4">
                <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Users className="h-8 w-8 text-primary" />
                </div>
                <CardTitle className="text-xl font-poppins">Social Features</CardTitle>
              </CardHeader>
              <CardContent className="text-center">
                <CardDescription className="text-base">
                  Connect with friends, see their wishlists, and discover gift inspiration from your social circle.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center pb-4">
                <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Shield className="h-8 w-8 text-primary" />
                </div>
                <CardTitle className="text-xl font-poppins">Privacy First</CardTitle>
              </CardHeader>
              <CardContent className="text-center">
                <CardDescription className="text-base">
                  Control who sees your wishlists with granular privacy settings. Share publicly, with friends, or keep private.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg hover:shadow-xl transition-shadow">
              <CardHeader className="text-center pb-4">
                <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Zap className="h-8 w-8 text-primary" />
                </div>
                <CardTitle className="text-xl font-poppins">Lightning Fast</CardTitle>
              </CardHeader>
              <CardContent className="text-center">
                <CardDescription className="text-base">
                  Built for speed on both web and mobile. Add items, share lists, and coordinate gifts in seconds.
                </CardDescription>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-20 lg:py-32">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-5xl font-bold font-poppins mb-4">How it works</h2>
            <p className="text-xl text-muted-foreground">Get started in minutes, delight for years</p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            <div className="text-center">
              <div className="w-20 h-20 bg-primary rounded-full flex items-center justify-center mx-auto mb-6 text-white text-2xl font-bold">
                1
              </div>
              <h3 className="text-xl font-semibold font-poppins mb-3">Create Your Wishlist</h3>
              <p className="text-muted-foreground">
                Add items by URL, manual entry, or from our curated suggestions. Organize by priority and add personal notes.
              </p>
            </div>
            
            <div className="text-center">
              <div className="w-20 h-20 bg-primary rounded-full flex items-center justify-center mx-auto mb-6 text-white text-2xl font-bold">
                2
              </div>
              <h3 className="text-xl font-semibold font-poppins mb-3">Share with Loved Ones</h3>
              <p className="text-muted-foreground">
                Send a beautiful link via text, email, or social media. Recipients can view without creating an account.
              </p>
            </div>
            
            <div className="text-center">
              <div className="w-20 h-20 bg-primary rounded-full flex items-center justify-center mx-auto mb-6 text-white text-2xl font-bold">
                3
              </div>
              <h3 className="text-xl font-semibold font-poppins mb-3">Coordinate & Surprise</h3>
              <p className="text-muted-foreground">
                Friends reserve items secretly. No duplicate gifts, maximum joy on the big day.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Demo/CTA Section */}
      <section className="py-20 lg:py-32 bg-gradient-to-br from-primary/5 via-purple-500/5 to-primary/5">
        <div className="container mx-auto px-4 text-center">
          <div className="max-w-4xl mx-auto">
            <h2 className="text-3xl lg:text-5xl font-bold font-poppins mb-6">See it in action</h2>
            <p className="text-xl text-muted-foreground mb-10">
              Experience how beautiful wishlist sharing can be with our live demo
            </p>
            
            <div className="bg-white rounded-2xl shadow-2xl p-8 mb-10">
              <div className="flex items-center justify-center mb-6">
                <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
                  <Play className="h-8 w-8 text-primary" />
                </div>
              </div>
              <h3 className="text-xl font-semibold mb-4">Try our interactive demo</h3>
              <p className="text-muted-foreground mb-6">
                See exactly how your friends will experience your shared wishlists
              </p>
              <Button size="lg" asChild>
                <Link href="/w/vEDutgeFgwKl">
                  <Heart className="h-5 w-5 mr-2" />
                  View Live Demo Wishlist
                </Link>
              </Button>
            </div>
            
            <div className="text-sm text-muted-foreground">
              ↑ This is a real wishlist shared using HeyWish
            </div>
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-20 lg:py-32 bg-primary text-white">
        <div className="container mx-auto px-4 text-center">
          <div className="max-w-3xl mx-auto">
            <h2 className="text-3xl lg:text-5xl font-bold font-poppins mb-6">
              Ready to make gifting delightful?
            </h2>
            <p className="text-xl mb-10 text-primary-foreground/80">
              Join thousands of people who've discovered the joy of thoughtful, coordinated gift-giving.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" variant="secondary" className="text-lg px-8 py-6">
                <Smartphone className="h-5 w-5 mr-2" />
                Download Mobile App
              </Button>
              <Button size="lg" variant="outline" className="text-lg px-8 py-6 bg-white text-primary hover:bg-white/90" asChild>
                <Link href="/app">
                  Try Web App Free
                  <ArrowRight className="h-5 w-5 ml-2" />
                </Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-16 bg-muted/30">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <Heart className="h-6 w-6 text-primary" />
                <span className="text-xl font-bold font-poppins">HeyWish</span>
              </div>
              <p className="text-muted-foreground text-sm mb-4">
                Making gifting delightful, one wishlist at a time.
              </p>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Product</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><Link href="/features" className="hover:text-primary transition-colors">Features</Link></li>
                <li><Link href="/pricing" className="hover:text-primary transition-colors">Pricing</Link></li>
                <li><Link href="/app" className="hover:text-primary transition-colors">Web App</Link></li>
                <li><Link href="#" className="hover:text-primary transition-colors">Mobile App</Link></li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Company</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><Link href="/about" className="hover:text-primary transition-colors">About</Link></li>
                <li><Link href="/blog" className="hover:text-primary transition-colors">Blog</Link></li>
                <li><Link href="/contact" className="hover:text-primary transition-colors">Contact</Link></li>
                <li><Link href="/careers" className="hover:text-primary transition-colors">Careers</Link></li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Support</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><Link href="/help" className="hover:text-primary transition-colors">Help Center</Link></li>
                <li><Link href="/privacy" className="hover:text-primary transition-colors">Privacy</Link></li>
                <li><Link href="/terms" className="hover:text-primary transition-colors">Terms</Link></li>
                <li><Link href="/security" className="hover:text-primary transition-colors">Security</Link></li>
              </ul>
            </div>
          </div>
          
          <div className="border-t pt-8 flex flex-col md:flex-row justify-between items-center text-sm text-muted-foreground">
            <div>© 2024 HeyWish. All rights reserved.</div>
            <div className="flex space-x-6 mt-4 md:mt-0">
              <Link href="#" className="hover:text-primary transition-colors">Twitter</Link>
              <Link href="#" className="hover:text-primary transition-colors">Instagram</Link>
              <Link href="#" className="hover:text-primary transition-colors">LinkedIn</Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
