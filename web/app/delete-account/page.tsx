"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Loader2, Trash2 } from "lucide-react";

export default function DeleteAccountPage() {
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<"idle" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!username.trim() || !email.trim()) {
      setErrorMessage("Please fill in all fields");
      setSubmitStatus("error");
      return;
    }

    if (!email.includes("@")) {
      setErrorMessage("Please enter a valid email address");
      setSubmitStatus("error");
      return;
    }

    setIsSubmitting(true);
    setSubmitStatus("idle");
    setErrorMessage("");

    try {
      const message = `🗑️ Account Deletion Request

Username: ${username}
Email: ${email}
Source: Web
Timestamp: ${new Date().toISOString()}

Please process this account deletion request according to our data retention policy.`;

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
        throw new Error("Failed to submit request");
      }

      setSubmitStatus("success");
      setUsername("");
      setEmail("");
    } catch (error) {
      console.error("Error submitting deletion request:", error);
      setSubmitStatus("error");
      setErrorMessage("Failed to submit request. Please try again or contact support.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <main className="min-h-screen bg-background flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center space-y-2">
          <div className="mx-auto w-12 h-12 rounded-full bg-destructive/10 flex items-center justify-center mb-2">
            <Trash2 className="h-6 w-6 text-destructive" />
          </div>
          <CardTitle className="text-2xl">Delete Your Account</CardTitle>
          <CardDescription className="text-base">
            Submit a request to permanently delete your Jinnie account and associated data
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Information Section */}
          <div className="bg-muted/50 rounded-lg p-4 space-y-3 text-sm">
            <h3 className="font-semibold">What happens when you delete your account:</h3>
            <ul className="space-y-2 list-disc list-inside text-muted-foreground">
              <li>Your profile and username will be permanently removed</li>
              <li>All your wishlists and wishes will be deleted</li>
              <li>Your reservations on others&apos; wishes will be canceled</li>
              <li>All your account data will be removed from our systems</li>
              <li>This action cannot be undone</li>
            </ul>
            <p className="text-muted-foreground pt-2">
              Account deletion requests are typically processed within 30 days.
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                type="text"
                placeholder="your_username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                disabled={isSubmitting}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email Address</Label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={isSubmitting}
                required
              />
              <p className="text-xs text-muted-foreground">
                Enter the email address associated with your account
              </p>
            </div>

            {submitStatus === "success" && (
              <div className="rounded-lg border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-900">
                <p className="font-semibold mb-1">✓ Request Submitted</p>
                <p>
                  Your account deletion request has been received. We&apos;ll process it within 30 days and send a confirmation to your email.
                </p>
              </div>
            )}

            {submitStatus === "error" && (
              <div className="rounded-lg border border-destructive/20 bg-destructive/10 p-4 text-sm text-destructive">
                <p className="font-semibold mb-1">Error</p>
                <p>{errorMessage}</p>
              </div>
            )}

            <Button
              type="submit"
              disabled={isSubmitting}
              variant="destructive"
              className="w-full"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin mr-2" />
                  Submitting Request...
                </>
              ) : (
                <>
                  <Trash2 className="h-4 w-4 mr-2" />
                  Request Account Deletion
                </>
              )}
            </Button>
          </form>

          {/* Footer */}
          <div className="text-center text-xs text-muted-foreground pt-4 border-t">
            <p>
              If you have questions about account deletion, please contact us at{" "}
              <a href="mailto:support@jinnie.co" className="text-primary hover:underline">
                support@jinnie.co
              </a>
            </p>
          </div>
        </CardContent>
      </Card>
    </main>
  );
}
