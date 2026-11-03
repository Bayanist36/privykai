/*
 * Render + layout audit for the design kit.
 * Usage:
 *   node tools/render.mjs audit
 *   node tools/render.mjs screens
 *   node tools/render.mjs store
 * Requires Node 22+ and Google Chrome installed.
 */
import { spawn } from "node:child_process";
import { mkdir, writeFile, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const chrome =
  process.env.CHROME_PATH ||
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9333;
const profile = path.join(process.env.TEMP || ".", "design-kit-chrome-" + Date.now());

const screens = [
  ["01-onboarding", "mockups/01-onboarding.html"],
  ["01b-onboarding-2", "mockups/01b-onboarding-2.html"],
  ["01c-onboarding-3", "mockups/01c-onboarding-3.html"],
  ["02-habits", "mockups/02-habits.html"],
  ["02b-habits-empty", "mockups/02b-habits-empty.html"],
  ["02c-no-habits-today", "mockups/02c-no-habits-today.html"],
  ["03-add-habit", "mockups/03-add-habit.html"],
  ["04-stats", "mockups/04-stats.html"],
  ["05-settings", "mockups/05-settings.html"],
  ["06-habits-loading", "mockups/06-habits-loading.html"],
  ["07-habit-actions", "mockups/07-habit-actions.html"],
  ["08-delete-all", "mockups/08-delete-all.html"],
  ["08b-delete-habit", "mockups/08b-delete-habit.html"],
  ["09-completed-snackbar", "mockups/09-completed-snackbar.html"],
];

const store = [
  ["store-1-habits", "store/screenshot-1.html"],
  ["store-2-streak", "store/screenshot-2.html"],
  ["store-3-add", "store/screenshot-3.html"],
  ["store-4-offline", "store/screenshot-4.html"],
];

const pages = [
  ["00-index", "index.html"],
  ["10-components", "mockups/10-components.html"],
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitReady(c) {
  for (let i = 0; i < 80; i++) {
    const { result } = await c.send("Runtime.evaluate", {
      expression:
        "document.readyState === 'complete' && document.fonts.status === 'loaded'",
      returnByValue: true,
    });
    if (result.value === true) return;
    await sleep(100);
  }
  throw new Error("page not ready");
}
const fileUrl = (rel) => "file:///" + path.join(root, rel).replace(/\\/g, "/");

async function connect() {
  const proc = spawn(
    chrome,
    [
      "--headless=new",
      "--disable-gpu",
      "--hide-scrollbars",
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-extensions",
      `--remote-debugging-port=${PORT}`,
      `--user-data-dir=${profile}`,
      "about:blank",
    ],
    { stdio: "ignore" },
  );

  let version;
  for (let i = 0; i < 60; i++) {
    try {
      version = await (await fetch(`http://127.0.0.1:${PORT}/json/version`)).json();
      break;
    } catch {
      await sleep(150);
    }
  }
  if (!version) throw new Error("Chrome did not start");
  return proc;
}

let msgId = 0;
function client(wsUrl) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const pending = new Map();
    const events = new Map();
    ws.onmessage = (e) => {
      const m = JSON.parse(e.data);
      if (m.id && pending.has(m.id)) {
        const { res, rej } = pending.get(m.id);
        pending.delete(m.id);
        m.error ? rej(new Error(JSON.stringify(m.error))) : res(m.result);
      } else if (m.method) {
        (events.get(m.method) || []).forEach((fn) => fn(m.params));
      }
    };
    ws.onerror = () => reject(new Error("ws error"));
    ws.onopen = () =>
      resolve({
        send(method, params = {}) {
          const id = ++msgId;
          ws.send(JSON.stringify({ id, method, params }));
          return new Promise((res, rej) => pending.set(id, { res, rej }));
        },
        once(method, timeout = 15000) {
          return new Promise((res, rej) => {
            const list = events.get(method) || [];
            const timer = setTimeout(() => rej(new Error("timeout " + method)), timeout);
            const fn = (p) => {
              clearTimeout(timer);
              events.set(
                method,
                (events.get(method) || []).filter((f) => f !== fn),
              );
              res(p);
            };
            events.set(method, [...list, fn]);
          });
        },
        close() {
          ws.close();
        },
      });
  });
}

