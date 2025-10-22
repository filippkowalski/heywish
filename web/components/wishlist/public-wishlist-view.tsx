'use client';

import Image from "next/image";
import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type Dispatch,
  type SetStateAction,
} from "react";
import {
  BookmarkCheck,
  Gift,
  Loader2,
  Mail,
  ShieldAlert,
  User,
} from "lucide-react";
import {
  onAuthStateChanged,
  sendSignInLinkToEmail,
  type ActionCodeSettings,
  type User as FirebaseUser,
} from "firebase/auth";
import { api, type Wish, type Wishlist } from "@/lib/api";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
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
import { Textarea } from "@/components/ui/textarea";
import { ShareButton } from "@/components/profile/share-button";
import {
  getFirebaseAuth,
  RESERVATION_EMAIL_STORAGE_KEY,
  RESERVATION_PENDING_STORAGE_KEY,
} from "@/lib/firebase-client";
import { emailPattern } from "@/lib/validators";
import { buildWishlistPath, getWishlistSlug } from "@/lib/slug";

export type PublicWishlistViewProps = {
  shareToken: string;
  sharePath?: string;
};

type ReservationForm = {
  name: string;
  email: string;
  message: string;
};

type PendingReservationPayload = {
  shareToken: string;
  wishId: string;
  email: string;
};

