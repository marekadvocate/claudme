// Runs the page under virtual time and evaluates an expression after N frames.
// Needed because rAF never fires in a background tab, so DOM the animation loop builds
// (the deckchair, for one) cannot be observed from the browser-automation side at all.
import { spawn } from 'node:child_process';
import { setTimeout as sleep } from 'node:timers/promises';
const CHROME='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const [url, expr, framesStr] = process.argv.slice(2);
const PORT = 9700 + Math.floor(Math.random()*200);
const chrome = spawn(CHROME,['--headless=new',`--remote-debugging-port=${PORT}`,'--disable-gpu',
  '--mute-audio','--window-size=1600,900',`--user-data-dir=/tmp/claudme-probe-${PORT}`,'about:blank'],{stdio:'ignore'});
const wsUrl = await (async()=>{for(let i=0;i<60;i++){try{const r=await fetch(`http://127.0.0.1:${PORT}/json/version`);return (await r.json()).webSocketDebuggerUrl;}catch{await sleep(250);}}})();
const ws=new WebSocket(wsUrl); await new Promise(r=>ws.addEventListener('open',r,{once:true}));
let id=0; const pending=new Map();
ws.addEventListener('message',e=>{const m=JSON.parse(e.data); if(m.id&&pending.has(m.id)){pending.get(m.id)(m.result);pending.delete(m.id);}});
const send=(method,params={},sessionId)=>new Promise(res=>{const n=++id;pending.set(n,res);ws.send(JSON.stringify({id:n,method,params,sessionId}));});
const {targetId}=await send('Target.createTarget',{url:'about:blank'});
const {sessionId}=await send('Target.attachToTarget',{targetId,flatten:true});
await send('Page.enable',{},sessionId); await send('Runtime.enable',{},sessionId);
const expired=()=>new Promise(res=>{const h=e=>{const m=JSON.parse(e.data);if(m.method==='Emulation.virtualTimeBudgetExpired'){ws.removeEventListener('message',h);res();}};ws.addEventListener('message',h);});
await send('Emulation.setVirtualTimePolicy',{policy:'pause'},sessionId);
await send('Page.navigate',{url},sessionId);
let w=expired(); await send('Emulation.setVirtualTimePolicy',{policy:'pauseIfNetworkFetchesPending',budget:1500},sessionId); await w;
for(let i=0;i<(+framesStr||30);i++){ w=expired(); await send('Emulation.setVirtualTimePolicy',{policy:'pauseIfNetworkFetchesPending',budget:33},sessionId); await w; }
const r=await send('Runtime.evaluate',{expression:expr,returnByValue:true},sessionId);
console.log(JSON.stringify(r.result?.value ?? r.exceptionDetails?.text ?? r));
ws.close(); chrome.kill();
