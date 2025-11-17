'use client';

import { useEffect, useState, type ReactNode } from "react";
import Link from "next/link";
import Image from "next/image";
import { X, ExternalLink, Loader2, Mail, Plus } from "lucide-react";
import {
  onAuthStateChanged,
  sendSignInLinkToEmail,
  type ActionCodeSettings,
  type User as FirebaseUser,
} from "firebase/auth";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, type Wish, type Wishlist } from "@/lib/api";
import {
  getFirebaseAuth,
  RESERVATION_EMAIL_STORAGE_KEY,
  RESERVATION_PENDING_STORAGE_KEY,
  isReservationSessionExpired,
  clearReservationSession,
} from "@/lib/firebase-client";
import { emailPattern } from "@/lib/validators";
import { useAuth } from "@/lib/auth/AuthContext.client";
import { signOut as firebaseSignOut } from "firebase/auth";
import { SignInModal } from "@/components/auth/SignInModal.client";
import { WishSlideOver } from "@/components/wish/WishSlideOver.client";
import { useApiAuth } from "@/lib/hooks/useApiAuth";

function formatPrice(amount?: number, currency: string = "USD") {
  if (amount == null) return null;

  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return `$${amount}`;
  }
}

type FooterRendererContext = {
  close: () => void;
  isReserved: boolean;
  isMine: boolean;
};

type FooterRenderer =
  | ReactNode
  | ((context: FooterRendererContext) => ReactNode);

export interface WishDetailDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  wish: Wish | null;
  onReserve?: () => void;
  onCancel?: () => void;
  isMine?: boolean;
  footer?: FooterRenderer;
  reserveHref?: string;
  reserveLabel?: string;
  shareToken?: string;
}

