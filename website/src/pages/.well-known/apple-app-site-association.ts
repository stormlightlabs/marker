const appleAppSiteAssociation = {
  applinks: { apps: [], details: [{ appID: '8TVR4TPL9Y.org.stormlightlabs.marker', paths: ['/oauth/callback'] }] },
  webcredentials: { apps: ['8TVR4TPL9Y.org.stormlightlabs.marker'] },
};

export function GET() {
  return new Response(JSON.stringify(appleAppSiteAssociation, null, 2), {
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'public, max-age=0, must-revalidate',
    },
  });
}
