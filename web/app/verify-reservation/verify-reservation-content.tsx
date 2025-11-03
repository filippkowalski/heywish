'use client';

import { useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { isSignInWithEmailLink, signInWithEmailLink, type Auth } from "firebase/auth";
import { Loader2, MailCheck, AlertTriangle } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  getFirebaseAuth,
  RESERVATION_EMAIL_STORAGE_KEY,
  setReservationSession,
} from "@/lib/firebase-client";
import { emailPattern } from "@/lib/validators";

export default function VerifyReservationContent() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [authInstance, setAuthInstance] = useState<Auth | null>(null);
  const [status, setStatus] = useState<"checking" | "prompt" | "success" | "error">("checking");
  const [email, setEmail] = useState("");
  const [error, setError] = useState<string | null>(null);

  const completeSignIn = useCallback(
    async (auth: Auth, emailForLink: string) => {
      try {
        await signInWithEmailLink(auth, emailForLink, window.location.href);
        window.localStorage.setItem(RESERVATION_EMAIL_STORAGE_KEY, emailForLink);

        // Store reservation session with 48-hour expiry
        setReservationSession(emailForLink);

        setStatus("success");
        setError(null);

        const redirectParam = searchParams.get("redirect");
        const target = redirectParam ? decodeURIComponent(redirectParam) : "/";

        setTimeout(() => {
          router.replace(target);
        }, 1200);
      } catch (err) {
        console.error("Error completing email sign-in:", err);
        setStatus("prompt");
        setError("We couldn't verify that email. Please try again.");
      }
    },
    [router, searchParams],
  );

  useEffect(() => {
    if (typeof window === "undefined") return;

    let auth: Auth;
    try {
      auth = getFirebaseAuth();
      setAuthInstance(auth);
    } catch (authError) {
      console.error("Firebase Auth is not configured:", authError);
      setStatus("error");
      setError("Magic links are not available right now. Please try again later.");
      return;
    }

    if (!isSignInWithEmailLink(auth, window.location.href)) {
      setStatus("error");
      setError("This verification link is invalid or has expired.");
      return;
    }

    const storedEmail = window.localStorage.getItem(RESERVATION_EMAIL_STORAGE_KEY);
    if (storedEmail) {
      setEmail(storedEmail);
      completeSignIn(auth, storedEmail);
    } else {
      setStatus("prompt");
    }
  }, [completeSignIn]);

  const handleEmailSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!authInstance) return;

    const trimmedEmail = email.trim();
    if (!emailPattern.test(trimmedEmail)) {
      setError("Enter the same email you used when requesting the reservation.");
      return;
    }

    setError(null);
    setStatus("checking");
    await completeSignIn(authInstance, trimmedEmail);
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-2">
          <CardTitle>Email confirmation</CardTitle>
          <CardDescription>
            We use a one-time magic link to confirm reservations. Finish the verification below.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {status === "checking" ? (
            <div className="flex flex-col items-center gap-3 text-sm text-muted-foreground">
              <Loader2 className="h-6 w-6 animate-spin text-primary" />
              <p>Confirming your email…</p>
            </div>
          ) : null}

          {status === "prompt" ? (
            <form onSubmit={handleEmailSubmit} className="space-y-4">
              <div className="space-y-1 text-sm text-muted-foreground">
                <p>Enter the email address where you received the magic link.</p>
                <p>We&apos;ll use it to complete the reservation.</p>
              </div>
              <Input
                type="email"
                inputMode="email"
                autoComplete="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="you@example.com"
                required
              />
              {error ? <p className="text-sm font-medium text-destructive">{error}</p> : null}
              <Button type="submit" className="w-full">
                Verify email
              </Button>
            </form>
          ) : null}

          {status === "success" ? (
            <div className="flex flex-col items-center gap-3 text-center text-sm text-muted-foreground">
              <MailCheck className="h-10 w-10 text-emerald-500" />
              <div>
                <p className="font-medium text-foreground">Email confirmed!</p>
                <p>Redirecting you back to the wishlist…</p>
              </div>
            </div>
          ) : null}

          {status === "error" ? (
            <div className="space-y-4 text-sm text-muted-foreground">
              <div className="flex items-start gap-3">
                <AlertTriangle className="mt-0.5 h-5 w-5 text-destructive" />
                <span>{error ?? "This link is no longer valid."}</span>
              </div>
              <Button
                type="button"
                variant="outline"
                className="w-full"
                onClick={() => router.replace("/")}
              >
                Go back home
              </Button>
            </div>
          ) : null}
        </CardContent>
      </Card>
    </main>
  );
}