export function WishDetailDialog({
  open,
  onOpenChange,
  wish,
  onReserve,
  onCancel,
  isMine = false,
  footer,
  reserveHref,
  reserveLabel,
  shareToken,
}: WishDetailDialogProps) {
  const { backendUser } = useAuth();
  const apiAuth = useApiAuth();
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [showReservationForm, setShowReservationForm] = useState(false);
  const [formValues, setFormValues] = useState({ name: "", email: "", message: "" });
  const [formError, setFormError] = useState<string | null>(null);
  const [formNotice, setFormNotice] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [authUser, setAuthUser] = useState<FirebaseUser | null>(null);
  const [authInitialized, setAuthInitialized] = useState(false);
  const [imageError, setImageError] = useState(false);
  const [showSignIn, setShowSignIn] = useState(false);
  const [showAddWish, setShowAddWish] = useState(false);
  const [pendingWishData, setPendingWishData] = useState<{
    title?: string;
    description?: string;
    price?: number;
    currency?: string;
    url?: string;
    images?: string[];
  } | null>(null);
  const [wishlists, setWishlists] = useState<Wishlist[]>([]);

  useEffect(() => {
    setCurrentImageIndex(0);
    setShowReservationForm(false);
    setFormError(null);
    setFormNotice(null);
    setImageError(false);
    setShowSignIn(false);
    setShowAddWish(false);
    setPendingWishData(null);
  }, [wish?.id]);

  // Load wishlists when user is authenticated
  useEffect(() => {
    const loadWishlists = async () => {
      if (backendUser) {
        try {
          const userWishlists = await apiAuth.getMyWishlists();
          setWishlists(userWishlists);
        } catch (error) {
          console.error('Failed to load wishlists:', error);
        }
      }
    };

    loadWishlists();
  }, [backendUser, apiAuth]);

  // Open add wish modal after successful sign-in
  useEffect(() => {
    if (backendUser && pendingWishData && !showSignIn) {
      setShowAddWish(true);
      setPendingWishData(null);
    }
  }, [backendUser, pendingWishData, showSignIn]);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const savedEmail = window.localStorage.getItem(RESERVATION_EMAIL_STORAGE_KEY);
    if (savedEmail) {
      setFormValues((prev) => ({ ...prev, email: savedEmail }));
    }
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") return;

    let unsubscribe: (() => void) | undefined;

    try {
      const auth = getFirebaseAuth();
      unsubscribe = onAuthStateChanged(auth, async (user) => {
        if (user) {
          try {
            await user.reload();
          } catch {
            // Silently handle reload errors
          }
        }

        setAuthUser(user);
        setAuthInitialized(true);
      });
    } catch {
      // Firebase Auth not configured
      setAuthInitialized(true);
    }

    return () => {
      unsubscribe?.();
    };
  }, []);

  const images = wish?.images ?? [];
  const hasValidImages = images.length > 0 && !imageError;
  const price = formatPrice(wish?.price, wish?.currency);
  const isReserved = wish?.status === "reserved";

  // Get user's email from any available source
  const verifiedEmail = authUser?.emailVerified ? authUser.email ?? null : null;
  const userEmail = authUser?.email ??
    (typeof window !== 'undefined' ? window.localStorage.getItem(RESERVATION_EMAIL_STORAGE_KEY) : null);

  // Check if user owns the reservation
  // The backend stores Firebase UID in reservedByUid, so check that first
  // If no UID available, fall back to email comparison with reservedBy
  const userUid = authUser?.uid;
  const isMyReservation = Boolean(
    isReserved &&
    (
      // Check UID match (most reliable)
      (userUid && wish?.reservedByUid && userUid === wish.reservedByUid) ||
      // Fallback: check if reservedBy is an email and matches
      (userEmail && wish?.reservedBy && wish.reservedBy.includes('@') && userEmail.toLowerCase() === wish.reservedBy.toLowerCase())
    )
  );

  if (!wish) return null;

  const handleClose = () => {
    onOpenChange(false);
    setShowReservationForm(false);
  };

  const handleAddToMyWishlist = () => {
    if (!wish) return;

    // Prepare prefilled data from the wish
    const prefilledData = {
      title: wish.title,
      description: wish.description || undefined,
      price: wish.price || undefined,
      currency: wish.currency || 'USD',
      url: wish.url || undefined,
      images: wish.images && wish.images.length > 0 ? wish.images : undefined,
    };

    // If user is logged in, open add wish modal directly
    if (backendUser) {
      setPendingWishData(prefilledData);
      setShowAddWish(true);
    } else {
      // If not logged in, save the data and show sign-in modal
      setPendingWishData(prefilledData);
      setShowSignIn(true);
    }
  };

  const handleStartReservation = () => {
    if (shareToken) {
      setShowReservationForm(true);
    } else if (onReserve) {
      onReserve();
    }
  };

  const handleCancelReservation = async () => {
    if (!wish) return;

    const confirmCancel = window.confirm(
      `Cancel your reservation for "${wish.title}"? This action cannot be undone.`
    );

    if (!confirmCancel) return;

    try {
      setSubmitting(true);
      const auth = getFirebaseAuth();
      const currentUser = auth.currentUser;

      if (!currentUser) {
        alert("Please verify your email to manage reservations.");
        setSubmitting(false);
        return;
      }

      // Check if reservation session has expired
      // ONLY check expiry for reservation-only sessions (not Google/Apple users)
      const hasAuthProvider = currentUser.providerData?.some(
        (p) => p.providerId === 'google.com' || p.providerId === 'apple.com'
      );

      if (!hasAuthProvider && isReservationSessionExpired()) {
        clearReservationSession();
        await firebaseSignOut(auth);
        alert(
          "Your session expired (48 hours). Please verify your email again to cancel this reservation."
        );
        setSubmitting(false);
        return;
      }

      // Get ID token and cancel reservation
      await currentUser.reload();
      const idToken = await currentUser.getIdToken(true);
      await api.cancelReservation(wish.id, idToken);

      handleClose();
      window.location.reload();
    } catch (err: unknown) {
      const axiosError = err as { response?: { status?: number; data?: { error?: { message?: string }; message?: string } } };
      const errorData = axiosError.response?.data;
      const message = errorData?.error?.message || errorData?.message || "Failed to cancel reservation. Please try again.";
      alert(message);
      setSubmitting(false);
    }
  };

  const handleReservationSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!wish || !shareToken) return;

    const trimmedEmail = formValues.email.trim();

    if (!trimmedEmail) {
      setFormError("Please enter your email address.");
      return;
    }

    if (!emailPattern.test(trimmedEmail)) {
      setFormError("That email looks incorrect. Double-check and try again.");
      return;
    }

    let auth;
    try {
      auth = getFirebaseAuth();
    } catch {
      setFormError("Reservations are temporarily unavailable. Please try again later.");
      return;
    }

    setFormError(null);
    setFormNotice(null);

    if (typeof window !== "undefined") {
      window.localStorage.setItem(RESERVATION_EMAIL_STORAGE_KEY, trimmedEmail);
    }

    await auth.currentUser?.reload();
    const currentUser = auth.currentUser;
    const verifiedUser = currentUser && currentUser.emailVerified ? currentUser : null;

    // Detect if user is fully authenticated by checking provider (Google/Apple)
    // Don't rely on backendUser as it may not be loaded yet
    const hasAuthProvider = currentUser?.providerData?.some(
      (p) => p.providerId === 'google.com' || p.providerId === 'apple.com'
    );
    const isFullyAuthenticated = hasAuthProvider || backendUser?.username;

    // Check if this is an expired reservation session
    // ONLY check expiry for reservation-only sessions (not Google/Apple users)
    if (verifiedUser && !hasAuthProvider && isReservationSessionExpired()) {
      clearReservationSession();
      await firebaseSignOut(auth);
      setFormError(
        "Your session expired (48 hours). Please verify your email again to make a reservation."
      );
      return;
    }

    if (!verifiedUser && !isFullyAuthenticated) {
      try {
        setSubmitting(true);
        const actionCodeSettings: ActionCodeSettings = {
          url: `${window.location.origin}/verify-reservation?redirect=${encodeURIComponent(window.location.pathname + window.location.search)}`,
          handleCodeInApp: true,
        };

        await sendSignInLinkToEmail(auth, trimmedEmail, actionCodeSettings);

        if (typeof window !== "undefined") {
          const payload = {
            shareToken,
            wishId: wish.id,
            email: trimmedEmail,
          };
          window.localStorage.setItem(
            RESERVATION_PENDING_STORAGE_KEY,
            JSON.stringify(payload),
          );
        }

        setFormNotice("Check your email for a link to confirm your reservation.");
      } catch {
        setFormError("We couldn't send the confirmation link. Please double-check your email and try again.");
      } finally {
        setSubmitting(false);
      }
      return;
    }

    try {
      setSubmitting(true);

      // Get ID token from current user (works for both fully auth and verified email)
      if (!currentUser) {
        throw new Error("No authenticated user");
      }
      const idToken = await currentUser.getIdToken(true);

      await api.reserveWish(wish.id, {
        email: trimmedEmail,
        idToken,
      });

      if (typeof window !== "undefined") {
        window.localStorage.removeItem(RESERVATION_PENDING_STORAGE_KEY);
      }

      setFormNotice(`Reserved "${wish.title}". Your reservation is confirmed.`);
      setTimeout(() => {
        handleClose();
        window.location.reload();
      }, 1500);
    } catch (err: unknown) {
      const axiosError = err as { response?: { status?: number; data?: { error?: { message?: string } } } };
      const message =
        axiosError.response?.data?.error?.message ??
        (axiosError.response?.status === 409
          ? "Someone just reserved this wish. Pick another item."
          : "Something went wrong while reserving. Try again.");
      setFormError(message);
    } finally {
      setSubmitting(false);
    }
  };

  const renderFooter = () => {
    if (footer) {
      return typeof footer === "function"
        ? footer({ close: handleClose, isReserved, isMine })
        : footer;
    }

    if (isReserved) {
      const showCancelButton = (isMine && onCancel) || isMyReservation;

      return (
        <div className="flex flex-col gap-2">
          <div className="flex flex-col sm:flex-row gap-2 sm:gap-3">
            {showCancelButton && (
              <Button
                variant="outline"
                onClick={isMyReservation ? handleCancelReservation : onCancel}
                disabled={submitting}
                className="flex-1 h-11 sm:h-12 text-base font-medium"
              >
                {submitting ? "Canceling..." : "Cancel reservation"}
              </Button>
            )}
            {wish.url && (
              <Button
                asChild
                variant="outline"
                className="flex-1 h-11 sm:h-12 text-base font-medium gap-2"
              >
                <a href={wish.url} target="_blank" rel="noopener noreferrer">
                  <ExternalLink className="h-4 w-4" />
                  View details
                </a>
              </Button>
            )}
          </div>
          <Button
            onClick={handleAddToMyWishlist}
            variant="outline"
            className="w-full h-11 sm:h-12 text-base font-medium gap-2"
          >
            <Plus className="h-4 w-4" />
            Add to my wishlist
          </Button>
        </div>
      );
    }

    const canReserve = !isReserved && (onReserve != null || reserveHref || shareToken);

    return (
      <div className="flex flex-col gap-2">
        <div className="flex flex-col-reverse sm:flex-row gap-2 sm:gap-3">
          {wish.url && (
            <Button
              asChild
              variant="outline"
              className="flex-1 h-11 sm:h-12 text-base font-medium gap-2"
            >
              <a href={wish.url} target="_blank" rel="noopener noreferrer">
                <ExternalLink className="h-4 w-4" />
                View details
              </a>
            </Button>
          )}
          {canReserve && (
            onReserve ? (
              <Button
                onClick={onReserve}
                className="flex-1 h-11 sm:h-12 text-base font-medium"
              >
                {reserveLabel ?? "Reserve"}
              </Button>
            ) : reserveHref ? (
              <Button
                asChild
                className="flex-1 h-11 sm:h-12 text-base font-medium"
              >
                <Link href={reserveHref}>{reserveLabel ?? "Reserve"}</Link>
              </Button>
            ) : shareToken ? (
              <Button
                onClick={handleStartReservation}
                className="flex-1 h-11 sm:h-12 text-base font-medium"
              >
                Reserve
              </Button>
            ) : null
          )}
        </div>
        <Button
          onClick={handleAddToMyWishlist}
          variant="outline"
          className="w-full h-11 sm:h-12 text-base font-medium gap-2"
        >
          <Plus className="h-4 w-4" />
          Add to my wishlist
        </Button>
      </div>
    );
  };

  // If showing reservation form, render that instead
  if (showReservationForm) {
    return (
      <Dialog open={open} onOpenChange={handleClose}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader className="text-center">
            <DialogTitle className="text-center">Reserve &quot;{wish.title}&quot;</DialogTitle>
            <DialogDescription className="text-center">
              You can manage your reservations using the link we&apos;ll send you.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleReservationSubmit} className="space-y-4 px-6">
            {backendUser?.username && verifiedEmail ? (
              <div className="rounded-md border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm text-emerald-900 text-center">
                Signed in as <span className="font-semibold">{verifiedEmail}</span>
              </div>
            ) : null}

            <div className="grid gap-4">
              <div className="grid gap-2">
                <Label htmlFor="reserve-email" className="inline-flex items-center gap-2">
                  <Mail className="h-4 w-4 text-muted-foreground" />
                  Email address
                </Label>
                <Input
                  id="reserve-email"
                  type="email"
                  required
                  value={formValues.email}
                  onChange={(e) => setFormValues((prev) => ({ ...prev, email: e.target.value }))}
                  autoComplete="email"
                  placeholder="you@example.com"
                />
              </div>
            </div>

            {formError ? (
              <p className="text-sm font-medium text-destructive text-center">{formError}</p>
            ) : null}

            {formNotice ? (
              <p className="rounded-md border border-primary/30 bg-primary/10 px-4 py-2 text-sm text-primary text-center">
                {formNotice}
              </p>
            ) : null}

            <DialogFooter className="gap-2 sm:gap-0">
              <Button
                type="button"
                variant="outline"
                onClick={() => setShowReservationForm(false)}
                disabled={submitting}
                className="flex-1"
              >
                Cancel
              </Button>
              <Button type="submit" disabled={submitting || !authInitialized} className="flex-1">
                {submitting ? (
                  <span className="inline-flex items-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Reserving…
                  </span>
                ) : (
                  "Reserve wish"
                )}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        className="max-h-[90vh] p-0 overflow-hidden"
        containerClassName="max-w-3xl overflow-hidden rounded-3xl border border-border/60 bg-card shadow-2xl flex flex-col"
        hideClose
        aria-describedby="wish-description"
      >
        <DialogTitle className="sr-only">{wish.title}</DialogTitle>
        <DialogDescription id="wish-description" className="sr-only">
          {wish.description || `View details for ${wish.title}`}
        </DialogDescription>

        {/* Close Button - Top Right */}
        <button
          onClick={handleClose}
          className="absolute top-4 right-4 z-50 rounded-full bg-black/60 p-2 text-white backdrop-blur-sm transition-colors hover:bg-black/80 focus:outline-none focus:ring-2 focus:ring-white/50"
          aria-label="Close"
        >
          <X className="h-5 w-5" />
        </button>

        {/* Image Gallery Section */}
        {hasValidImages ? (
          <div className="relative w-full bg-muted max-h-[50vh]" style={{ aspectRatio: "4/3" }}>
            <Image
              src={images[currentImageIndex]}
              alt={wish.title}
              fill
              className="object-cover"
              sizes="(min-width: 768px) 50vw, 100vw"
              priority
              onError={() => setImageError(true)}
            />
            {isReserved && (
              <div className="absolute top-4 left-4">
                <Badge variant="secondary" className="bg-black/80 text-white border-0 backdrop-blur-sm px-3 py-1.5 text-xs sm:text-sm">
                  {isMine ? "Reserved by you" : "Reserved"}
                </Badge>
              </div>
            )}

            {images.length > 1 && (
              <div className="absolute bottom-4 left-4">
                <Badge variant="secondary" className="bg-black/80 text-white border-0 backdrop-blur-sm px-2 py-1 text-xs">
                  {currentImageIndex + 1} / {images.length}
                </Badge>
              </div>
            )}
          </div>
        ) : null}

        {hasValidImages && images.length > 1 && (
          <div className="flex gap-2 overflow-x-auto px-4 py-3 border-b bg-background scrollbar-thin">
            {images.map((img, idx) => (
              <button
                key={idx}
                onClick={() => setCurrentImageIndex(idx)}
                className={`relative flex-shrink-0 w-16 h-16 sm:w-20 sm:h-20 rounded-lg overflow-hidden border-2 transition-all ${
                  idx === currentImageIndex
                    ? "border-primary ring-2 ring-primary/20"
                    : "border-border/40 hover:border-border"
                }`}
              >
                <Image
                  src={img}
                  alt={`${wish.title} - Image ${idx + 1}`}
                  fill
                  className="object-cover"
                  sizes="80px"
                />
              </button>
            ))}
          </div>
        )}

        <div className="flex-1 overflow-y-auto">
          <div className="p-4 sm:p-6 space-y-4">
            <div className="space-y-2">
              <div className="flex items-start justify-between gap-3">
                <h2 className="text-xl sm:text-2xl font-semibold leading-tight flex-1">{wish.title}</h2>
                {isReserved && !hasValidImages && (
                  <Badge variant="secondary" className="bg-black/70 text-white border-0 px-3 py-1.5 text-xs sm:text-sm flex-shrink-0">
                    {isMine ? "Reserved by you" : "Reserved"}
                  </Badge>
                )}
              </div>
              {price && (
                <div className="text-2xl sm:text-3xl font-bold text-primary">{price}</div>
              )}
            </div>

            {wish.description && (
              <div className="space-y-1.5">
                <h3 className="font-semibold text-sm text-muted-foreground uppercase tracking-wide">
                  Description
                </h3>
                <p className="text-foreground leading-relaxed text-sm sm:text-base">
                  {wish.description}
                </p>
              </div>
            )}
          </div>
        </div>

        <div className="border-t bg-background p-4 sm:p-6">
          {renderFooter()}
        </div>
      </DialogContent>

      {/* Sign In Modal */}
      <SignInModal
        open={showSignIn}
        onOpenChange={setShowSignIn}
      />

      {/* Add Wish Modal */}
      {showAddWish && (
        <WishSlideOver
          open={showAddWish}
          onClose={() => setShowAddWish(false)}
          onSuccess={() => {
            setShowAddWish(false);
            handleClose();
            window.location.reload();
          }}
          wishlists={wishlists}
          prefilledData={pendingWishData || undefined}
        />
      )}
    </Dialog>
  );
}
