import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';

const SCRIPTS = [
  { title: 'ASCII to Text', description: 'Turns simple text into ASCII using an API.', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/ascii/main.lua"))()', raw_url: 'https://roblox-alpha-murex.vercel.app/src/scripts/ascii/main.lua', tags: ['Open Source'], button_text: 'Copy Loadstring', updated: 'last month' },
  { title: 'ESP', description: 'ESP', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/esp/main.lua"))()', raw_url: 'https://roblox-alpha-murex.vercel.app/src/scripts/esp/main.lua', tags: ['Open Source', 'Key System'], button_text: 'Copy Loadstring', updated: '6 months ago' },
  { title: 'Powerball', description: 'Play Powerball in Roblox with a simple GUI, no money required.', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/powerball/main.lua"))()', raw_url: 'https://roblox-alpha-murex.vercel.app/src/scripts/powerball/main.lua', tags: [], button_text: 'Copy Loadstring', updated: '4 months ago' },
  { title: 'MoreUnc v4', description: 'Replicates Sunc functions, and more, for better script compatibility.', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/unc/main.lua"))()', raw_url: 'https://roblox-alpha-murex.vercel.app/src/scripts/unc/main.lua', tags: ['Open Source'], button_text: 'Copy Loadstring', updated: '3 weeks ago' }
];

const GAMES = [
  { title: 'Answer or Die', description: 'Autofarm', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Answer-Or-Die/main.lua"))()', play_url: 'https://www.roblox.com/games/11966456877/Answer-or-Die', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '10 months ago' },
  { title: 'Block Puzzle', description: 'Auto Farm', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Block-Puzzle/main.lua"))()', play_url: 'https://www.roblox.com/games/15564827526/Block-Puzzle', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 days ago' },
  { title: 'Catch And Tame!', description: 'Get Best Animal', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Catch-And-Tame/main.lua"))()', play_url: 'https://www.roblox.com/games/96645548064314/Catch-And-Tame', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '4 months ago' },
  { title: 'Catastrophia', description: 'Basic Aimbot and Esp', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Catastrophia/main.lua"))()', play_url: 'https://www.roblox.com/games/1087852616/CATASTROPHIA-Survive', tags: ['Functional', 'Undetected', 'First Script for a game'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 weeks ago' },
  { title: 'Escape Tsunami For Brainrots!', description: 'Misc', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Escape-Tsunami-for-Brainrots/main.lua"))()', play_url: 'https://www.roblox.com/games/131623223084840/Escape-Tsunami-For-Brainrots', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '5 months ago' },
  { title: 'Guess the Country Flag or Die!', description: 'Autofarm', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Guess-The-Flag-Or-Die/main.lua"))()', play_url: 'https://www.roblox.com/games/88817068170433/Guess-the-Country-Flag-or-Die', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 weeks ago' },
  { title: 'Heavy Rust', description: 'Silent Aim', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Heavy-Metal/main.lua"))()', play_url: 'https://www.roblox.com/games/74669489500088/Heavy-Rust', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '5 months ago' },
  { title: 'Idle Blocks', description: 'Auto Farm', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Idle-Blocks/main.lua"))()', play_url: 'https://www.roblox.com/games/101759436219635/Idle-Blocks', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 months ago' },
  { title: 'Kick a Lucky Block', description: 'Best Kick', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Kick-a-Lucky-Block-for-Brainrots/main.lua"))()', play_url: 'https://www.roblox.com/games/89469502395769/Kick-a-Lucky-Block', tags: ['Functional', 'Undetected'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 months ago' },
  { title: 'LUCKY BLOCKS Battlegrounds', description: 'Get Blocks Instantly', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Lucky-Blocks-Battleground/main.lua"))()', play_url: 'https://www.roblox.com/games/662417684/LUCKY-BLOCKS-Battlegrounds', tags: ['Functional', 'Undetected', 'Open Source'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 weeks ago' },
  { title: 'Operation One', description: 'Basic Aimbot and Esp', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Operation-One/main.lua"))()', play_url: 'https://www.roblox.com/games/72920620366355/Operation-One', tags: ['Functional', 'Undetected', 'Key System'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: 'last month' },
  { title: 'Prospecting', description: 'Autofarm', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/prospecting/main.lua"))()', play_url: 'https://www.roblox.com/games/129827112113663/Prospecting', tags: ['Functional', 'Undetected', 'Open Source'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 hours ago' },
  { title: 'T-Titans Battlegrounds', description: 'Autofarm, Esp, Aimbot, Triggerbot', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Teen-Titan-Battleground/main.lua"))()', play_url: 'https://www.roblox.com/games/3082002798/T-Titans-Battlegrounds', tags: ['Functional', 'Undetected', 'Open Source'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: 'last month' },
  { title: 'Titan Warfare', description: 'Kill Aura for Titans and People', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Titan-Warfare/main.lua"))()', play_url: 'https://www.roblox.com/games/6297822481/Titan-Warfare', tags: ['Functional', 'Undetected', 'Open Source'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '3 months ago' },
  { title: 'Trident Survival', description: 'Basic Aimbot, Esp, Silent aim, amany of features.', loadstring: 'loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Trident/main.lua"))()', play_url: 'https://www.roblox.com/games/13253735473/Trident-Survival', tags: ['In Development'], button_text: 'Get Script', play_button_text: 'Play on Roblox', updated: '2 weeks ago' }
];

const MISC = [
  { title: 'Rayfield UI Module', description: 'Standalone customized Rayfield UI module for embedding sleek modern interfaces into any Luau script.', snippet: 'local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/main/libraries/Rayfield.luau"))()', raw_url: 'https://raw.githubusercontent.com/matpatz/Roblox/main/libraries/Rayfield.luau', button_text: 'Copy Snippet' },
  { title: 'Voltex API Bridge', description: 'API connector module handling authentication, analytics reporting, and version checking.', snippet: 'fetch("https://raw.githubusercontent.com/matpatz/Roblox/main/api/alpha.js")', raw_url: 'https://raw.githubusercontent.com/matpatz/Roblox/main/api/alpha.js', button_text: 'Copy URL' },
  { title: 'Discord Webhook Logger', description: 'Send execution logs, errors, and status reports directly to your Discord webhook.', snippet: 'loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/main/init.luau"))()', raw_url: 'https://raw.githubusercontent.com/matpatz/Roblox/main/init.luau', button_text: 'Copy Snippet' }
];

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');

  const supabase = getSupabase();

  let scriptsSeeded = 0, gamesSeeded = 0, miscSeeded = 0;

  const { count: sc } = await supabase.from('scripts').select('*', { count: 'exact', head: true });
  if ((sc || 0) === 0) {
    const { error } = await supabase.from('scripts').insert(SCRIPTS);
    if (!error) scriptsSeeded = SCRIPTS.length;
  } else {
    scriptsSeeded = `already has ${sc} items`;
  }

  const { count: gc } = await supabase.from('games').select('*', { count: 'exact', head: true });
  if ((gc || 0) === 0) {
    const { error } = await supabase.from('games').insert(GAMES);
    if (!error) gamesSeeded = GAMES.length;
  } else {
    gamesSeeded = `already has ${gc} items`;
  }

  const { count: mc } = await supabase.from('misc').select('*', { count: 'exact', head: true });
  if ((mc || 0) === 0) {
    const { error } = await supabase.from('misc').insert(MISC);
    if (!error) miscSeeded = MISC.length;
  } else {
    miscSeeded = `already has ${mc} items`;
  }

  return successResponse(res, req, { scripts: scriptsSeeded, games: gamesSeeded, misc: miscSeeded });
}

export { handler_fn as handler };
