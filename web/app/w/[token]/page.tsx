import { PublicWishlistView } from "@/components/wishlist/public-wishlist-view";

export const runtime = 'edge';

export default async function WishlistTokenPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;
  return <PublicWishlistView shareToken={token} />;
}