export function PublicWishlistView({ shareToken, sharePath }: PublicWishlistViewProps) {
  const token = shareToken;

  const [wishlist, setWishlist] = useState<Wishlist | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [banner, setBanner] = useState<string | null>(null);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailDialogOpen, setDetailDialogOpen] = useState(false);
  const [activeWish, setActiveWish] = useState<Wish | null>(null);
  const [formValues, setFormValues] = useState<ReservationForm>({
    name: "",
    email: "",
    message: "",
  });
  const [formError, setFormError] = useState<string | null>(null);
  const [formNotice, setFormNotice] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [authUser, setAuthUser] = useState<FirebaseUser | null>(null);
  const [authInitialized, setAuthInitialized] = useState(false);
  const [cancellingIds, setCancellingIds] = useState<Set<string>>(new Set());

  const deriveSlug = (target?: Wishlist | null) => {
    if (!target) {
      return undefined;
    }

    const rawShareToken = (target as unknown as { share_token?: string }).share_token;
    return (
      target.slug
      ?? getWishlistSlug({
        slug: target.slug,
        name: target.name,
        shareToken: target.shareToken ?? rawShareToken,
        id: target.id,
      })
    );
  };

  const setCancellingState = (wishId: string, active: boolean) => {
    setCancellingIds((prev) => {
      const next = new Set(prev);
      if (active) {
        next.add(wishId);
      } else {
        next.delete(wishId);
      }
      return next;
    });
  };

  useEffect(() => {
    let isMounted = true;

    const fetchWishlist = async () => {
      try {
        setLoading(true);
        const response = await api.getPublicWishlist(token);
        if (!isMounted) return;
        setWishlist(response.wishlist);
        setError(null);
      } catch (err: unknown) {
        console.error("Error fetching wishlist:", err);
        const axiosError = err as { response?: { status?: number } };
        if (axiosError.response?.status === 404) {
          setError("This wishlist could not be found.");
        } else if (axiosError.response?.status === 403) {
          setError("This wishlist is private.");
        } else {
          setError("We could not load this wishlist. Please try again later.");
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    if (token) {
      fetchWishlist();
    } else {
      setError("Wishlist code missing.");
      setLoading(false);
    }

    return () => {
      isMounted = false;
    };
  }, [token]);

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
          } catch (reloadError) {
            console.warn("Failed to reload Firebase user", reloadError);
          }
        }

        setAuthUser(user);
        setAuthInitialized(true);
      });
    } catch (authError) {
      console.error("Firebase Auth is not configured:", authError);
      setAuthInitialized(true);
    }

    return () => {
      unsubscribe?.();
    };
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") return;
    if (!authUser?.emailVerified) return;

    const rawPayload = window.localStorage.getItem(RESERVATION_PENDING_STORAGE_KEY);
    if (!rawPayload) return;

    try {
      const payload = JSON.parse(rawPayload) as PendingReservationPayload;
      if (payload.shareToken === token) {
        setBanner("Email verified. Reserve the item again to finish the hold.");
      }
    } catch (parseError) {
      console.warn("Failed to parse pending reservation payload", parseError);
    } finally {
      window.localStorage.removeItem(RESERVATION_PENDING_STORAGE_KEY);
    }
  }, [authUser, token]);

  const handleDialogChange = useCallback((isOpen: boolean) => {
    setDialogOpen(isOpen);
    if (!isOpen) {
      setActiveWish(null);
      setFormError(null);
      setFormNotice(null);
      setFormValues((prev) => ({ ...prev, message: "" }));
    }
  }, []);

  const startReservation = (wish: Wish) => {
    setActiveWish(wish);
    setFormError(null);
    setFormValues((prev) => ({ ...prev, message: "" }));
    setDialogOpen(true);
  };

  const handleReservationSubmit = async () => {
    if (!activeWish) return;

    const trimmedEmail = formValues.email.trim();
    const trimmedName = formValues.name.trim();
    const trimmedMessage = formValues.message.trim();

    if (!trimmedEmail) {
      setFormError("Enter your email so the wishlist owner knows who reserved.");
      return;
    }

    if (!emailPattern.test(trimmedEmail)) {
      setFormError("That email looks incorrect. Double-check and try again.");
      return;
    }

    let auth;
    try {
      auth = getFirebaseAuth();
    } catch (authError) {
      console.error("Firebase Auth is unavailable:", authError);
      setFormError("Reservations are temporarily unavailable. Please try again later.");
      return;
    }

    setFormError(null);
    setFormNotice(null);

    if (typeof window !== "undefined") {
      window.localStorage.setItem(RESERVATION_EMAIL_STORAGE_KEY, trimmedEmail);
    }

    await auth.currentUser?.reload();
    const verifiedUser = auth.currentUser && auth.currentUser.emailVerified ? auth.currentUser : null;

    if (!verifiedUser) {
      try {
        setSubmitting(true);
        const slugForShare = deriveSlug(wishlist);
        const redirectTarget = sharePath ?? (wishlist?.username && slugForShare
          ? buildWishlistPath(wishlist.username, slugForShare)
          : `${window.location.pathname}${window.location.search}`);
        const actionCodeSettings: ActionCodeSettings = {
          url: `${window.location.origin}/verify-reservation?redirect=${encodeURIComponent(
            redirectTarget,
          )}`,
          handleCodeInApp: true,
        };

        await sendSignInLinkToEmail(auth, trimmedEmail, actionCodeSettings);

        if (typeof window !== "undefined") {
          const payload: PendingReservationPayload = {
            shareToken: token,
            wishId: activeWish.id,
            email: trimmedEmail,
          };
          window.localStorage.setItem(
            RESERVATION_PENDING_STORAGE_KEY,
            JSON.stringify(payload),
          );
        }

        setFormNotice("Check your email for a link to confirm your reservation.");
      } catch (err: unknown) {
        console.error("Error sending reservation verification link:", err);
        setFormError("We couldn't send the confirmation link. Please double-check your email and try again.");
      } finally {
        setSubmitting(false);
      }
      return;
    }

    try {
      setSubmitting(true);
      const idToken = await verifiedUser.getIdToken(true);
      const currentUserUid = verifiedUser.uid;

      await api.reserveWish(activeWish.id, {
        email: trimmedEmail,
        name: trimmedName || undefined,
        message: trimmedMessage || undefined,
        idToken,
      });

      if (typeof window !== "undefined") {
        window.localStorage.removeItem(RESERVATION_PENDING_STORAGE_KEY);
      }

      setWishlist((prev) => {
        if (!prev) return prev;

        const alreadyReserved =
          (prev.wishes ?? prev.items ?? []).some(
            (wish) => wish.id === activeWish.id && wish.status === "reserved"
          );

        const applyReservation = (wish: Wish) =>
          wish.id === activeWish.id
            ? {
                ...wish,
                status: "reserved" as const,
                reservedBy: trimmedEmail,
                reservedByUid: currentUserUid,
                reservedMessage: trimmedMessage || undefined,
                reserverName: trimmedName || undefined,
                reservedAt: new Date().toISOString(),
              }
            : wish;

        return {
          ...prev,
          reservedCount: alreadyReserved ? prev.reservedCount : (prev.reservedCount ?? 0) + 1,
          wishes: prev.wishes ? prev.wishes.map(applyReservation) : undefined,
          items: prev.items ? prev.items.map(applyReservation) : undefined,
        };
      });

      setBanner(`Reserved "${activeWish.title}". Your reservation is confirmed.`);
      handleDialogChange(false);
  } catch (err: unknown) {
    console.error("Error reserving wish:", err);
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

  const handleCancelReservation = async (wish: Wish) => {
    try {
      const auth = getFirebaseAuth();
      const current = auth.currentUser;

      if (!current) {
        setFormError("Open the confirmation link from your email to manage your reservations.");
        return;
      }

      await current.reload();
      const idToken = await current.getIdToken(true);

      setFormError(null);
      setFormNotice(null);
      setCancellingState(wish.id, true);

      await api.cancelReservation(wish.id, idToken);

      setWishlist((prev) => {
        if (!prev) return prev;
        const clearReservation = (entry: Wish) =>
          entry.id === wish.id
            ? {
                ...entry,
                status: "available" as const,
                reservedBy: undefined,
                reservedByUid: undefined,
                reservedAt: undefined,
                reservedMessage: undefined,
                reserverName: undefined,
              }
            : entry;

        return {
          ...prev,
          reservedCount: Math.max((prev.reservedCount ?? 1) - 1, 0),
          wishes: prev.wishes ? prev.wishes.map(clearReservation) : undefined,
          items: prev.items ? prev.items.map(clearReservation) : undefined,
        };
      });

      setBanner(`Cancelled reservation for "${wish.title}".`);

      // Refresh the page to ensure UI reflects the cancellation
      setTimeout(() => {
        window.location.reload();
      }, 500);
    } catch (err: unknown) {
      console.error("Error cancelling reservation:", err);
      setFormError("We couldn't cancel that reservation. Please try again.");
    } finally {
      setCancellingState(wish.id, false);
    }
  };

  const resetBanner = () => setBanner(null);

  const allWishes = useMemo(
    () => wishlist?.wishes ?? wishlist?.items ?? [],
    [wishlist]
  );

  const displayWishes = useMemo(() =>
    allWishes.filter((wish) => wish.status !== "purchased"),
    [allWishes]
  );

  const verifiedEmail = authUser?.emailVerified ? authUser.email ?? null : null;
  const viewerUid = authUser?.uid ?? null;

  if (loading) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-3 bg-background text-muted-foreground">
        <Loader2 className="h-8 w-8 animate-spin" />
        <p>Loading wishlist…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background px-4">
        <Card className="max-w-md border-destructive/40 bg-destructive/5 p-8 text-center">
          <ShieldAlert className="mx-auto mb-4 h-10 w-10 text-destructive" />
          <h1 className="text-xl font-semibold text-destructive">Oops!</h1>
          <p className="mt-2 text-sm text-muted-foreground">{error}</p>
        </Card>
      </div>
    );
  }

  if (!wishlist) {
    return null;
  }

  const resolvedSlug = deriveSlug(wishlist) ?? "wishlist";

  const computedSharePath = sharePath ?? (
    wishlist.username ? buildWishlistPath(wishlist.username, resolvedSlug) : `/w/${token}`
  );

  const ownerDisplayName = (wishlist.fullName ?? "").trim()
    || wishlist.username
    || "Jinnie user";

  const ownerInitials = ownerDisplayName
    .split(" ")
    .map((part) => part.charAt(0))
    .join("")
    .slice(0, 2)
    .toUpperCase();

  const totalItems = allWishes.length || wishlist.wishCount;

  return (
    <main className="min-h-screen bg-background">
      <header className="border-b bg-card/60">
        <div className="container mx-auto flex flex-col gap-6 px-4 py-10 md:flex-row md:items-center md:justify-between md:px-6">
          <div className="flex items-start gap-4">
            <Avatar className="h-16 w-16 border border-border text-lg">
              <AvatarFallback>{ownerInitials}</AvatarFallback>
            </Avatar>
            <div className="space-y-3">
              <div className="flex flex-wrap items-center gap-3">
                <h1 className="text-2xl font-semibold md:text-3xl">{wishlist.name}</h1>
                <Badge variant="secondary" className="text-xs uppercase">
                  Public wishlist
                </Badge>
              </div>
              <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                <span className="font-medium text-foreground">{ownerDisplayName}</span>
                {wishlist.username ? <span>@{wishlist.username}</span> : null}
              </div>
              {wishlist.description ? (
                <p className="text-sm text-muted-foreground md:max-w-xl">{wishlist.description}</p>
              ) : null}
              <div className="flex flex-wrap gap-4 text-xs text-muted-foreground">
                <span className="inline-flex items-center gap-1">
                  <Gift className="h-4 w-4 text-primary" />
                  {totalItems} items
                </span>
                <span className="inline-flex items-center gap-1">
                  <BookmarkCheck className="h-4 w-4 text-emerald-500" />
                  {wishlist.reservedCount ?? 0} reserved
                </span>
                {wishlist.updatedAt ? (
                  <span>
                    Updated{" "}
                    {new Intl.DateTimeFormat("en", {
                      month: "short",
                      day: "numeric",
                    }).format(new Date(wishlist.updatedAt))}
                  </span>
                ) : null}
              </div>
            </div>
          </div>

          <ShareButton
            path={computedSharePath}
            label="Share wishlist"
            title={`${wishlist.name} · ${ownerDisplayName} · Jinnie`}
            text={`Check out ${ownerDisplayName}'s ${wishlist.name} wishlist on Jinnie.`}
            className="self-start"
          />
        </div>
      </header>

      <section className="container mx-auto px-4 py-10 md:px-6">
        {banner ? (
          <button
            onClick={resetBanner}
            className="mb-6 flex w-full items-start justify-between rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-left text-sm text-emerald-900 hover:bg-emerald-100 md:items-center"
          >
            <span>{banner}</span>
            <span className="text-xs uppercase tracking-wide">Dismiss</span>
          </button>
        ) : null}

        {displayWishes.length === 0 ? (
          <Card className="bg-muted/40">
            <CardContent className="flex flex-col items-center gap-3 p-10 text-center">
              <Gift className="h-10 w-10 text-muted-foreground" />
              <div>
                <h2 className="text-lg font-semibold">No wishes yet</h2>
                <p className="text-sm text-muted-foreground">
                  This wishlist is empty. Check back soon!
                </p>
              </div>
            </CardContent>
          </Card>
        ) : (
          <div className="columns-1 gap-4 space-y-4 sm:columns-2 lg:columns-3 xl:columns-4">
            {displayWishes.map((wish) => (
              <WishCard
                key={wish.id}
                wish={wish}
                onClick={() => {
                  setActiveWish(wish);
                  setDetailDialogOpen(true);
                }}
                onReserve={() => startReservation(wish)}
                onCancel={viewerUid != null && wish.reservedByUid === viewerUid ? () => handleCancelReservation(wish) : undefined}
                reserving={submitting && activeWish?.id === wish.id}
                cancelling={cancellingIds.has(wish.id)}
                isMine={viewerUid != null && wish.reservedByUid === viewerUid}
              />
            ))}
          </div>
        )}
      </section>

      <ReservationDialog
        open={dialogOpen}
        onOpenChange={handleDialogChange}
        wish={activeWish}
        values={formValues}
        onChange={setFormValues}
        onSubmit={handleReservationSubmit}
        submitting={submitting}
        error={formError}
        notice={formNotice}
        verifiedEmail={verifiedEmail}
        authReady={authInitialized}
      />

      <WishDetailDialog
        open={detailDialogOpen}
        onOpenChange={setDetailDialogOpen}
        wish={activeWish}
        onReserve={() => {
          setDetailDialogOpen(false);
          startReservation(activeWish!);
        }}
        onCancel={viewerUid != null && activeWish?.reservedByUid === viewerUid ? () => {
          setDetailDialogOpen(false);
          handleCancelReservation(activeWish!);
        } : undefined}
        isMine={viewerUid != null && activeWish?.reservedByUid === viewerUid}
      />
    </main>
  );
}

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

