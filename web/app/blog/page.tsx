import { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { getAllBlogPosts, BlogPostMetadata } from '@/lib/blog';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Calendar, Clock, ArrowLeft, Heart } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Blog - HeyWish',
  description: 'Gift guides, wishlist tips, and insights to make gifting more delightful. Learn how to create the perfect wishlists and give meaningful gifts.',
  openGraph: {
    title: 'Blog - HeyWish',
    description: 'Gift guides, wishlist tips, and insights to make gifting more delightful.',
  },
};

export default function BlogPage() {
  const posts = getAllBlogPosts();
  const featuredPosts = posts.filter(post => post.featured);
  const regularPosts = posts.filter(post => !post.featured);

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
              <Button size="sm" asChild>
                <Link href="/app">Open on Web</Link>
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Header */}
      <section className="py-16 bg-gradient-to-br from-primary/5 via-purple-500/5 to-primary/5">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl lg:text-6xl font-bold font-poppins mb-6">
            The HeyWish Blog
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Gift guides, wishlist tips, and insights to make gifting more delightful.
            Learn how to create the perfect wishlists and give meaningful gifts.
          </p>
        </div>
      </section>

      <div className="container mx-auto px-4 py-16">
        {posts.length === 0 ? (
          /* Empty State */
          <div className="text-center py-16">
            <div className="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <Heart className="h-12 w-12 text-primary" />
            </div>
            <h2 className="text-2xl font-bold font-poppins mb-4">Coming Soon!</h2>
            <p className="text-muted-foreground mb-8 max-w-md mx-auto">
              We're working on amazing content about gifting, wishlists, and making special moments even more special.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button asChild>
                <Link href="/app">Open on Web</Link>
              </Button>
              <Button variant="outline" asChild>
                <Link href="/">Learn More</Link>
              </Button>
            </div>
          </div>
        ) : (
          <>
            {/* Featured Posts */}
            {featuredPosts.length > 0 && (
              <section className="mb-16">
                <h2 className="text-3xl font-bold font-poppins mb-8">Featured Articles</h2>
                <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
                  {featuredPosts.map((post) => (
                    <BlogPostCard key={post.slug} post={post} featured />
                  ))}
                </div>
              </section>
            )}

            {/* All Posts */}
            <section>
              <h2 className="text-3xl font-bold font-poppins mb-8">All Articles</h2>
              <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
                {regularPosts.map((post) => (
                  <BlogPostCard key={post.slug} post={post} />
                ))}
              </div>
            </section>
          </>
        )}
      </div>
    </div>
  );
}

function BlogPostCard({ post, featured = false }: { post: BlogPostMetadata; featured?: boolean }) {
  const formattedDate = new Date(post.date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  return (
    <Card className={`hover:shadow-lg transition-shadow ${featured ? 'border-primary/20 shadow-md' : ''}`}>
      {post.image && (
        <div className="relative h-48 overflow-hidden rounded-t-lg">
          <Image
            src={post.image}
            alt={post.title}
            fill
            className="object-cover"
          />
          {featured && (
            <Badge className="absolute top-4 left-4">Featured</Badge>
          )}
        </div>
      )}
      
      <CardHeader>
        <div className="flex flex-wrap gap-2 mb-3">
          {post.tags.map((tag) => (
            <Badge key={tag} variant="secondary" className="text-xs">
              {tag}
            </Badge>
          ))}
        </div>
        <CardTitle className="text-xl font-poppins line-clamp-2">
          <Link href={`/blog/${post.slug}`} className="hover:text-primary transition-colors">
            {post.title}
          </Link>
        </CardTitle>
      </CardHeader>
      
      <CardContent>
        <CardDescription className="text-base mb-4 line-clamp-3">
          {post.description}
        </CardDescription>
        
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <Calendar className="h-4 w-4 mr-1" />
              {formattedDate}
            </div>
            <div className="flex items-center">
              <Clock className="h-4 w-4 mr-1" />
              {post.readingTime}
            </div>
          </div>
        </div>
        
        <div className="mt-4">
          <Button variant="outline" size="sm" asChild>
            <Link href={`/blog/${post.slug}`}>Read More</Link>
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}