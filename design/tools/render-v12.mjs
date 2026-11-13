/*
 * Render v1.2 concepts and home-screen widget mockups.
 * Usage:
 *   node tools/render-v12.mjs screens
 *   node tools/render-v12.mjs widgets
 *   node tools/render-v12.mjs all
 * Requires Node 22+ and Google Chrome.
 */
import { spawn } from "node:child_process";
import { mkdir, writeFile, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const chrome =
  process.env.CHROME_PATH ||
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9334;
const profile = path.join(process.env.TEMP || ".", "design-v12-chrome-" + Date.now());

const screens = [
  ["v12-01-stats", "mockups/v12-01-stats.html", 0],
  ["v12-01b-stats-lower", "mockups/v12-01-stats.html", 500],
  ["v12-02-quiet-hours", "mockups/v12-02-quiet-hours.html", 0],
  ["v12-03-goal", "mockups/v12-03-goal.html", 0],
  ["v12-04-onboarding", "mockups/v12-04-onboarding.html", 0],
];

const widgets = [
  ["widgets-2x1-overview", "widgets/widget-2x1.html", 900],
  ["widgets-4x2-overview", "widgets/widget-4x2.html", 820],
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitReady(c) {
  for (let i = 0; i < 100; i++) {
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

async function shoot(c, outPath, width, height, dsf, clip, omitBackground = false, resize = true) {
  if (resize) {
    await c.send("Emulation.setDeviceMetricsOverride", {
      width,
      height,
      deviceScaleFactor: dsf,
      mobile: false,
    });
    await sleep(250);
  }
  const params = {
    format: "png",
    captureBeyondViewport: false,
    omitBackground,
  };
  if (clip) params.clip = clip;
  const { data } = await c.send("Page.captureScreenshot", params);
  await mkdir(path.dirname(outPath), { recursive: true });
  await writeFile(outPath, Buffer.from(data, "base64"));
}

async function renderScreens() {
  for (const [name, rel, scroll] of screens) {
    const { c, targetId } = await openPage(fileUrl(rel));
    await waitReady(c);
    await c.send("Emulation.setDeviceMetricsOverride", {
      width: 360,
      height: 800,
      deviceScaleFactor: 3,
      mobile: true,
    });
    await sleep(400);
    if (scroll > 0) {
      await c.send("Runtime.evaluate", {
        expression: `(() => { const el = document.querySelector('.body--scroll'); if (el) el.scrollTop = ${scroll}; })()`,
      });
      await sleep(200);
    }
    const audit = await c.send("Runtime.evaluate", {
      expression: `(() => {
        const scroller = document.querySelector('.body--scroll');
        const phone = document.querySelector('.phone');
        const over = [...document.querySelectorAll('.phone *')].filter((el) => {
          const r = el.getBoundingClientRect();
          const p = phone.getBoundingClientRect();
          return r.width > 0 && (r.right - p.right > 1.5 || r.left - p.left < -1.5);
        }).map((el) => el.className || el.tagName);
        const rect = (sel) => {
          const el = document.querySelector(sel);
          if (!el) return null;
          const r = el.getBoundingClientRect();
          return [Math.round(r.top), Math.round(r.bottom), Math.round(r.height)];
        };
        return {
          scrollH: scroller ? scroller.scrollHeight : null,
          clientH: scroller ? scroller.clientHeight : null,
          over: over.slice(0, 8),
          rects: {
            footer: rect('.form-footer'),
            onbFooter: rect('.onb-footer'),
            apply: rect('.quiet-apply'),
            goalPanel: rect('.goal-panel'),
            preview: rect('.goal-card'),
            chart: rect('.chart-card'),
            heatmap: rect('.heatmap-card'),
            statsList: rect('.stats-list')
          },
          fit: ['.stats-summary', '.chart-card', '.heatmap-card', '.goal-card', '.quiet-times', '.timeline', '.mode-seg', '.onb-option'].map((sel) => {
            const el = document.querySelector(sel);
            if (!el) return [sel, null];
            return [sel, el.scrollWidth, el.clientWidth, el.scrollHeight, el.clientHeight];
          })
        };
      })()`,
      returnByValue: true,
    });
    await shoot(c, path.join(root, "exports", name + ".png"), 360, 800, 3);
    console.log(name, JSON.stringify(audit.result.value));
    c.close();
    await fetch(`http://127.0.0.1:${PORT}/json/close/${targetId}`);
  }
}

async function renderWidgets() {
  for (const [name, rel, width] of widgets) {
    const { c, targetId } = await openPage(fileUrl(rel));
    await waitReady(c);
    await c.send("Emulation.setDeviceMetricsOverride", {
      width,
      height: 1200,
      deviceScaleFactor: 2,
      mobile: false,
    });
    await sleep(500);
    const { result } = await c.send("Runtime.evaluate", {
      expression: `JSON.stringify({ h: Math.ceil(document.body.getBoundingClientRect().height), w: Math.ceil(document.body.getBoundingClientRect().width) })`,
      returnByValue: true,
    });
    const size = JSON.parse(result.value);
    const { result: audit } = await c.send("Runtime.evaluate", {
      expression: `JSON.stringify([...document.querySelectorAll('.w')].map((el) => {
        const r = el.getBoundingClientRect();
        const outside = [...el.querySelectorAll('*')].filter((child) => {
          const c = child.getBoundingClientRect();
          return c.width > 0 && (c.right - r.right > 1.5 || c.left - r.left < -1.5 || c.bottom - r.bottom > 1.5 || c.top - r.top < -1.5);
        }).map((child) => child.className.toString() || child.tagName);
        return {
          shot: el.dataset.shot || el.className,
          box: [Math.round(r.width), Math.round(r.height)],
          scroll: [el.scrollWidth, el.scrollHeight],
          outside: outside.slice(0, 6)
        };
      }))`,
      returnByValue: true,
    });
    console.log(name, JSON.stringify(JSON.parse(audit.value)));
    await shoot(
      c,
      path.join(root, "widgets", "exports", name + ".png"),
      width,
      Math.min(size.h, 5000),
      2,
    );

    // Exact 3x crops of the recommended variant. Transparent corners.
    await c.send("Runtime.evaluate", { expression: "window.scrollTo(0, 0)" });
    await c.send("Emulation.setDefaultBackgroundColorOverride", {
      color: { r: 0, g: 0, b: 0, a: 0 },
    });
    await c.send("Emulation.setDeviceMetricsOverride", {
      width,
      height: Math.max(size.h, 1200),
      deviceScaleFactor: 1,
      mobile: false,
    });
    await sleep(250);

    const { result: shots } = await c.send("Runtime.evaluate", {
      expression: `JSON.stringify([...document.querySelectorAll('[data-shot]')].map((el) => {
        const r = el.getBoundingClientRect();
        return { id: el.dataset.shot, x: r.left + window.scrollX, y: r.top + window.scrollY, w: r.width, h: r.height };
      }))`,
      returnByValue: true,
    });
    for (const shot of JSON.parse(shots.value)) {
      console.log(JSON.stringify(shot));
      await shoot(
        c,
        path.join(root, "widgets", "exports", shot.id + ".png"),
        1,
        1,
        1,
        {
          x: shot.x,
          y: shot.y,
          width: shot.w,
          height: shot.h,
          scale: 3,
        },
        true,
        false,
      );
      console.log(shot.id, `${shot.w * 3}x${shot.h * 3}`);
    }
    await c.send("Emulation.setDefaultBackgroundColorOverride", {});
    c.close();
    await fetch(`http://127.0.0.1:${PORT}/json/close/${targetId}`);
  }
}

async function main() {
  const mode = process.argv[2] || "all";
  const proc = await connect();
  try {
    if (mode === "screens" || mode === "all") await renderScreens();
    if (mode === "widgets" || mode === "all") await renderWidgets();
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