function WishCard({
  wish,
  onClick,
  onReserve,
  onCancel,
  reserving,
  cancelling,
  isMine,
}: {
  wish: Wish;
  onClick: () => void;
  onReserve: () => void;
  onCancel?: () => void;
  reserving: boolean;
  cancelling?: boolean;
  isMine?: boolean;
}) {
  const coverImage = wish.images?.[0];
  const price = formatPrice(wish.price, wish.currency);
  const isReserved = wish.status === "reserved";

  return (
    <Card className="flex flex-col overflow-hidden border border-border/40 break-inside-avoid-column mb-4 hover:border-border hover:shadow-lg transition-all cursor-pointer group">
      <div onClick={onClick}>
        {coverImage ? (
          <div className="relative w-full bg-muted">
            <Image
              src={coverImage}
              alt={wish.title}
              width={400}
              height={400}
              className="w-full h-auto object-cover group-hover:opacity-90 transition-opacity"
              sizes="(min-width: 1280px) 20vw, (min-width: 1024px) 25vw, (min-width: 640px) 40vw, 90vw"
              onError={(event) => {
                event.currentTarget.style.display = "none";
              }}
            />
            {isReserved && (
              <div className="absolute top-3 right-3">
                <Badge variant="secondary" className="bg-black/70 text-white border-0 backdrop-blur-sm text-xs px-3 py-1">
                  {isMine ? "Reserved by you" : "Reserved"}
                </Badge>
              </div>
            )}
          </div>
        ) : (
          <div className="relative w-full bg-muted/30 flex items-center justify-center" style={{ minHeight: '240px' }}>
            <Gift className="h-16 w-16 text-muted-foreground/30" />
            {isReserved && (
              <div className="absolute top-3 right-3">
                <Badge variant="secondary" className="bg-black/70 text-white border-0 backdrop-blur-sm text-xs px-3 py-1">
                  {isMine ? "Reserved by you" : "Reserved"}
                </Badge>
              </div>
            )}
          </div>
        )}

        <CardContent className="p-4 space-y-2">
          <div className="space-y-1">
            <h3 className="font-semibold text-base leading-tight group-hover:underline">
              {wish.title}
            </h3>
            {wish.description && (
              <p className="text-sm text-muted-foreground line-clamp-2">
                {wish.description}
              </p>
            )}
          </div>

          {price && (
            <div className="text-sm font-semibold text-foreground">
              {price}
            </div>
          )}
        </CardContent>
      </div>

      <CardContent className="px-4 pb-4 pt-0 mt-auto">
        {isReserved ? (
          <>
            {isMine && onCancel && (
              <Button
                variant="outline"
                size="sm"
                onClick={(e) => {
                  e.stopPropagation();
                  onCancel();
                }}
                disabled={cancelling}
                className="w-full"
              >
                {cancelling ? (
                  <span className="inline-flex items-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Cancelling…
                  </span>
                ) : (
                  "Cancel reservation"
                )}
              </Button>
            )}
          </>
        ) : (
          <Button
            onClick={(e) => {
              e.stopPropagation();
              onReserve();
            }}
            disabled={reserving}
            className="w-full"
            size="sm"
          >
            {reserving ? (
              <span className="inline-flex items-center gap-2">
                <Loader2 className="h-4 w-4 animate-spin" />
                Reserving…
              </span>
            ) : (
              "Reserve"
            )}
          </Button>
        )}
      </CardContent>
    </Card>
  );
}

