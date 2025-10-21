import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Sparkles, ArrowRight, Apple, PlaySquare } from "lucide-react";

export default function HomePage() {
  return (
    <main className="min-h-screen bg-background">
      <section className="border-b bg-gradient-to-br from-primary/5 via-transparent to-secondary/30">
        <div className="container mx-auto flex min-h-[70vh] flex-col items-center justify-center gap-10 px-4 py-20 text-center md:px-6">
          <div className="space-y-6 md:max-w-3xl">
            <Badge variant="outline" className="mx-auto flex w-fit items-center gap-2 border-primary/30 text-xs uppercase tracking-wide">
              <Sparkles className="h-3.5 w-3.5 text-primary" />
              Mobile-first wishlist sharing
            </Badge>
            <h1 className="text-4xl font-semibold leading-tight md:text-5xl">
              Jinnie keeps wishlists in sync with the people you care about.
            </h1>
            <p className="text-lg text-muted-foreground">
              Create, manage, and share your lists from the Jinnie app. Friends with a direct link can still view profiles and wishlists right here on the web.
            </p>
          </div>

          <div className="flex flex-col gap-4 md:flex-row">
            <Button
              asChild
              size="lg"
              className="gap-2 px-8"
            >
              <Link href="https://apps.apple.com/app/id6504302007" target="_blank" rel="noreferrer">
                <Apple className="h-5 w-5" />
                Download on the App Store
              </Link>
            </Button>
            <Button
              asChild
              size="lg"
              variant="outline"
              className="gap-2 px-8"
            >
              <Link href="https://play.google.com/store/apps/details?id=app.jinnie" target="_blank" rel="noreferrer">
                <PlaySquare className="h-5 w-5" />
                Get it on Google Play
              </Link>
            </Button>
          </div>
        </div>
      </section>

      <section className="container mx-auto flex flex-col items-center gap-4 px-4 py-12 text-center text-sm text-muted-foreground md:px-6">
        <p className="max-w-xl">
          Already have a link? Just open it directly&mdash;for example{" "}
          <Link href="https://jinnie.co/jinnie" className="font-medium text-primary hover:underline">
            jinnie.co/jinnie
          </Link>{" "}
          takes you to our official public profile.
        </p>
        <div className="flex flex-wrap justify-center gap-3">
          <Button variant="ghost" size="sm" asChild>
            <Link href="mailto:hello@jinnie.app">
              Contact support
            </Link>
          </Button>
          <Button variant="ghost" size="sm" asChild>
            <Link href="https://heywish.notion.site/Jinnie-Preview" target="_blank" rel="noreferrer">
              Product roadmap
              <ArrowRight className="ml-2 h-4 w-4" />
            </Link>
          </Button>
        </div>
      </section>
    </main>
  );
}
