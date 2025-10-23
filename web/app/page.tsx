"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sparkles, Apple, PlaySquare, Heart, Users, Gift, Loader2 } from "lucide-react";

// Wish images - stored locally for reliability
const wishImages = [
  "/landing/wish-01.jpg",
  "/landing/wish-02.jpg",
  "/landing/wish-03.jpg",
  "/landing/wish-04.jpg",
  "/landing/wish-05.jpg",
  "/landing/wish-06.jpg",
  "/landing/wish-08.jpg",
  "/landing/wish-09.jpg",
  "/landing/wish-10.jpg",
  "/landing/wish-11.jpg",
  "/landing/wish-12.jpg",
  "/landing/wish-13.jpg",
  "/landing/wish-14.jpg",
  "/landing/wish-16.jpg",
  "/landing/wish-17.jpg",
  "/landing/wish-18.jpg",
  "/landing/wish-19.jpg",
  "/landing/wish-20.jpg",
  "/landing/wish-21.jpg",
  "/landing/wish-22.jpg",
  "/landing/wish-25.jpg",
  "/landing/wish-27.jpg",
  "/landing/wish-28.jpg",
  "/landing/wish-29.jpg",
  "/landing/wish-31.jpg",
  "/landing/wish-32.jpg",
  "/landing/wish-33.jpg",
  "/landing/wish-34.jpg",
  "/landing/wish-35.jpg",
];

export default function HomePage() {
  const [email, setEmail] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<"idle" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const handleWaitlistSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email || !email.includes("@")) {
      setErrorMessage("Please enter a valid email address");
      setSubmitStatus("error");
      return;
    }

    setIsSubmitting(true);
    setSubmitStatus("idle");
    setErrorMessage("");

    try {
      const message = `🎉 New Waitlist Signup!\n\nEmail: ${email}\nSource: Landing Page\nTimestamp: ${new Date().toISOString()}`;

      const response = await fetch("https://openai-rewrite.onrender.com/telegram/send-message", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message,
          channel: "general",
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to submit");
      }

      setSubmitStatus("success");
      setEmail("");
    } catch (error) {
      console.error("Error submitting to waitlist:", error);
      setSubmitStatus("error");
      setErrorMessage("Something went wrong. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

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

            {/* CTA Buttons - Disabled with Coming Soon */}
            <div className="flex flex-col items-center gap-3 md:gap-4 pt-2 md:pt-4 animate-fade-in-up animation-delay-200">
              <div className="flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
                <Button
                  disabled
                  size="lg"
                  className="h-12 gap-2 px-8 text-base font-medium opacity-50 cursor-not-allowed relative"
                >
                  <Apple className="h-5 w-5" />
                  Download on App Store
                  <Badge className="absolute -top-2 -right-2 text-[10px] bg-primary text-primary-foreground">Coming Soon</Badge>
                </Button>
                <Button
                  disabled
                  size="lg"
                  variant="outline"
                  className="h-12 gap-2 px-8 text-base font-medium opacity-50 cursor-not-allowed relative"
                >
                  <PlaySquare className="h-5 w-5" />
                  Get it on Google Play
                  <Badge className="absolute -top-2 -right-2 text-[10px] bg-primary text-primary-foreground">Coming Soon</Badge>
                </Button>
              </div>

              {/* Waitlist Form */}
              <div className="w-full max-w-md pt-6 space-y-3">
                <p className="text-sm font-medium text-foreground">Join the waitlist to be notified when we launch:</p>
                <form onSubmit={handleWaitlistSubmit} className="flex flex-col gap-2 sm:flex-row">
                  <Input
                    type="email"
                    placeholder="Enter your email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={isSubmitting}
                    className="flex-1 h-11"
                    required
                  />
                  <Button
                    type="submit"
                    disabled={isSubmitting}
                    className="h-11 px-6"
                  >
                    {isSubmitting ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin mr-2" />
                        Joining...
                      </>
                    ) : (
                      "Join Waitlist"
                    )}
                  </Button>
                </form>
                {submitStatus === "success" && (
                  <p className="text-sm text-emerald-600 font-medium">
                    ✓ Thanks! We'll notify you when we launch.
                  </p>
                )}
                {submitStatus === "error" && (
                  <p className="text-sm text-destructive font-medium">
                    {errorMessage || "Something went wrong. Please try again."}
                  </p>
                )}
              </div>
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
