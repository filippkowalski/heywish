import { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { getBlogPost, getAllBlogPosts } from '@/lib/blog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Calendar, Clock, ArrowLeft, Heart, Share2 } from 'lucide-react';

interface BlogPostPageProps {
  params: {
    slug: string;
  };
}

export async function generateStaticParams() {
  const posts = getAllBlogPosts();
  return posts.map((post) => ({
    slug: post.slug,
  }));
}

export async function generateMetadata({ params }: BlogPostPageProps): Promise<Metadata> {
  const post = await getBlogPost(params.slug);
  
  if (!post) {
    return {
      title: 'Post Not Found - HeyWish Blog',
    };
  }

  return {
    title: `${post.title} - HeyWish Blog`,
    description: post.description,
    openGraph: {
      title: post.title,
      description: post.description,
      type: 'article',
      publishedTime: post.date,
      authors: [post.author.name],
      images: post.image ? [{ url: post.image }] : undefined,
    },
    twitter: {
      card: 'summary_large_image',
      title: post.title,
      description: post.description,
      images: post.image ? [post.image] : undefined,
    },
  };
}

export default async function BlogPostPage({ params }: BlogPostPageProps) {
  const post = await getBlogPost(params.slug);

  if (!post) {
    notFound();
  }

  const formattedDate = new Date(post.date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  // Get other posts for "You might also like" section
  const allPosts = getAllBlogPosts();
  const otherPosts = allPosts
    .filter(p => p.slug !== post.slug)
    .slice(0, 3);

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
                <Link href="/blog">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Blog
                </Link>
              </Button>
              <Button size="sm" asChild>
                <Link href="/app">Open on Web</Link>
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Article Header */}
      <article className="container mx-auto px-4 py-16 max-w-4xl">
        {/* Breadcrumb */}
        <nav className="flex items-center text-sm text-muted-foreground mb-8">
          <Link href="/" className="hover:text-foreground">Home</Link>
          <span className="mx-2">/</span>
          <Link href="/blog" className="hover:text-foreground">Blog</Link>
          <span className="mx-2">/</span>
          <span className="text-foreground">{post.title}</span>
        </nav>

        {/* Tags */}
        <div className="flex flex-wrap gap-2 mb-6">
          {post.tags.map((tag) => (
            <Badge key={tag} variant="secondary">
              {tag}
            </Badge>
          ))}
        </div>

        {/* Title */}
        <h1 className="text-4xl lg:text-5xl font-bold font-poppins mb-6 leading-tight">
          {post.title}
        </h1>

        {/* Meta info */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-8 pb-8 border-b">
          <div className="flex items-center space-x-4 mb-4 sm:mb-0">
            <Avatar className="h-12 w-12">
              <AvatarImage src={post.author.avatar} alt={post.author.name} />
              <AvatarFallback>{post.author.name.split(' ').map(n => n[0]).join('')}</AvatarFallback>
            </Avatar>
            <div>
              <p className="font-medium">{post.author.name}</p>
              <div className="flex items-center space-x-4 text-sm text-muted-foreground">
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
          </div>
          
          <Button variant="outline" size="sm">
            <Share2 className="h-4 w-4 mr-2" />
            Share Article
          </Button>
        </div>

        {/* Hero Image */}
        {post.image && (
          <div className="relative h-64 md:h-96 lg:h-[500px] mb-12 rounded-xl overflow-hidden">
            <Image
              src={post.image}
              alt={post.title}
              fill
              className="object-cover"
            />
          </div>
        )}

        {/* Article Content */}
        <div className="max-w-none text-base leading-relaxed space-y-6
          [&>h1]:text-3xl [&>h1]:font-bold [&>h1]:font-poppins [&>h1]:text-foreground [&>h1]:mb-6 [&>h1]:mt-8
          [&>h2]:text-2xl [&>h2]:font-bold [&>h2]:font-poppins [&>h2]:text-foreground [&>h2]:mb-4 [&>h2]:mt-8
          [&>h3]:text-xl [&>h3]:font-bold [&>h3]:font-poppins [&>h3]:text-foreground [&>h3]:mb-3 [&>h3]:mt-6
          [&>h4]:text-lg [&>h4]:font-semibold [&>h4]:font-poppins [&>h4]:text-foreground [&>h4]:mb-2 [&>h4]:mt-4
          [&>p]:text-muted-foreground [&>p]:leading-relaxed [&>p]:mb-4
          [&>ul]:list-disc [&>ul]:pl-6 [&>ul]:text-muted-foreground [&>ul]:space-y-1
          [&>ol]:list-decimal [&>ol]:pl-6 [&>ol]:text-muted-foreground [&>ol]:space-y-1
          [&>li]:text-muted-foreground
          [&>blockquote]:border-l-4 [&>blockquote]:border-primary [&>blockquote]:bg-primary/5 [&>blockquote]:pl-6 [&>blockquote]:py-4 [&>blockquote]:my-4 [&>blockquote]:italic
          [&>strong]:font-semibold [&>strong]:text-foreground
          [&>em]:italic [&>em]:text-muted-foreground
          [&>code]:bg-muted [&>code]:px-1 [&>code]:py-0.5 [&>code]:rounded [&>code]:text-sm [&>code]:font-mono
          [&>pre]:bg-muted [&>pre]:p-4 [&>pre]:rounded-lg [&>pre]:overflow-x-auto
          [&>a]:text-primary [&>a]:no-underline hover:[&>a]:underline
          [&>img]:rounded-lg [&>img]:shadow-md [&>img]:my-6">
          <div dangerouslySetInnerHTML={{ __html: post.content }} />
        </div>

        {/* Call to Action */}
        <Card className="mt-16 bg-gradient-to-r from-primary/5 via-purple-500/5 to-primary/5 border-primary/20">
          <CardContent className="p-8 text-center">
            <Heart className="h-12 w-12 text-primary mx-auto mb-4" />
            <h3 className="text-2xl font-bold font-poppins mb-4">
              Ready to create your perfect wishlist?
            </h3>
            <p className="text-muted-foreground mb-6 max-w-md mx-auto">
              Put these insights to work and start building wishlists that make gifting delightful for everyone.
            </p>
            <Button size="lg" asChild>
              <Link href="/app">Open on Web</Link>
            </Button>
          </CardContent>
        </Card>
      </article>

      {/* Related Posts */}
      {otherPosts.length > 0 && (
        <section className="bg-muted/30 py-16">
          <div className="container mx-auto px-4">
            <h2 className="text-3xl font-bold font-poppins mb-8 text-center">
              You might also like
            </h2>
            <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
              {otherPosts.map((relatedPost) => (
                <Card key={relatedPost.slug} className="hover:shadow-lg transition-shadow">
                  {relatedPost.image && (
                    <div className="relative h-48 overflow-hidden rounded-t-lg">
                      <Image
                        src={relatedPost.image}
                        alt={relatedPost.title}
                        fill
                        className="object-cover"
                      />
                    </div>
                  )}
                  
                  <CardContent className="p-6">
                    <div className="flex flex-wrap gap-2 mb-3">
                      {relatedPost.tags.slice(0, 2).map((tag) => (
                        <Badge key={tag} variant="secondary" className="text-xs">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                    
                    <h3 className="text-xl font-poppins font-bold mb-3 line-clamp-2">
                      <Link href={`/blog/${relatedPost.slug}`} className="hover:text-primary transition-colors">
                        {relatedPost.title}
                      </Link>
                    </h3>
                    
                    <p className="text-muted-foreground mb-4 line-clamp-3">
                      {relatedPost.description}
                    </p>
                    
                    <div className="flex items-center justify-between text-sm text-muted-foreground mb-4">
                      <div className="flex items-center">
                        <Calendar className="h-4 w-4 mr-1" />
                        {new Date(relatedPost.date).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                        })}
                      </div>
                      <div className="flex items-center">
                        <Clock className="h-4 w-4 mr-1" />
                        {relatedPost.readingTime}
                      </div>
                    </div>
                    
                    <Button variant="outline" size="sm" asChild>
                      <Link href={`/blog/${relatedPost.slug}`}>Read More</Link>
                    </Button>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        </section>
      )}
    </div>
  );
}