function ReservationDialog({
  open,
  onOpenChange,
  wish,
  values,
  onChange,
  onSubmit,
  submitting,
  error,
  notice,
  verifiedEmail,
  authReady,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  wish: Wish | null;
  values: ReservationForm;
  onChange: Dispatch<SetStateAction<ReservationForm>>;
  onSubmit: () => Promise<void>;
  submitting: boolean;
  error: string | null;
  notice: string | null;
  verifiedEmail: string | null;
  authReady: boolean;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Reserve &quot;{wish?.title ?? "Wish"}&quot;</DialogTitle>
          <DialogDescription>
            Your reservation will be tied to this email address. You can manage your reservations using the link we&apos;ll send you.
          </DialogDescription>
        </DialogHeader>
        <form
          onSubmit={async (event) => {
            event.preventDefault();
            await onSubmit();
          }}
          className="space-y-4 px-6 pb-6 pt-4"
        >
          {verifiedEmail ? (
            <div className="rounded-md border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm text-emerald-900">
              Signed in as <span className="font-semibold">{verifiedEmail}</span>. This email will be shared with the wishlist owner.
            </div>
          ) : null}

          <div className="grid gap-4">
            <div className="grid gap-2">
              <Label htmlFor="reserve-name" className="inline-flex items-center gap-2">
                <User className="h-4 w-4 text-muted-foreground" />
                Your name
              </Label>
              <Input
                id="reserve-name"
                placeholder="Optional"
                value={values.name}
                onChange={(event) =>
                  onChange((prev) => ({ ...prev, name: event.target.value }))
                }
                autoComplete="name"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="reserve-email" className="inline-flex items-center gap-2">
                <Mail className="h-4 w-4 text-muted-foreground" />
                Email address
              </Label>
              <Input
                id="reserve-email"
                type="email"
                required
                value={values.email}
                onChange={(event) =>
                  onChange((prev) => ({ ...prev, email: event.target.value }))
                }
                autoComplete="email"
                placeholder="you@example.com"
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="reserve-message">Message for the owner</Label>
              <Textarea
                id="reserve-message"
                placeholder="Add a note (optional)"
                value={values.message}
                onChange={(event) =>
                  onChange((prev) => ({ ...prev, message: event.target.value }))
                }
                rows={4}
              />
            </div>
          </div>

          {error ? (
            <p className="text-sm font-medium text-destructive">{error}</p>
          ) : null}

          {notice ? (
            <p className="rounded-md border border-primary/30 bg-primary/10 px-4 py-2 text-sm text-primary">
              {notice}
            </p>
          ) : null}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={submitting}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={submitting || !authReady}>
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
}

function WishDetailDialog({
  open,
  onOpenChange,
  wish,
  onReserve,
  onCancel,
  isMine,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  wish: Wish | null;
  onReserve: () => void;
  onCancel?: () => void;
  isMine?: boolean;
}) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  if (!wish) return null;

  const images = wish.images ?? [];
  const price = formatPrice(wish.price, wish.currency);
  const isReserved = wish.status === "reserved";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl">{wish.title}</DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          {images.length > 0 && (
            <div className="space-y-3">
              <div className="relative w-full bg-muted rounded-lg overflow-hidden" style={{ aspectRatio: '16/9' }}>
                <Image
                  src={images[currentImageIndex]}
                  alt={wish.title}
                  fill
                  className="object-contain"
                  sizes="(min-width: 768px) 50vw, 90vw"
                  onError={(event) => {
                    event.currentTarget.style.display = "none";
                  }}
                />
                {isReserved && (
                  <div className="absolute top-4 right-4">
                    <Badge variant="secondary" className="bg-black/80 text-white border-0 backdrop-blur-sm px-4 py-2">
                      {isMine ? "Reserved by you" : "Reserved"}
                    </Badge>
                  </div>
                )}
              </div>

              {images.length > 1 && (
                <div className="flex gap-2 overflow-x-auto pb-2">
                  {images.map((img, idx) => (
                    <button
                      key={idx}
                      onClick={() => setCurrentImageIndex(idx)}
                      className={`relative flex-shrink-0 w-20 h-20 rounded-md overflow-hidden border-2 transition-all ${
                        idx === currentImageIndex
                          ? 'border-primary'
                          : 'border-border hover:border-border/60'
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
            </div>
          )}

          <div className="space-y-4">
            {price && (
              <div className="text-3xl font-bold">{price}</div>
            )}

            {wish.description && (
              <div className="space-y-2">
                <h3 className="font-semibold text-lg">Description</h3>
                <p className="text-muted-foreground leading-relaxed">{wish.description}</p>
              </div>
            )}

            {wish.url && (
              <div className="pt-2">
                <a
                  href={wish.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 text-primary hover:underline font-medium"
                >
                  View product details →
                </a>
              </div>
            )}

            {isReserved && (wish.reserverName || wish.reservedMessage) && (
              <div className="space-y-2 pt-4 border-t">
                <h3 className="font-semibold text-sm text-muted-foreground">Reservation Details</h3>
                {wish.reserverName && (
                  <p className="text-sm">
                    Reserved by <span className="font-medium">{wish.reserverName}</span>
                  </p>
                )}
                {wish.reservedMessage && (
                  <p className="text-sm italic text-muted-foreground">
                    &quot;{wish.reservedMessage}&quot;
                  </p>
                )}
              </div>
            )}
          </div>
        </div>

        <DialogFooter className="flex gap-2">
          {isReserved ? (
            <>
              {isMine && onCancel && (
                <Button variant="outline" onClick={onCancel} className="flex-1">
                  Cancel reservation
                </Button>
              )}
              <Button variant="secondary" onClick={() => onOpenChange(false)} className="flex-1">
                Close
              </Button>
            </>
          ) : (
            <>
              <Button variant="outline" onClick={() => onOpenChange(false)} className="flex-1">
                Close
              </Button>
              <Button onClick={onReserve} className="flex-1">
                Reserve this item
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default PublicWishlistView;
