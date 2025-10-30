export async function uploadToR2(
  file: File,
  getPresignedUrl: () => Promise<{ uploadUrl: string; publicUrl: string }>
): Promise<string> {
  const { uploadUrl, publicUrl } = await getPresignedUrl();

  const response = await fetch(uploadUrl, {
    method: 'PUT',
    body: file,
    headers: {
      'Content-Type': file.type,
    },
  });

  if (!response.ok) {
    throw new Error(`Upload failed: ${response.statusText}`);
  }

  return publicUrl;
}