async function openPage(url) {
  const res = await fetch(
    `http://127.0.0.1:${PORT}/json/new?${encodeURIComponent(url)}`,
    { method: "PUT" },
  );
  const target = await res.json();
  const c = await client(target.webSocketDebuggerUrl);
  await c.send("Page.enable");
  await c.send("Runtime.enable");
  return { c, targetId: target.id };
}

const auditScript = `(() => {
  const out = { viewport: [innerWidth, innerHeight], issues: [] };
  const u = document.querySelector('use');
  out.fonts = { status: document.fonts.status, inter: document.fonts.check('16px Inter'), body: getComputedStyle(document.body).fontFamily };
  out.icons = {
    symbols: document.querySelectorAll('symbol').length,
    uses: document.querySelectorAll('use').length,
    firstUseBox: u ? [Math.round(u.getBBox().width), Math.round(u.getBBox().height)] : null
  };
  const phone = document.querySelector('.phone');
  if (phone) {
    const pr = phone.getBoundingClientRect();
    out.phone = { w: pr.width, h: pr.height, scrollH: phone.scrollHeight };
    document.querySelectorAll('.phone *').forEach((el) => {
      const r = el.getBoundingClientRect();
      const cs = getComputedStyle(el);
      if (cs.position === 'fixed') return;
      if (r.width === 0 && r.height === 0) return;
      if (r.right - pr.right > 1.5 || r.left - pr.left < -1.5 || r.bottom - pr.bottom > 1.5) {
        out.issues.push({
          kind: 'outside-phone',
          el: el.tagName.toLowerCase() + '.' + (el.className || '').toString().split(' ').join('.'),
          text: (el.textContent || '').trim().slice(0, 40),
          rect: [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)],
          phone: [Math.round(pr.left), Math.round(pr.top), Math.round(pr.width), Math.round(pr.height)]
        });
      }
      if (el.scrollWidth - el.clientWidth > 2 && cs.overflowX !== 'auto' && cs.overflowX !== 'scroll' && el.clientWidth > 0) {
        out.issues.push({ kind: 'h-overflow', el: el.tagName.toLowerCase() + '.' + (el.className || '').toString().split(' ').join('.') });
      }
    });
    const scrollers = [...document.querySelectorAll('.body--scroll, .screen-scroll')].map((el) => ({
      cls: el.className,
      scrollH: el.scrollHeight,
      clientH: el.clientHeight
    }));
    out.scrollers = scrollers;
  }
  out.rects = {};
  const named = {fab:'.fab', snack:'.snackbar-wrap', footer:'.form-footer', scroll:'.screen-scroll', summary:'.stats-summary', lastStat:'.stats-list .stat-card:last-child', examples:'.empty__examples', cta:'.empty__cta', tabbar:'.tabbar', sheet:'.sheet-wrap', emojis:'.emoji-grid', weekdays:'.weekdays', lastForm:'.form-section:last-child', dialog:'.dialog'};
  Object.entries(named).forEach(([k, sel]) => { const el = document.querySelector(sel); if (el) { const r = el.getBoundingClientRect(); out.rects[k] = [Math.round(r.left), Math.round(r.top), Math.round(r.right), Math.round(r.bottom)]; } });
  const h = document.documentElement.scrollHeight;
  if (h > innerHeight + 1) out.issues.push({ kind: 'page-scroll', pageH: h, viewportH: innerHeight });
  return out;
})()`;

