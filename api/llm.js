const { getEnv, json, readJsonBody, requireSession } = require('../lib/auth');

const OPENAI_API_URL = 'https://api.openai.com/v1/responses';
const DEFAULT_OPENAI_MODEL = 'gpt-4.1-mini';

function extractText(data) {
	if (typeof data.output_text === 'string' && data.output_text.length > 0) {
		return data.output_text;
	}

	if (!Array.isArray(data.output)) {
		return '';
	}

	const textParts = [];
	for (const item of data.output) {
		if (!item || !Array.isArray(item.content)) {
			continue;
		}

		for (const content of item.content) {
			if (content && typeof content.text === 'string') {
				textParts.push(content.text);
			}
		}
	}

	return textParts.join('\n').trim();
}

module.exports = async function handler(req, res) {
	const auth = requireSession(req);
	if (auth.error) {
		return json(res, auth.statusCode, { error: auth.error });
	}

	if (req.method !== 'POST') {
		res.setHeader('Allow', 'POST');
		return json(res, 405, { error: 'Method not allowed.' });
	}

	const apiKey = getEnv('OPENAI_API_KEY');
	const defaultModel = getEnv('OPENAI_MODEL') || DEFAULT_OPENAI_MODEL;
	if (!apiKey) {
		return json(res, 500, { error: 'OPENAI_API_KEY is not configured.' });
	}

	let body;
	try {
		body = await readJsonBody(req);
	} catch {
		return json(res, 400, { error: 'Invalid JSON body.' });
	}

	const input = typeof body.input === 'string' ? body.input.trim() : '';
	const instructions = typeof body.instructions === 'string' ? body.instructions.trim() : '';
	const model = typeof body.model === 'string' && body.model.trim() ? body.model.trim() : defaultModel;
	const maxOutputTokens = Number.isInteger(body.max_output_tokens) ? body.max_output_tokens : undefined;

	if (!input) {
		return json(res, 400, { error: 'The request body must include a non-empty input string.' });
	}

	const payload = {
		model,
		input,
	};

	if (instructions) {
		payload.instructions = instructions;
	}

	if (typeof maxOutputTokens === 'number' && maxOutputTokens > 0) {
		payload.max_output_tokens = maxOutputTokens;
	}

	let upstreamResponse;
	try {
		upstreamResponse = await fetch(OPENAI_API_URL, {
			method: 'POST',
			headers: {
				'Authorization': `Bearer ${apiKey}`,
				'Content-Type': 'application/json',
			},
			body: JSON.stringify(payload),
		});
	} catch {
		return json(res, 502, { error: 'Failed to reach OpenAI.' });
	}

	let upstreamBody = {};
	try {
		upstreamBody = await upstreamResponse.json();
	} catch {
		upstreamBody = {};
	}

	if (!upstreamResponse.ok) {
		const upstreamError = upstreamBody && upstreamBody.error && typeof upstreamBody.error.message === 'string'
			? upstreamBody.error.message
			: 'OpenAI request failed.';
		return json(res, upstreamResponse.status, { error: upstreamError });
	}

	return json(res, 200, {
		model,
		text: extractText(upstreamBody),
		response: upstreamBody,
	});
};