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
  '--user-data-dir=/tmp/claudme-capture-profile', 'about:blank',
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
const send = (method, params = {}, sessionId) => new Promise(res => {
  const n = ++id;
  pending.set(n, res);
  ws.send(JSON.stringify({ id: n, method, params, sessionId }));
});

const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
await send('Page.enable', {}, sessionId);
await send('Emulation.setDeviceMetricsOverride',
  { width: W, height: H, deviceScaleFactor: 1, mobile: false }, sessionId);
await send('Page.navigate', { url }, sessionId);
await sleep(2600);                      // let fonts, the voxel logo and the crabs settle

const total = Math.round(SECONDS * FPS);
const step = 1000 / FPS;
const t0 = Date.now();
for (let i = 0; i < total; i++) {
  const shot = await send('Page.captureScreenshot',
    { format: 'png', captureBeyondViewport: false }, sessionId);
  await writeFile(`${outDir}/f${String(i).padStart(5, '0')}.png`,
                  Buffer.from(shot.data, 'base64'));
  const drift = (t0 + (i + 1) * step) - Date.now();
  if (drift > 0) await sleep(drift);
  if (i % 30 === 0) process.stdout.write(`\r  ${i}/${total} frames`);
}
process.stdout.write(`\r  ${total}/${total} frames\n`);
ws.close();
chrome.kill();
