import Link from "next/link";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Sparkles, Apple, PlaySquare, Heart, Users, Gift } from "lucide-react";

// Wish images from Jinnie's profile - verified working URLs
const wishImages = [
  "https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=400&auto=format",
  "https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&auto=format",
  "https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400&auto=format",
  "https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=400&auto=format",
  "https://images.unsplash.com/photo-1492707892479-7bc8d5a4ee93?w=400&auto=format",
  "https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400&auto=format",
  "https://images.unsplash.com/photo-1580909612062-f9e9bb933990?w=400&auto=format",
  "https://images.unsplash.com/photo-1583292650898-7d22cd27ca6f?w=400&auto=format",
  "https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400&auto=format",
  "https://images.unsplash.com/photo-1591561954557-26941169b49e?w=400&auto=format",
  "https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=400&auto=format",
  "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=400&auto=format",
  "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400&auto=format",
  "https://images.unsplash.com/photo-1593811167562-9cef47bfc4d7?w=400&auto=format",
  "https://images.unsplash.com/photo-1608181715578-5c7c13f88f15?w=400&auto=format",
  "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400&auto=format",
  "https://images.unsplash.com/photo-1603006905003-be475563bc59?w=400&auto=format",
  "https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=400&auto=format",
  "https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400&auto=format",
  "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400&auto=format",
  "https://images.unsplash.com/photo-1543589077-47d81606c1bf?w=400&auto=format",
  "https://images.unsplash.com/photo-1576919228236-a097c32a5cd4?w=400&auto=format",
  "https://images.unsplash.com/photo-1544552866-82bd464e7f9b?w=400&auto=format",
  "https://images.unsplash.com/photo-1585232350370-ef72a3bd0efd?w=400&auto=format",
  "https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=400&auto=format",
  "https://images.unsplash.com/photo-1602874801006-c2b5f633e0a7?w=400&auto=format",
  "https://images.unsplash.com/photo-1513805959324-96eb66ca8713?w=400&auto=format",
  "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&auto=format",
  "https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=400&auto=format",
  "https://images.unsplash.com/photo-1607081830014-f808b8954a10?w=400&auto=format",
  "https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=400&auto=format",
  "https://images.unsplash.com/photo-1617043786394-f977fa12eddf?w=400&auto=format",
  "https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=400&auto=format",
  "https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?w=400&auto=format",
  "https://images.unsplash.com/photo-1558317374-067fb5f30001?w=400&auto=format",
];

