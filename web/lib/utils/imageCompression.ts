import imageCompression from 'browser-image-compression';

export async function compressWishlistCover(file: File): Promise<File> {
  return imageCompression(file, {
    maxWidthOrHeight: 1920,
    initialQuality: 0.85,
    useWebWorker: true,
  });
}

export async function compressWishImage(file: File): Promise<File> {
  return imageCompression(file, {
    maxWidthOrHeight: 1024,
    initialQuality: 0.85,
    useWebWorker: true,
  });
}
