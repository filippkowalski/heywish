import Link from 'next/link';
import { Heart, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function ProfileNotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-b from-primary/5 via-background to-background px-4 text-center">
      <div className="rounded-3xl border border-dashed border-primary/30 bg-background/80 p-12 shadow-xl">
        <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-primary">
          <Heart className="h-8 w-8" />
        </div>
        <h1 className="mt-6 text-3xl font-semibold tracking-tight">We couldn’t find that profile</h1>
        <p className="mt-4 max-w-md text-sm text-muted-foreground">
          The username you entered doesn’t exist or the user hasn’t shared their profile yet. Double-check the link or explore featured wishlists on our home page.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Button asChild>
            <Link href="/">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back to HeyWish
            </Link>
          </Button>
          <Button variant="outline" asChild>
            <Link href="/blog">Read our stories</Link>
          </Button>
        </div>
      </div>
    </div>
  );
}
