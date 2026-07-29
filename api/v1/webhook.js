import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { ApiError } from '../_lib/errors.js';
import { rateLimit } from '../_lib/validate.js';

export const config = { runtime: 'nodejs' };

const webhooks = {
	'games/Answer-Or-Die': 'https://discord.com/api/webhooks/1531135919917236374/nZRB7pmRfxM1mh0nhmC2FIKYFGO4oJnAveB7UeAj79czODk93-UBVw08gJigMv3GeOAs',
	'games/Block-Puzzle': 'https://discord.com/api/webhooks/1531136178709987379/l9V3QpoIexIz8EkENjJLKES8FdBGPWvtkgBJWP9CWBAD0k7ocbuclLf_N_JnV539R3bD',
	'games/Build-a-Scam-Empire': 'https://discord.com/api/webhooks/1531136972842860655/uVU7NDu-3Cncti6wATMJ05OliGg8cU8x8abHXRdsUCCeCnJENs-ALKfnvI_w0q3yXixg',
	'games/Catch-And-Tame': 'https://discord.com/api/webhooks/1531137082200952973/IpILm2av_hiaGixzjpoL9_Q1BVGTy0KJurE5XCz4Ol59TkAAa9k9dsRF5F95O7W3dxV7',
	'games/Clone-Line-Challenge': 'https://discord.com/api/webhooks/1531137228422647838/-YO3KfWROcPJ6EtGqAqXfml-cte-JobC5312vVKFvo8-nqoNBDlU6Fp9um-iv04qzOIo',
	'games/Escape-Tsunami-for-Brainrots': 'https://discord.com/api/webhooks/1531137317992140953/xMY5k5JmAZ5uGeAE9idfcGjpibCWPQ45Opk2b2RMNKVaJHRLGgDaggy9AGLdvUAP-qSq',
	'games/Grow-Bigger-Every-Step': 'https://discord.com/api/webhooks/1531137405774725130/kkFh2q0jfP7xLBv_yobacSKRHtkmG6Mgxfh8LIcLi-FzM2lkMmG2yvv0rZKTADPwHHqt',
	'games/Guess-The-Flag-Or-Die': 'https://discord.com/api/webhooks/1531137500486176909/JnRDnC3wLaswEMEpWhlbPwFXxk0hK-Ea-9-pLJ5qpCW8pe8k2uaYmI3-IzYFTlutX6x7',
	'games/Heavy-Metal': 'https://discord.com/api/webhooks/1531137586054172693/Sdo36Ib3zejveWBxlcuXKRAXlAJbr_Onm5gEer5PPcVD-Hekwj55q9JiKuvDq6fjAZIt',
	'games/Horse-Race': 'https://discord.com/api/webhooks/1531137675216687205/UJjhyRpRWAjt-OvFBPFIbCq-B-DASBFs-uILF1Xbzn60CkLF3auAEt_B20YW4bpyQLCN',
	'games/Hunting-Season': 'https://discord.com/api/webhooks/1531137751272132688/OQo22LxTxo7mYWcK9l1X1h-zhx2r7TDAff9er3lEME4-Uq1qldRMtxjlUCwX_ud7RWmB',
	'games/Hyper-Speed-Runner': 'https://discord.com/api/webhooks/1531137962249687060/I1XPm3OkKemJ09yOuvzNJl12pWuMlG61gZESWqw0O0WRyYCIwsZth8_RnhJk0ZO7DeW7',
	'games/Idle-Blocks': 'https://discord.com/api/webhooks/1531137844712833135/M78iMPb2xooIh25Xs9FY2zlInZdYamSjhK4fWo6KZmasTDkAEDgsu-htqcbV1dOmkaH5',
	'games/Industrialist': 'https://discord.com/api/webhooks/1531138076703854706/cMoc9DtKXG6_DdVWYPYmKNMRwzjkow59YELNmB4NAkaOnuO0Fc1q1-ymQYBU7yL1sp_Y',
	'games/Kick-a-Lucky-Block-for-Brainrots': 'https://discord.com/api/webhooks/1531138171063111812/TDp0pf2YHtg2deY5d1cWRuEhqvf14evoc2G0NYgWfYDmJXbBkkLZj8HyJ0itQl4u9Al_',
	'games/Lucky-Blocks-Battleground': 'https://discord.com/api/webhooks/1531138248661930015/ouhlU0-38RiQ3IB65lVzDdAO39RVjPrEoHpr4VJ0uQGAaP03Z90mW8BRB2snNFcbh6iR',
	'games/Operation-One': 'https://discord.com/api/webhooks/1531138360666755162/83TsdBJPpTWkW-ZEj0fGEmTqmpKzof-BHna2ZFJskJpZdHIJNGD1yCEo7o3Pht3D5PJ8',
	'games/Prospecting': 'https://discord.com/api/webhooks/1531138458007900181/j_3fmYVB99u5up9izZ259NiQjjHOm0-ulBowgVP-Kubo9QpHZG5FKuuTvgGvs80X4ngI',
	'games/Step-for-Jumps': 'https://discord.com/api/webhooks/1531138572680171550/-E9UGAK5kcvePzhcaCbnBXmGz08UOnFKSzY8_xiDeuPq9bw_kNqHNFsy07doYZyIBota',
	'games/Teen-Titan-Battleground': 'https://discord.com/api/webhooks/1531138705291481228/Bk2HJ5sSEPpBJStEDYTETUa8BB5R38R7iQbDWNDMATiiDBHNN4LB85GAZphv0A2Jr6OS',
	'games/Timebomb-Duel': 'https://discord.com/api/webhooks/1531138821524291676/9Slep8aVYXVO56oV8ZWDF5vyuI6sn7u0PJ9TFTjS821VVpiTY_cbM0F1LjpFpFKkTetm',
	'games/Titan-Warfare': 'https://discord.com/api/webhooks/1531138918576029878/OsN1JJMVgltvcaySsCih14zPeHtC_Y9t7jW-vC_w9h68N-JWmPSpF30HtKO0Pa2YoOPW',
	'games/catastrophia': 'https://discord.com/api/webhooks/1531139025300095119/KXv4-OUzQc2_InjTLVAzvbGINLH4FwZGay22F4tuwzbwP6PH6ZPiUgSdXoScuGY2QTt3',
	'games/trident': 'https://discord.com/api/webhooks/1531139142170181642/v9_E0Z4AogIv9XoPIHVk6-iDi2n7YPrxWw46FwM19rswCUXIqv_e__W1Y9bx_VCB-hj-',
    'games/Pickaxe-Swing-Escape': 'https://discord.com/api/webhooks/1531420645458710568/U8JY7mJroSZN8QJwPlL3-xC2h6KiyfW7F_B4gNKX5FYZLlC926pz9-gUp9VtbTE0A1hb',
};

