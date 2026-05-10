const crypto = require('crypto');

const SESSION_COOKIE = 'fred_session';
const SESSION_TTL_SECONDS = 60 * 60 * 12;

function getEnv(name) {
	const value = process.env[name];
	return typeof value === 'string' ? value.trim() : '';
}

function json(res, statusCode, body) {
	res.status(statusCode).setHeader('Content-Type', 'application/json; charset=utf-8');
	res.send(JSON.stringify(body));
}

function parseCookies(header) {
	const cookies = {};
	if (!header) {
		return cookies;
	}

	header.split(';').forEach((entry) => {
		const [rawName, ...rawValue] = entry.trim().split('=');
		if (!rawName) {
			return;
		}
		cookies[rawName] = decodeURIComponent(rawValue.join('='));
	});

	return cookies;
}

function safeEqual(left, right) {
	const leftBuffer = Buffer.from(left, 'utf8');
	const rightBuffer = Buffer.from(right, 'utf8');
	if (leftBuffer.length !== rightBuffer.length) {
		return false;
	}
	return crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function createSignature(payload, secret) {
	return crypto.createHmac('sha256', secret).update(payload).digest('base64url');
}

function encodeSession(username, expiresAt, secret) {
	const payload = JSON.stringify({ username, expiresAt });
	const encodedPayload = Buffer.from(payload, 'utf8').toString('base64url');
	const signature = createSignature(encodedPayload, secret);
	return `${encodedPayload}.${signature}`;
}

function decodeSession(token, secret) {
	if (!token || !token.includes('.')) {
		return null;
	}

	const [encodedPayload, signature] = token.split('.', 2);
	const expectedSignature = createSignature(encodedPayload, secret);
	if (!safeEqual(signature, expectedSignature)) {
		return null;
	}

	let payload;
	try {
		payload = JSON.parse(Buffer.from(encodedPayload, 'base64url').toString('utf8'));
	} catch {
		return null;
	}

	if (!payload || typeof payload.username !== 'string' || typeof payload.expiresAt !== 'number') {
		return null;
	}

	if (Date.now() > payload.expiresAt) {
		return null;
	}

	return payload;
}

async function readJsonBody(req) {
	if (typeof req.body === 'object' && req.body !== null) {
		return req.body;
	}

	const chunks = [];
	for await (const chunk of req) {
		chunks.push(chunk);
	}

	if (chunks.length === 0) {
		return {};
	}

	return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function buildSessionCookie(token, maxAge) {
	const parts = [
		`${SESSION_COOKIE}=${encodeURIComponent(token)}`,
		'Path=/',
		'HttpOnly',
		'SameSite=Lax',
		'Secure',
		`Max-Age=${maxAge}`,
	];
	return parts.join('; ');
}

function getSessionConfig() {
	return {
		username: getEnv('APP_USERNAME'),
		password: getEnv('APP_PASSWORD'),
		sessionSecret: getEnv('APP_SESSION_SECRET'),
	};
}

function getSession(req, sessionSecret) {
	const cookies = parseCookies(req.headers.cookie);
	return decodeSession(cookies[SESSION_COOKIE], sessionSecret);
}

function requireSession(req) {
	const { sessionSecret } = getSessionConfig();
	if (!sessionSecret) {
		return { error: 'Server auth is not configured. Set APP_USERNAME, APP_PASSWORD, and APP_SESSION_SECRET.', statusCode: 500 };
	}

	const session = getSession(req, sessionSecret);
	if (!session) {
		return { error: 'Authentication required.', statusCode: 401 };
	}

	return { session };
}

module.exports = {
	SESSION_COOKIE,
	SESSION_TTL_SECONDS,
	buildSessionCookie,
	encodeSession,
	getEnv,
	getSession,
	getSessionConfig,
	json,
	readJsonBody,
	requireSession,
	safeEqual,
};