async function shoot(c, outPath, width, height, dsf) {
  await c.send("Emulation.setDeviceMetricsOverride", {
    width,
    height,
    deviceScaleFactor: dsf,
    mobile: true,
  });
  await sleep(250);
  const { data } = await c.send("Page.captureScreenshot", {
    format: "png",
    captureBeyondViewport: false,
  });
  await mkdir(path.dirname(outPath), { recursive: true });
  await writeFile(outPath, Buffer.from(data, "base64"));
}

async function runMocks(list, outDir, mode) {
  await mkdir(outDir, { recursive: true });
  const report = [];
  for (const [name, rel] of list) {
    const { c, targetId } = await openPage(fileUrl(rel));
    await waitReady(c);
    await c.send("Emulation.setDeviceMetricsOverride", {
      width: 360,
      height: 800,
      deviceScaleFactor: 3,
      mobile: true,
    });
    await sleep(400);
    if (mode === "audit") {
      const { result } = await c.send("Runtime.evaluate", {
        expression: auditScript,
        returnByValue: true,
      });
      report.push({ name, ...result.value });
    } else {
      await shoot(c, path.join(outDir, name + ".png"), 360, 800, 3);
    }
    c.close();
    await fetch(`http://127.0.0.1:${PORT}/json/close/${targetId}`);
  }
  return report;
}

async function main() {
  const mode = process.argv[2] || "audit";
  const proc = await connect();
  try {
    if (mode === "audit" || mode === "screens") {
      const report = await runMocks(screens, path.join(root, "exports"), mode);
      if (mode === "audit") {
        console.log(JSON.stringify(report, null, 2));
      } else {
        console.log("rendered screens ->", path.join(root, "exports"));
      }
    }
    if (mode === "pages") {
      const report = [];
      for (const [name, rel] of pages) {
        const { c, targetId } = await openPage(fileUrl(rel));
        await waitReady(c);
        await c.send("Emulation.setDeviceMetricsOverride", {
          width: 1160,
          height: 1600,
          deviceScaleFactor: 1,
          mobile: false,
        });
        await sleep(500);
        const { result } = await c.send("Runtime.evaluate", {
          expression:
            "JSON.stringify({h: document.documentElement.scrollHeight, w: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth, inner: [innerWidth, innerHeight]})",
          returnByValue: true,
        });
        const m = JSON.parse(result.value);
        report.push({ name, ...m });
        await c.send("Emulation.setDeviceMetricsOverride", {
          width: 1160,
          height: Math.min(m.h, 5000),
          deviceScaleFactor: 1,
          mobile: false,
        });
        await sleep(250);
        await shoot(c, path.join(root, "exports", name + ".png"), 1160, Math.min(m.h, 5000), 1);
        c.close();
        await fetch(`http://127.0.0.1:${PORT}/json/close/${targetId}`);
      }
      console.log(JSON.stringify(report, null, 2));
    }
    if (mode === "store") {
      const report = [];
      for (const [name, rel] of store) {
        const { c, targetId } = await openPage(fileUrl(rel));
        await waitReady(c);
        await c.send("Emulation.setDeviceMetricsOverride", {
          width: 1080,
          height: 1920,
          deviceScaleFactor: 1,
          mobile: false,
        });
        await sleep(500);
        const { result } = await c.send("Runtime.evaluate", {
          expression:
            "JSON.stringify({h: document.documentElement.scrollHeight, w: document.documentElement.scrollWidth, inner: [innerWidth, innerHeight]})",
          returnByValue: true,
        });
        report.push({ name, ...JSON.parse(result.value) });
        await shoot(c, path.join(root, "store", name + ".png"), 1080, 1920, 1);
        c.close();
        await fetch(`http://127.0.0.1:${PORT}/json/close/${targetId}`);
      }
      console.log(JSON.stringify(report, null, 2));
    }
  } finally {
    proc.kill();
    await sleep(300);
    await rm(profile, { recursive: true, force: true }).catch(() => {});
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