async function isValidUser(userId) {
	try {
		const res = await fetch(`https://groups.roblox.com/v1/users/${userId}/groups/roles?includeLocked=true`);
		return res.ok;
	} catch {
		return false;
	}
}

function buildEmbed({ User, UserId, Executor, Script, Game, PlaceId }) {
	return {
		title: Game || 'Unknown Game',
		color: 0x00b0f4,
		fields: [
			{ name: 'User', value: `\`${User}\``, inline: true },
			{ name: 'UserId', value: `\`${UserId}\``, inline: true },
			{ name: 'Executor', value: `\`${Executor}\``, inline: true },
			{ name: 'Script', value: `\`${Script}\``, inline: true },
			{ name: 'PlaceId', value: `\`${PlaceId}\``, inline: true },
		],
		footer: { text: 'Roblox Webhook Logger' },
		timestamp: new Date().toISOString(),
	};
}

async function handler_fn(req, res) {
	if (req.method === 'OPTIONS') return handleOptions(req, res);
	if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');
	await rateLimit(req, { limit: 30, window: 60000 });

	const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
	if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request');

	const { User, UserId, Executor, Script, Game, PlaceId } = body;
	if (!Script) throw new ApiError(400, 'Missing Script field');

	const webhookUrl = webhooks[Script];
	if (!webhookUrl) throw new ApiError(404, 'No webhook configured for this script');

	const valid = await isValidUser(UserId);
	if (!valid) return successResponse(res, req, { sent: false, reason: 'Invalid user' });

	const payload = {
		embeds: [buildEmbed({ User, UserId, Executor, Script, Game, PlaceId })],
	};

	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), 10000);

	try {
		const response = await fetch(webhookUrl, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload),
			signal: controller.signal,
		});
		clearTimeout(timeout);

		if (!response.ok) {
			throw new ApiError(502, `Discord webhook returned ${response.status}`);
		}
	} catch (err) {
		clearTimeout(timeout);
		if (err instanceof ApiError) throw err;
		throw new ApiError(502, 'Failed to send Discord webhook');
	}

	return successResponse(res, req, { sent: true, script: Script });
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };