import { Suspense } from "react";
import VerifyReservationContent from "./verify-reservation-content";

export const dynamic = 'force-dynamic';

export default function VerifyReservationPage() {
  return (
    <Suspense fallback={<div className="flex min-h-screen items-center justify-center">Loading...</div>}>
      <VerifyReservationContent />
    </Suspense>
  );
}
