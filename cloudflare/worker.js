// vtex.win Worker: serves this repo as static assets and forwards /api/* to the
// existing Vercel deployment, which stays the API of record.

// Mirrors the "rewrites" block in vercel.json.
const REWRITES = {
	"/": "/src/frontend/index.html",
	"/projects": "/src/frontend/projects.html",
	"/projects/scripts": "/src/frontend/projects/scripts.html",
	"/projects/scripts.json": "/src/frontend/projects/scripts.json",
	"/projects/games": "/src/frontend/projects/games.html",
	"/projects/games.json": "/src/frontend/projects/games.json",
	"/projects/misc": "/src/frontend/projects/misc.html",
	"/projects/misc.json": "/src/frontend/projects/misc.json",
	"/stats": "/src/frontend/stats.html",
	"/setup": "/src/frontend/setup.html",
	"/key-system": "/src/frontend/key-system/index.html",
	"/calculator/": "/src/frontend/calculator/index.html",
	"/pollinations/": "/src/frontend/pollinations/index.html",
};

// Served from their own subpath because their HTML uses relative asset links.
const DIR_REWRITES = ["/calculator/", "/pollinations/"];

// Mirrors the "redirects" block in vercel.json.
const REDIRECTS = {
	"/calculator": "/calculator/",
	"/pollinations": "/pollinations/",
};

// Mirrors the "headers" block in vercel.json.
const SECURITY_HEADERS = {
	"X-Content-Type-Options": "nosniff",
	"X-Frame-Options": "DENY",
	"X-XSS-Protection": "1; mode=block",
	"Referrer-Policy": "strict-origin-when-cross-origin",
	"Strict-Transport-Security": "max-age=31536000; includeSubDomains",
};

export default {
	async fetch(request, env) {
		const url = new URL(request.url);
		const { pathname } = url;

		const redirect = REDIRECTS[pathname];
		if (redirect) return Response.redirect(url.origin + redirect, 301);

		if (pathname === "/api" || pathname.startsWith("/api/")) {
			return proxyApi(request, url, env);
		}

		const assetPath = resolveAssetPath(pathname);
		const assetRequest =
			assetPath === pathname ? request : new Request(new URL(assetPath + url.search, url.origin), request);

		return withSecurityHeaders(await env.ASSETS.fetch(assetRequest));
	},
};

function resolveAssetPath(pathname) {
	if (pathname in REWRITES) return REWRITES[pathname];
	for (const prefix of DIR_REWRITES) {
		if (pathname.startsWith(prefix) && pathname.length > prefix.length) return "/src/frontend" + pathname;
	}
	return pathname;
}

async function proxyApi(request, url, env) {
	const target = new URL(url.pathname + url.search, env.API_ORIGIN);
	const headers = new Headers(request.headers);
	headers.delete("host");

	const init = { method: request.method, headers, redirect: "manual" };
	if (request.method !== "GET" && request.method !== "HEAD") init.body = request.body;

	return fetch(target, init);
}

// Asset responses carry immutable headers, so rebuild instead of mutating.
function withSecurityHeaders(response) {
	const headers = new Headers(response.headers);
	for (const [key, value] of Object.entries(SECURITY_HEADERS)) headers.set(key, value);

	return new Response(response.body, {
		status: response.status,
		statusText: response.statusText,
		headers,
	});
}
