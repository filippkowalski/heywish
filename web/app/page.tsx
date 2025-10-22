import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Sparkles, Apple, PlaySquare, Heart, Users, Gift } from "lucide-react";

export default function HomePage() {
  return (
    <main className="min-h-screen bg-background">
      {/* Hero Section */}
      <section className="relative overflow-hidden border-b">
        {/* Animated gradient orbs */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute -left-40 top-20 h-96 w-96 animate-float rounded-full bg-gradient-to-br from-primary/10 to-transparent blur-3xl" />
          <div className="absolute -right-40 top-60 h-96 w-96 animate-float-delayed rounded-full bg-gradient-to-bl from-primary/10 to-transparent blur-3xl animation-delay-2000" />
          <div className="absolute left-1/3 -bottom-40 h-96 w-96 animate-float-slow rounded-full bg-gradient-to-tr from-primary/5 to-transparent blur-3xl animation-delay-1000" />
        </div>

        {/* Subtle gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-primary/[0.02] via-transparent to-primary/[0.03]" />

        {/* Floating decorative icons */}
        <div className="absolute inset-0 overflow-hidden">
          <Sparkles className="absolute left-[10%] top-[20%] h-6 w-6 animate-float text-primary/20 animation-delay-500" />
          <Heart className="absolute right-[15%] top-[30%] h-5 w-5 animate-float-delayed text-primary/15 animation-delay-1500" />
          <Gift className="absolute left-[85%] top-[60%] h-6 w-6 animate-float-slow text-primary/20 animation-delay-3000" />
          <Sparkles className="absolute left-[20%] bottom-[25%] h-4 w-4 animate-float text-primary/15 animation-delay-2500" />
        </div>

        <div className="container relative mx-auto flex min-h-[85vh] flex-col items-center justify-center px-4 py-24 text-center md:px-6 md:py-32">
          <div className="mx-auto max-w-4xl space-y-10">
            {/* Badge */}
            <div className="animate-fade-in-up">
              <Badge
                variant="outline"
                className="inline-flex items-center gap-2 border-primary/20 bg-background/50 px-4 py-1.5 text-xs font-medium tracking-wide backdrop-blur-sm"
              >
                <Sparkles className="h-3.5 w-3.5 text-primary" />
                Your Modern Wishlist Platform
              </Badge>
            </div>

            {/* Main Heading */}
            <div className="space-y-6 animate-fade-in-up animation-delay-100">
              <h1 className="font-poppins text-5xl font-semibold leading-[1.15] tracking-tight md:text-6xl lg:text-7xl">
                Keep wishlists in sync with the people you{" "}
                <span className="relative inline-block">
                  <span className="relative z-10">care about</span>
                  <span className="absolute -bottom-2 left-0 h-3 w-full bg-primary/10 -rotate-1" />
                </span>
              </h1>
              <p className="mx-auto max-w-2xl text-lg leading-relaxed text-muted-foreground md:text-xl">
                Create, manage, and share your wishlists effortlessly. Make gift-giving magical with the Jinnie mobile app.
              </p>
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col items-center gap-4 pt-4 animate-fade-in-up animation-delay-200 sm:flex-row sm:justify-center">
              <Button
                asChild
                size="lg"
                className="group h-12 gap-2 px-8 text-base font-medium shadow-lg shadow-primary/20 transition-all hover:shadow-xl hover:shadow-primary/30"
              >
                <Link href="https://apps.apple.com/app/id6504302007" target="_blank" rel="noreferrer">
                  <Apple className="h-5 w-5 transition-transform group-hover:scale-110" />
                  Download on App Store
                </Link>
              </Button>
              <Button
                asChild
                size="lg"
                variant="outline"
                className="group h-12 gap-2 border-primary/20 px-8 text-base font-medium backdrop-blur-sm transition-all hover:border-primary/40 hover:bg-primary/5"
              >
                <Link href="https://play.google.com/store/apps/details?id=app.jinnie" target="_blank" rel="noreferrer">
                  <PlaySquare className="h-5 w-5 transition-transform group-hover:scale-110" />
                  Get it on Google Play
                </Link>
              </Button>
            </div>
          </div>

          {/* Scroll indicator */}
          <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
            <div className="h-10 w-6 rounded-full border-2 border-primary/20">
              <div className="mx-auto mt-2 h-1.5 w-1.5 rounded-full bg-primary/40" />
            </div>
          </div>
        </div>
      </section>

      {/* App Preview Section */}
      <section className="relative overflow-hidden border-b bg-gradient-to-b from-background to-muted/20">
        <div className="container mx-auto px-4 py-20 md:px-6 md:py-32">
          <div className="mx-auto max-w-6xl">
            <div className="mb-16 text-center">
              <h2 className="font-poppins text-3xl font-semibold tracking-tight md:text-4xl lg:text-5xl">
                Beautiful wishlists,{" "}
                <span className="text-primary">right in your pocket</span>
              </h2>
              <p className="mx-auto mt-4 max-w-2xl text-lg text-muted-foreground">
                Experience seamless wishlist management with our intuitive mobile app
              </p>
            </div>

            {/* Phone Mockup - Placeholder for screenshots */}
            <div className="relative mx-auto max-w-4xl">
              <div className="flex items-center justify-center gap-8">
                {/* Center Phone */}
                <div className="relative animate-float-slow">
                  <div className="relative h-[600px] w-[280px] rounded-[3rem] border-8 border-foreground/10 bg-background shadow-2xl">
                    <div className="absolute left-1/2 top-6 h-1 w-16 -translate-x-1/2 rounded-full bg-foreground/20" />
                    <div className="mt-12 flex h-full flex-col items-center justify-center gap-8 px-8 pb-12">
                      <div className="flex h-20 w-20 items-center justify-center rounded-2xl bg-primary/10">
                        <Heart className="h-10 w-10 text-primary" />
                      </div>
                      <div className="space-y-2 text-center">
                        <h3 className="font-poppins text-xl font-semibold">Your Wishlists</h3>
                        <p className="text-sm text-muted-foreground">
                          Create and manage unlimited wishlists
                        </p>
                      </div>
                      {/* Placeholder wishlist items */}
                      <div className="w-full space-y-3">
                        {[1, 2, 3].map((i) => (
                          <div
                            key={i}
                            className="flex items-center gap-3 rounded-xl border border-primary/10 bg-muted/50 p-3"
                          >
                            <div className="h-12 w-12 rounded-lg bg-primary/10" />
                            <div className="flex-1 space-y-1.5">
                              <div className="h-2 w-3/4 rounded bg-foreground/10" />
                              <div className="h-2 w-1/2 rounded bg-foreground/5" />
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Decorative elements */}
              <div className="absolute -left-20 top-1/4 h-40 w-40 animate-float rounded-full bg-gradient-to-br from-primary/20 to-transparent blur-3xl" />
              <div className="absolute -right-20 bottom-1/4 h-40 w-40 animate-float-delayed rounded-full bg-gradient-to-bl from-primary/20 to-transparent blur-3xl animation-delay-2000" />
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="border-b bg-muted/30">
        <div className="container mx-auto px-4 py-20 md:px-6 md:py-28">
          <div className="mx-auto grid max-w-5xl gap-8 md:grid-cols-3 md:gap-12">
            <div className="group space-y-4 text-center">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/5 transition-all group-hover:scale-110 group-hover:bg-primary/10">
                <Heart className="h-7 w-7 text-primary" />
              </div>
              <h3 className="font-poppins text-xl font-semibold">Share Wishes</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">
                Create beautiful wishlists and share them with friends and family in seconds
              </p>
            </div>

            <div className="group space-y-4 text-center">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/5 transition-all group-hover:scale-110 group-hover:bg-primary/10">
                <Users className="h-7 w-7 text-primary" />
              </div>
              <h3 className="font-poppins text-xl font-semibold">Stay Connected</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">
                Follow friends, get notified of their wishes, and never miss a special occasion
              </p>
            </div>

            <div className="group space-y-4 text-center">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/5 transition-all group-hover:scale-110 group-hover:bg-primary/10">
                <Gift className="h-7 w-7 text-primary" />
              </div>
              <h3 className="font-poppins text-xl font-semibold">Reserve Gifts</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">
                Coordinate with others to ensure no one buys the same gift twice
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer CTA Section */}
      <section className="container mx-auto px-4 py-16 md:px-6 md:py-20">
        <div className="mx-auto max-w-3xl space-y-8 text-center">
          <div className="space-y-4">
            <h2 className="font-poppins text-2xl font-semibold md:text-3xl">
              Already have a link?
            </h2>
            <p className="text-base leading-relaxed text-muted-foreground">
              Just open it directly—for example{" "}
              <Link
                href="https://jinnie.co/jinnie"
                className="font-medium text-primary underline-offset-4 transition-colors hover:underline"
              >
                jinnie.co/jinnie
              </Link>{" "}
              takes you to our official profile
            </p>
          </div>

          {/* Footer note */}
          <p className="pt-8 text-xs text-muted-foreground/70">
            © 2025 Jinnie. All rights reserved.
          </p>
        </div>
      </section>
    </main>
  );
}
