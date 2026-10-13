// APP_ORIGIN is retained for existing deployments; it may include a hosting path.
export function notificationLinks(base: string | undefined, bookingId: string) {
  if (!base) return undefined;
  const url = new URL(base);
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) {
    throw new Error('APP_ORIGIN must be an HTTPS application base URL.');
  }
  url.pathname = `${url.pathname.replace(/\/+$/, '')}/`;
  return {
    link: new URL(`booking/${encodeURIComponent(bookingId)}`, url).href,
    icon: new URL('icons/Icon-192.png', url).href,
  };
}
