const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const SESSION_COOKIE = 'fred_session';
const SESSION_TTL_SECONDS = 60 * 60 * 12;
const MAX_JSON_BODY_BYTES = 1024 * 1024;
const LOCAL_ENV_FILES = ['.env', '.env.local'];

let localEnvCache = null;


function parseEnvFile(contents) {
	const values = {};
	const lines = contents.split(/\r?\n/);
	for (const rawLine of lines) {
		const line = rawLine.trim();
		if (!line || line.startsWith('#')) {
			continue;
		}

		const separatorIndex = line.indexOf('=');
		if (separatorIndex <= 0) {
			continue;
		}

		const key = line.slice(0, separatorIndex).trim();
		if (!key) {
			continue;
		}

		let value = line.slice(separatorIndex + 1).trim();
		if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
			value = value.slice(1, -1);
		}

		values[key] = value;
	}

	return values;
}


function loadLocalEnv() {
	if (localEnvCache !== null) {
		return localEnvCache;
	}

	const rootDir = path.resolve(__dirname, '..');
	const merged = {};
	for (const fileName of LOCAL_ENV_FILES) {
		const filePath = path.join(rootDir, fileName);
		if (!fs.existsSync(filePath)) {
			continue;
		}

		Object.assign(merged, parseEnvFile(fs.readFileSync(filePath, 'utf8')));
	}

	localEnvCache = merged;
	return localEnvCache;
}

function getEnv(name) {
	const value = process.env[name] || loadLocalEnv()[name];
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
		try {
			cookies[rawName] = decodeURIComponent(rawValue.join('='));
		} catch {
			cookies[rawName] = rawValue.join('=');
		}
	});

	return cookies;
}

function safeEqual(left, right) {
	if (typeof left !== 'string' || typeof right !== 'string') {
		return false;
	}

	const leftHash = crypto.createHash('sha256').update(left, 'utf8').digest();
	const rightHash = crypto.createHash('sha256').update(right, 'utf8').digest();
	return crypto.timingSafeEqual(leftHash, rightHash);
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

function parseJsonText(text) {
	if (!text.trim()) {
		return {};
	}
	return JSON.parse(text);
}

async function readJsonBody(req, options = {}) {
	const maxBytes = Number.isInteger(options.maxBytes) && options.maxBytes > 0
		? options.maxBytes
		: MAX_JSON_BODY_BYTES;

	if (typeof req.body === 'object' && req.body !== null) {
		return req.body;
	}

	if (typeof req.body === 'string' || Buffer.isBuffer(req.body)) {
		const bodyBuffer = Buffer.isBuffer(req.body) ? req.body : Buffer.from(req.body, 'utf8');
		if (bodyBuffer.length > maxBytes) {
			throw new Error('JSON body too large.');
		}
		return parseJsonText(bodyBuffer.toString('utf8'));
	}

	const chunks = [];
	let receivedBytes = 0;
	for await (const chunk of req) {
		const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
		receivedBytes += buffer.length;
		if (receivedBytes > maxBytes) {
			throw new Error('JSON body too large.');
		}
		chunks.push(buffer);
	}

	if (chunks.length === 0) {
		return {};
	}

	return parseJsonText(Buffer.concat(chunks).toString('utf8'));
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
	const cookies = parseCookies(req.headers && req.headers.cookie);
	return decodeSession(cookies[SESSION_COOKIE], sessionSecret);
}

function requireSession(req) {
	const { username, password, sessionSecret } = getSessionConfig();
	if (!username || !password || !sessionSecret) {
		return { error: 'Server auth is not configured. Set APP_USERNAME, APP_PASSWORD, and APP_SESSION_SECRET.', statusCode: 500 };
	}

	const session = getSession(req, sessionSecret);
	if (!session || !safeEqual(session.username, username)) {
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
