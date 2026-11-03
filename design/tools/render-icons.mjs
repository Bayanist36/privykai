/*
 * Export final app icon PNGs at exact sizes.
 * Usage: node tools/render-icons.mjs
 */
import { spawn } from "node:child_process";
import { mkdir, writeFile, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const project = path.resolve(root, "..");
const chrome =
  process.env.CHROME_PATH ||
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9444;
const profile = path.join(process.env.TEMP || ".", "icon-render-" + Date.now());

const jobs = [
  ["assets/icon-export.html", "design/assets/app-icon-512.png", 512, false],
  ["assets/icon-export.html", "design/assets/app-icon-1024.png", 1024, false],
  ["assets/icon-export.html", "android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48, false],
  ["assets/icon-export.html", "android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72, false],
  ["assets/icon-export.html", "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96, false],
  ["assets/icon-export.html", "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144, false],
  ["assets/icon-export.html", "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192, false],
  ["assets/icon-foreground-export.html", "android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png", 108, true],
  ["assets/icon-foreground-export.html", "android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png", 162, true],
  ["assets/icon-foreground-export.html", "android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png", 216, true],
  ["assets/icon-foreground-export.html", "android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png", 324, true],
  ["assets/icon-foreground-export.html", "android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png", 432, true],
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

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

async function main() {
  const proc = await connect();
  try {
    let current = null;
    let c = null;
    for (const [rel, out, size, transparent] of jobs) {
      if (current !== rel) {
        if (c) c.close();
        const url = "file:///" + path.join(root, rel).replace(/\\/g, "/");
        const res = await fetch(
          `http://127.0.0.1:${PORT}/json/new?${encodeURIComponent(url)}`,
          { method: "PUT" },
        );
        const target = await res.json();
        c = await client(target.webSocketDebuggerUrl);
        await c.send("Page.enable");
        await c.send("Runtime.enable");
        await c.send("Emulation.setDefaultBackgroundColorOverride", {
          color: transparent
            ? { r: 0, g: 0, b: 0, a: 0 }
            : { r: 244, g: 241, b: 233, a: 1 },
        });
        await sleep(350);
        current = rel;
      }
      await c.send("Emulation.setDeviceMetricsOverride", {
        width: size,
        height: size,
        deviceScaleFactor: 1,
        mobile: false,
      });
      await sleep(120);
      const { data } = await c.send("Page.captureScreenshot", {
        format: "png",
        captureBeyondViewport: false,
        omitBackground: transparent,
      });
      const target = path.join(project, out);
      await mkdir(path.dirname(target), { recursive: true });
      await writeFile(target, Buffer.from(data, "base64"));
      console.log(`${out} ${size}x${size}`);
    }
    if (c) c.close();
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
