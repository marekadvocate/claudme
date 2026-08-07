// Frame capture over the Chrome DevTools Protocol.
//
// Screen recording needs a permission this terminal does not have, so instead we drive a
// headless Chrome ourselves and pull frames straight out of the renderer. No Puppeteer:
// Node 24 has a global WebSocket, and CDP is just JSON over one socket.
import { spawn } from 'node:child_process';
import { mkdir, writeFile, rm } from 'node:fs/promises';
import { setTimeout as sleep } from 'node:timers/promises';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const [url, outDir, wStr, hStr, secStr, fpsStr] = process.argv.slice(2);
const W = +wStr, H = +hStr, SECONDS = +secStr, FPS = +fpsStr;
const PORT = 9222 + Math.floor(Math.random() * 500);

await rm(outDir, { recursive: true, force: true });
await mkdir(outDir, { recursive: true });

const chrome = spawn(CHROME, [
  '--headless=new', `--remote-debugging-port=${PORT}`, '--disable-gpu',
  '--hide-scrollbars', '--mute-audio', `--window-size=${W},${H}`,
  '--force-device-scale-factor=1', '--no-first-run', '--no-default-browser-check',
  '--user-data-dir=/tmp/claudme-cap-'+PORT+'', 'about:blank',
], { stdio: 'ignore' });

const targetUrl = await (async () => {
  for (let i = 0; i < 60; i++) {
    try {
      const r = await fetch(`http://127.0.0.1:${PORT}/json/version`);
      return (await r.json()).webSocketDebuggerUrl;
    } catch { await sleep(250); }
  }
  throw new Error('Chrome never came up');
})();

const ws = new WebSocket(targetUrl);
await new Promise(r => ws.addEventListener('open', r, { once: true }));

let id = 0;
const pending = new Map();
ws.addEventListener('message', e => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); }
});
// Every CDP call gets a ceiling. Page.captureScreenshot stops returning at a reproducible
// point in a long capture — always the same frame — and an un-timed promise turned that into
// a dead render that still looked alive: process up, 0% CPU, no new files for half an hour.
const send = (method, params = {}, sessionId, ms = 4000) => new Promise(res => {
  const n = ++id;
  const t = setTimeout(() => { pending.delete(n); res(null); }, ms);
  pending.set(n, v => { clearTimeout(t); res(v); });
  ws.send(JSON.stringify({ id: n, method, params, sessionId }));
});

const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
await send('Page.enable', {}, sessionId);
await send('Emulation.setDeviceMetricsOverride',
  { width: W, height: H, deviceScaleFactor: 1, mobile: false }, sessionId);
// Virtual time is the whole trick. Capturing a 1920x1080 frame takes far longer than
// the 33ms it represents, so with the real clock the page races ahead of the frame
// index and the film desynchronises from its own script. Under a paused virtual clock
// Chrome only advances time when we say so, by exactly one frame at a time — every
// setTimeout, transition and rAF steps in lockstep with what we record.
const stepMs = 1000 / FPS;
// Chrome occasionally stops delivering virtualTimeBudgetExpired — deterministically, in
// this project, around the 1240th frame. Waiting on it unconditionally deadlocked the whole
// render for half an hour at a time with the process at 0% CPU. One missed event must not
// be able to do that, so the wait has a ceiling: past it we simply take the next frame.
const budgetExpired = (ms = 2500) => new Promise(res => {
  let done = false;
  const finish = () => { if (!done) { done = true; ws.removeEventListener('message', h); res(); } };
  const h = e => {
    const m = JSON.parse(e.data);
    if (m.method === 'Emulation.virtualTimeBudgetExpired') finish();
  };
  ws.addEventListener('message', h);
  setTimeout(finish, ms);
});

await send('Emulation.setVirtualTimePolicy', { policy: 'pause' }, sessionId);
await send('Network.enable', {}, sessionId);
await send('Page.navigate', { url }, sessionId);

// let fonts, the voxel logo and the first crab layout settle before frame zero
let wait = budgetExpired(8000);
await send('Emulation.setVirtualTimePolicy',
  { policy: 'pauseIfNetworkFetchesPending', budget: 1500 }, sessionId);
await wait;

// Everything is loaded; cut the network so the render-waiting policy below has nothing
// outstanding to block on.
await send('Network.emulateNetworkConditions',
  { offline: true, latency: 0, downloadThroughput: 0, uploadThroughput: 0 }, sessionId);

let lastFrame = null;
const total = Math.round(SECONDS * FPS);
for (let i = 0; i < total; i++) {
  const shot = await send('Page.captureScreenshot',
    { format: 'jpeg', quality: 92, captureBeyondViewport: false }, sessionId);
  const name = `${outDir}/f${String(i).padStart(5, '0')}.jpg`;
  if (shot?.data) {
    lastFrame = Buffer.from(shot.data, 'base64');
  }
  // a dropped frame repeats the previous one rather than stopping the film
  await writeFile(name, lastFrame ?? Buffer.alloc(0));
  wait = budgetExpired();
  await send('Emulation.setVirtualTimePolicy',
    { policy: 'pauseIfNetworkFetchesPending', budget: stepMs }, sessionId);
  await wait;
  if (i % 60 === 0) process.stdout.write(`\r  ${i}/${total} frames`);
}
process.stdout.write(`\r  ${total}/${total} frames\n`);
ws.close();
chrome.kill();