export default function HomePage() {
  return (
    <main className="min-h-screen bg-background">
      {/* Hero Section */}
      <section className="relative overflow-hidden border-b">
        {/* Animated grid background */}
        <div className="absolute inset-0 overflow-hidden opacity-70">
          {/* Row 1 - Moving right */}
          <div className="flex gap-4 py-2 animate-scroll-right">
            {[...wishImages.slice(0, 10), ...wishImages.slice(0, 10)].map((img, i) => (
              <div
                key={`row1-${i}`}
                className="relative h-32 w-32 flex-shrink-0"
                style={{ transform: `rotate(${[2, -3, 1, -2, 3, -1, 2, -3, 1, -2, 3, -1, 2, -3, 1, -2, 3, -1, 2, -3][i % 20]}deg)` }}
              >
                <Image
                  src={img}
                  alt=""
                  fill
                  className="rounded-xl object-cover"
                  sizes="128px"
                />
              </div>
            ))}
          </div>

          {/* Row 2 - Moving left */}
          <div className="flex gap-4 py-2 animate-scroll-left">
            {[...wishImages.slice(10, 20), ...wishImages.slice(10, 20)].map((img, i) => (
              <div
                key={`row2-${i}`}
                className="relative h-32 w-32 flex-shrink-0"
                style={{ transform: `rotate(${[-2, 3, -1, 2, -3, 1, -2, 3, -1, 2, -3, 1, -2, 3, -1, 2, -3, 1, -2, 3][i % 20]}deg)` }}
              >
                <Image
                  src={img}
                  alt=""
                  fill
                  className="rounded-xl object-cover"
                  sizes="128px"
                />
              </div>
            ))}
          </div>

          {/* Row 3 - Moving right */}
          <div className="flex gap-4 py-2 animate-scroll-right-slow">
            {[...wishImages.slice(20, 30), ...wishImages.slice(0, 10)].map((img, i) => (
              <div
                key={`row3-${i}`}
                className="relative h-32 w-32 flex-shrink-0"
                style={{ transform: `rotate(${[3, -2, 2, -1, 3, -3, 1, -2, 2, -1, 3, -3, 1, -2, 2, -1, 3, -3, 1, -2][i % 20]}deg)` }}
              >
                <Image
                  src={img}
                  alt=""
                  fill
                  className="rounded-xl object-cover"
                  sizes="128px"
                />
              </div>
            ))}
          </div>

          {/* Row 4 - Moving left */}
          <div className="flex gap-4 py-2 animate-scroll-left-slow">
            {[...wishImages.slice(5, 15), ...wishImages.slice(5, 15)].map((img, i) => (
              <div
                key={`row4-${i}`}
                className="relative h-32 w-32 flex-shrink-0"
                style={{ transform: `rotate(${[-1, 2, -3, 3, -2, 1, -3, 2, -1, 3, -2, 1, -3, 2, -1, 3, -2, 1, -3, 2][i % 20]}deg)` }}
              >
                <Image
                  src={img}
                  alt=""
                  fill
                  className="rounded-xl object-cover"
                  sizes="128px"
                />
              </div>
            ))}
          </div>

          {/* Row 5 - Moving right */}
          <div className="flex gap-4 py-2 animate-scroll-right">
            {[...wishImages.slice(15, 25), ...wishImages.slice(15, 25)].map((img, i) => (
              <div
                key={`row5-${i}`}
                className="relative h-32 w-32 flex-shrink-0"
                style={{ transform: `rotate(${[1, -2, 3, -3, 2, -1, 3, -2, 1, -3, 2, -1, 3, -2, 1, -3, 2, -1, 3, -2][i % 20]}deg)` }}
              >
                <Image
                  src={img}
                  alt=""
                  fill
                  className="rounded-xl object-cover"
                  sizes="128px"
                />
              </div>
            ))}
          </div>
        </div>

        {/* Gradient overlay to fade images */}
        <div className="absolute inset-0 bg-gradient-to-b from-background/40 via-background/50 to-background/85" />

        <div className="container relative mx-auto flex min-h-[85vh] flex-col items-center justify-center px-4 py-24 text-center md:px-6 md:py-32">
          <div className="mx-auto max-w-4xl space-y-6 md:space-y-10 bg-white/90 backdrop-blur-lg rounded-3xl px-6 py-12 md:px-12 md:py-16 shadow-2xl">
            {/* Badge */}
            <div className="animate-fade-in-up">
              <Badge
                variant="outline"
                style={{ color: '#000', borderColor: 'rgba(0,0,0,0.2)' }}
                className="inline-flex items-center gap-2 bg-white/60 px-4 py-1.5 text-xs font-medium tracking-wide backdrop-blur-sm"
              >
                <Sparkles className="h-3.5 w-3.5" style={{ color: '#000' }} />
                Your Modern Wishlist Platform
              </Badge>
            </div>

            {/* Main Heading */}
            <div className="space-y-4 md:space-y-6 animate-fade-in-up animation-delay-100">
              <h1 className="font-poppins text-4xl sm:text-5xl font-semibold leading-[1.15] tracking-tight md:text-6xl lg:text-7xl px-2" style={{ color: '#000' }}>
                Keep wishlists in sync with the people you{" "}
                <span className="relative inline-block">
                  <span className="relative z-10">care about</span>
                  <span className="absolute -bottom-2 left-0 h-3 w-full -rotate-1" style={{ backgroundColor: 'rgba(0,0,0,0.1)' }} />
                </span>
              </h1>
              <p className="mx-auto max-w-2xl text-base sm:text-lg leading-relaxed md:text-xl px-4" style={{ color: '#374151' }}>
                Create, manage, and share your wishlists effortlessly. Make gift-giving magical with the Jinnie mobile app.
              </p>
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col items-center gap-3 md:gap-4 pt-2 md:pt-4 animate-fade-in-up animation-delay-200 sm:flex-row sm:justify-center">
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
