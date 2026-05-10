const {
	SESSION_TTL_SECONDS,
	buildSessionCookie,
	encodeSession,
	getSession,
	getSessionConfig,
	json,
	readJsonBody,
	safeEqual,
} = require('../lib/auth');

module.exports = async function handler(req, res) {
	if (req.method === 'DELETE') {
		res.setHeader('Set-Cookie', buildSessionCookie('', 0));
		return json(res, 200, { authenticated: false });
	}

	const { username, password, sessionSecret } = getSessionConfig();

	if (!username || !password || !sessionSecret) {
		return json(res, 500, {
			error: 'Server auth is not configured. Set APP_USERNAME, APP_PASSWORD, and APP_SESSION_SECRET.',
		});
	}

	if (req.method === 'GET') {
		const session = getSession(req, sessionSecret);
		if (!session || !safeEqual(session.username, username)) {
			return json(res, 401, { authenticated: false });
		}

		return json(res, 200, { authenticated: true, username: session.username });
	}

	if (req.method !== 'POST') {
		res.setHeader('Allow', 'GET, POST, DELETE');
		return json(res, 405, { error: 'Method not allowed.' });
	}

	let body;
	try {
		body = await readJsonBody(req);
	} catch {
		return json(res, 400, { error: 'Invalid JSON body.' });
	}

	const submittedUsername = typeof body.username === 'string' ? body.username.trim() : '';
	const submittedPassword = typeof body.password === 'string' ? body.password : '';

	if (!safeEqual(submittedUsername, username) || !safeEqual(submittedPassword, password)) {
		return json(res, 401, { error: 'Invalid username or password.' });
	}

	const expiresAt = Date.now() + (SESSION_TTL_SECONDS * 1000);
	const token = encodeSession(username, expiresAt, sessionSecret);
	res.setHeader('Set-Cookie', buildSessionCookie(token, SESSION_TTL_SECONDS));

	return json(res, 200, { authenticated: true, username });
};
