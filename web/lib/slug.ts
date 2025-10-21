export function slugify(value: string): string {
  return value
    .toString()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");
}

export function getWishlistSlug({
  slug,
  name,
  shareToken,
  id,
}: {
  slug?: string | null;
  name?: string | null;
  shareToken?: string | null;
  id?: string | null;
}): string {
  if (slug && slug.trim().length > 0) {
    return slug.trim().toLowerCase();
  }

  const base = slugify(name ?? "");
  if (base) {
    return base;
  }

  if (shareToken) {
    return `wishlist-${shareToken.slice(0, 8).toLowerCase()}`;
  }

  if (id) {
    return `wishlist-${id.toLowerCase()}`;
  }

  return "wishlist";
}

export function matchesWishlistSlug(
  target: { slug?: string | null; name?: string | null; shareToken?: string | null; id?: string | null },
  slugParam: string,
): boolean {
  const normalizedParam = slugParam.toLowerCase();

  if (target.slug && target.slug.toLowerCase() === normalizedParam) {
    return true;
  }

  const base = slugify(target.name ?? "");
  if (base && base === normalizedParam) {
    return true;
  }

  if (target.shareToken && target.shareToken.toLowerCase() === normalizedParam) {
    return true;
  }

  if (target.id && target.id.toLowerCase() === normalizedParam) {
    return true;
  }

  return false;
}

export function buildWishlistPath(username: string, slug: string): string {
  return `/${encodeURIComponent(username)}/${encodeURIComponent(slug)}`;
}
