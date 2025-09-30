import { Metadata } from 'next';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Heart, Users, Lightbulb, Shield, Globe, ArrowRight } from 'lucide-react';

export const metadata: Metadata = {
  title: 'About Us - HeyWish',
  description: 'Learn about HeyWish&apos;s mission to make gifting more delightful. Discover our story, values, and commitment to helping people give and receive meaningful gifts.',
  openGraph: {
    title: 'About Us - HeyWish',
    description: 'Learn about HeyWish&apos;s mission to make gifting more delightful through modern wishlist technology.',
  },
};

export default function AboutPage() {
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
            <div className="hidden md:flex items-center space-x-6">
              <Link href="/blog" className="text-muted-foreground hover:text-foreground transition-colors">
                Blog
              </Link>
              <Link href="/about" className="text-foreground font-medium">
                About
              </Link>
            </div>
            <div className="flex items-center space-x-4">
              <Button variant="ghost" size="sm" asChild>
                <Link href="/">Home</Link>
              </Button>
              <Button size="sm" asChild>
                <Link href="/app">Open on Web</Link>
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="py-20 bg-gradient-to-br from-primary/5 via-purple-500/5 to-primary/5">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl lg:text-6xl font-bold font-poppins mb-6">
            Making gifting{" "}
            <span className="bg-gradient-to-r from-primary via-purple-500 to-primary bg-clip-text text-transparent">
              delightful
            </span>
          </h1>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto mb-8">
            We believe that giving and receiving gifts should be joyful, meaningful, and stress-free. 
            HeyWish is transforming how people share their wishes and create memorable moments through thoughtful gifting.
          </p>
        </div>
      </section>

      {/* Mission Section */}
      <section className="py-20">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-3xl lg:text-4xl font-bold font-poppins mb-6">Our Mission</h2>
              <p className="text-xl text-muted-foreground">
                To eliminate the guesswork from gift-giving and help people express their care through meaningful presents.
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-12 items-center">
              <div>
                <h3 className="text-2xl font-bold font-poppins mb-6">The Problem We&apos;re Solving</h3>
                <div className="space-y-4">
                  <p className="text-muted-foreground">
                    Gift-giving should bring joy, but too often it becomes a source of stress and disappointment. 
                    People struggle to find the perfect gifts, waste time and money on unwanted items, and miss 
                    opportunities to show they truly care.
                  </p>
                  <p className="text-muted-foreground">
                    Traditional wishlists are outdated, scattered across different platforms, or buried in 
                    forgotten conversations. We saw an opportunity to revolutionize this experience.
                  </p>
                </div>
              </div>
              
              <div className="relative">
                <div className="bg-gradient-to-br from-primary/10 to-purple-500/10 rounded-2xl p-8">
                  <Heart className="h-16 w-16 text-primary mb-6" />
                  <h4 className="text-xl font-bold font-poppins mb-4">Our Vision</h4>
                  <p className="text-muted-foreground">
                    A world where every gift is thoughtful, every wish is heard, and every special moment 
                    is celebrated with meaningful presents that strengthen relationships.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section className="py-20 bg-muted/30">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold font-poppins mb-6">Our Values</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              The principles that guide everything we build and every decision we make.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <Card className="border-0 shadow-lg">
              <CardHeader className="text-center pb-2">
                <Users className="h-12 w-12 text-primary mx-auto mb-4" />
                <CardTitle className="font-poppins">People First</CardTitle>
              </CardHeader>
              <CardContent>
                <CardDescription className="text-center">
                  We prioritize human connections and relationships over technology for technology&apos;s sake.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardHeader className="text-center pb-2">
                <Lightbulb className="h-12 w-12 text-primary mx-auto mb-4" />
                <CardTitle className="font-poppins">Thoughtful Innovation</CardTitle>
              </CardHeader>
              <CardContent>
                <CardDescription className="text-center">
                  We build features that solve real problems and enhance the gifting experience.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardHeader className="text-center pb-2">
                <Shield className="h-12 w-12 text-primary mx-auto mb-4" />
                <CardTitle className="font-poppins">Privacy & Trust</CardTitle>
              </CardHeader>
              <CardContent>
                <CardDescription className="text-center">
                  Your personal information and wish data are protected with the highest security standards.
                </CardDescription>
              </CardContent>
            </Card>

            <Card className="border-0 shadow-lg">
              <CardHeader className="text-center pb-2">
                <Globe className="h-12 w-12 text-primary mx-auto mb-4" />
                <CardTitle className="font-poppins">Inclusive Access</CardTitle>
              </CardHeader>
              <CardContent>
                <CardDescription className="text-center">
                  Gifting should be accessible to everyone, regardless of technical expertise or budget.
                </CardDescription>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Story Section */}
      <section className="py-20">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-3xl lg:text-4xl font-bold font-poppins mb-6">Our Story</h2>
              <p className="text-xl text-muted-foreground">
                Born from frustration with outdated gifting experiences.
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-12 items-center mb-16">
              <div>
                <h3 className="text-2xl font-bold font-poppins mb-6">The Inspiration</h3>
                <div className="space-y-4">
                  <p className="text-muted-foreground">
                    HeyWish began when our founders experienced the same frustrations that millions of people 
                    face during gift-giving seasons. Despite having access to more products than ever before, 
                    finding the right gift felt harder than it should be.
                  </p>
                  <p className="text-muted-foreground">
                    We realized that the problem wasn&apos;t a lack of options—it was a lack of clear communication 
                    about what people actually wanted. Traditional wishlists were either too rigid, too hidden, 
                    or too complicated to use effectively.
                  </p>
                </div>
              </div>
              
              <div className="bg-gradient-to-br from-primary/5 to-purple-500/5 rounded-2xl p-8">
                <div className="text-center">
                  <div className="text-4xl font-bold font-poppins text-primary mb-2">2024</div>
                  <div className="text-lg font-medium mb-4">Founded</div>
                  <div className="text-muted-foreground">
                    Started with a simple goal: make wishlist sharing as easy as sending a text message.
                  </div>
                </div>
              </div>
            </div>

            <div className="grid md:grid-cols-3 gap-8">
              <div className="text-center">
                <div className="text-3xl font-bold font-poppins text-primary mb-2">10K+</div>
                <div className="text-lg font-medium mb-2">Early Adopters</div>
                <div className="text-sm text-muted-foreground">
                  People testing our beta platform
                </div>
              </div>
              
              <div className="text-center">
                <div className="text-3xl font-bold font-poppins text-primary mb-2">50K+</div>
                <div className="text-lg font-medium mb-2">Wishes Created</div>
                <div className="text-sm text-muted-foreground">
                  Items added to wishlists so far
                </div>
              </div>
              
              <div className="text-center">
                <div className="text-3xl font-bold font-poppins text-primary mb-2">95%</div>
                <div className="text-lg font-medium mb-2">Satisfaction Rate</div>
                <div className="text-sm text-muted-foreground">
                  From our beta user feedback
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-20 bg-muted/30">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold font-poppins mb-6">Built by Gift-Givers</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Our team combines expertise in technology, design, and user experience to create 
              the most intuitive gifting platform ever built.
            </p>
          </div>

          <div className="max-w-2xl mx-auto text-center">
            <p className="text-lg text-muted-foreground mb-8">
              We&apos;re a distributed team of designers, developers, and product experts who are passionate 
              about solving real human problems. Every feature we build is tested with real families, 
              friends, and gift-giving communities to ensure it truly makes gifting more delightful.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" asChild>
                <Link href="/app">
                  Try HeyWish Today
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Link>
              </Button>
              <Button variant="outline" size="lg" asChild>
                <Link href="/blog">Read Our Blog</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-background border-t py-16">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8">
            <div className="space-y-4">
              <Link href="/" className="flex items-center space-x-2">
                <Heart className="h-8 w-8 text-primary" />
                <span className="text-2xl font-bold font-poppins">HeyWish</span>
              </Link>
              <p className="text-muted-foreground">
                Making gifting delightful for everyone.
              </p>
            </div>

            <div className="space-y-4">
              <h3 className="font-semibold">Product</h3>
              <div className="space-y-2 text-sm">
                <Link href="/app" className="block text-muted-foreground hover:text-foreground transition-colors">
                  Open on Web
                </Link>
                <Link href="/features" className="block text-muted-foreground hover:text-foreground transition-colors">
                  Features
                </Link>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="font-semibold">Company</h3>
              <div className="space-y-2 text-sm">
                <Link href="/about" className="block text-foreground font-medium">
                  About
                </Link>
                <Link href="/blog" className="block text-muted-foreground hover:text-foreground transition-colors">
                  Blog
                </Link>
                <Link href="/contact" className="block text-muted-foreground hover:text-foreground transition-colors">
                  Contact
                </Link>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="font-semibold">Support</h3>
              <div className="space-y-2 text-sm">
                <Link href="/help" className="block text-muted-foreground hover:text-foreground transition-colors">
                  Help Center
                </Link>
                <Link href="/privacy" className="block text-muted-foreground hover:text-foreground transition-colors">
                  Privacy
                </Link>
                <Link href="/terms" className="block text-muted-foreground hover:text-foreground transition-colors">
                  Terms
                </Link>
              </div>
            </div>
          </div>

          <div className="border-t mt-12 pt-8 text-center text-muted-foreground">
            <p>&copy; 2024 HeyWish. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
