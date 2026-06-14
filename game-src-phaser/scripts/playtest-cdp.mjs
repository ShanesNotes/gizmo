import { spawn } from "node:child_process";
import { mkdir, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_CHROME = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const URL = process.env.MISCHIEF_URL ?? "http://127.0.0.1:5186";
const CHROME = process.env.CHROME_PATH ?? DEFAULT_CHROME;
const PORT = Number(process.env.CDP_PORT ?? 9380);
const WIDTH = Number(process.env.VIEWPORT_WIDTH ?? 1280);
const HEIGHT = Number(process.env.VIEWPORT_HEIGHT ?? 800);
const MOBILE = process.env.MOBILE === "1";
const RUN_MISSION = process.env.RUN_MISSION !== "0";
const PROFILE_DIR = resolve(ROOT, "..", "chrome-profile-mischief-cdp");
const SCREENSHOT = process.env.SCREENSHOT_PATH
  ? resolve(process.env.SCREENSHOT_PATH)
  : resolve(ROOT, "..", "screenshots", RUN_MISSION ? "mischief-playtest-complete.png" : "mischief-smoke.png");

const sleep = (ms) => new Promise((resolveSleep) => setTimeout(resolveSleep, ms));

class CdpClient {
  constructor(url) {
    this.nextId = 1;
    this.pending = new Map();
    this.ws = new WebSocket(url);
    this.ready = new Promise((resolveReady, rejectReady) => {
      this.ws.addEventListener("open", resolveReady, { once: true });
      this.ws.addEventListener("error", rejectReady, { once: true });
    });
    this.ws.addEventListener("message", (event) => this.handleMessage(event));
  }

  handleMessage(event) {
    const message = JSON.parse(String(event.data));
    if (!message.id) return;
    const pending = this.pending.get(message.id);
    if (!pending) return;
    this.pending.delete(message.id);
    clearTimeout(pending.timeout);
    if (message.error) {
      pending.reject(new Error(`${pending.method}: ${message.error.message}`));
      return;
    }
    pending.resolve(message.result ?? {});
  }

  async send(method, params = {}, timeoutMs = 8000) {
    await this.ready;
    const id = this.nextId++;
    const timeout = setTimeout(() => {
      const pending = this.pending.get(id);
      if (!pending) return;
      this.pending.delete(id);
      pending.reject(new Error(`${method}: timed out`));
    }, timeoutMs);
    const promise = new Promise((resolveSend, rejectSend) => {
      this.pending.set(id, { method, resolve: resolveSend, reject: rejectSend, timeout });
    });
    this.ws.send(JSON.stringify({ id, method, params }));
    return promise;
  }

  close() {
    this.ws.close();
  }
}

const fetchJson = async (url, timeoutMs = 8000) => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
    return await response.json();
  } finally {
    clearTimeout(timeout);
  }
};

const waitForJson = async (url, timeoutMs = 12000) => {
  const started = Date.now();
  let lastError;
  while (Date.now() - started < timeoutMs) {
    try {
      return await fetchJson(url, 1200);
    } catch (error) {
      lastError = error;
      await sleep(120);
    }
  }
  throw lastError ?? new Error(`Timed out waiting for ${url}`);
};

const evaluate = async (client, expression) => {
  const response = await client.send("Runtime.evaluate", {
    expression,
    returnByValue: true,
    awaitPromise: true
  });
  if (response.exceptionDetails) {
    throw new Error(response.exceptionDetails.text ?? "Runtime.evaluate failed");
  }
  return response.result?.value;
};

const snap = async (client) => {
  const value = await evaluate(
    client,
    `(() => {
      const node = document.querySelector("#mischief-debug-state");
      return node?.textContent ? JSON.parse(node.textContent) : null;
    })()`
  );
  if (!value?.state) {
    throw new Error("Mischief debug state missing");
  }
  return value;
};

const screenForWorld = (snapshot, worldX, worldY) => {
  const cam = snapshot.camera;
  const rawX = (worldX - cam.scrollX) * cam.zoom;
  const rawY = (worldY - cam.scrollY) * cam.zoom;
  return {
    x: Math.round(Math.max(110, Math.min(cam.width - 110, rawX))),
    y: Math.round(Math.max(120, Math.min(cam.height - 145, rawY)))
  };
};

const click = async (client, point) => {
  await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: point.x, y: point.y });
  await client.send("Input.dispatchMouseEvent", {
    type: "mousePressed",
    x: point.x,
    y: point.y,
    button: "left",
    buttons: 1,
    clickCount: 1
  });
  await sleep(20);
  await client.send("Input.dispatchMouseEvent", {
    type: "mouseReleased",
    x: point.x,
    y: point.y,
    button: "left",
    buttons: 0,
    clickCount: 1
  });
};

const pressAction = async (client) => {
  await client.send("Input.dispatchKeyEvent", {
    type: "keyDown",
    key: " ",
    code: "Space",
    windowsVirtualKeyCode: 32,
    nativeVirtualKeyCode: 32
  });
  await sleep(45);
  await client.send("Input.dispatchKeyEvent", {
    type: "keyUp",
    key: " ",
    code: "Space",
    windowsVirtualKeyCode: 32,
    nativeVirtualKeyCode: 32
  });
  await sleep(310);
};

const goTo = async (client, worldX, worldY, radius, label, log) => {
  for (let attempt = 0; attempt < 85; attempt += 1) {
    const snapshot = await snap(client);
    const player = snapshot.state.player;
    const distance = Math.hypot(player.x - worldX, player.y - worldY);
    if (distance <= radius || snapshot.state.phase === "complete") return true;
    await click(client, screenForWorld(snapshot, worldX, worldY));
    await sleep(210);
  }

  const snapshot = await snap(client);
  log.push({
    type: "travel-timeout",
    label,
    distance: Math.round(Math.hypot(snapshot.state.player.x - worldX, snapshot.state.player.y - worldY)),
    player: snapshot.state.player
  });
  return false;
};

const collectParts = async (client, log) => {
  for (let loop = 0; loop < 5; loop += 1) {
    const state = (await snap(client)).state;
    const part = state.parts.find((candidate) => candidate.status === "ready");
    if (!part) return;
    await goTo(client, part.x, part.y, 70, part.id, log);
    await sleep(360);
    const after = (await snap(client)).state;
    const current = after.parts.find((candidate) => candidate.id === part.id);
    log.push({
      type: current?.status === "collected" ? "part" : "part-nochange",
      id: part.id,
      status: current?.status,
      partsCollected: after.partsCollected,
      invention: after.player.invention
    });
  }
};

const blastNextAsteroid = async (client, log) => {
  const state = (await snap(client)).state;
  const asteroid = state.asteroids
    .filter((candidate) => candidate.status === "incoming")
    .sort((a, b) => Math.abs(state.player.x - a.x) + a.y * 0.2 - (Math.abs(state.player.x - b.x) + b.y * 0.2))[0];
  if (!asteroid) return false;
  await goTo(client, asteroid.x, Math.min(870, asteroid.y + 410), 110, asteroid.id, log);
  const before = (await snap(client)).state;
  await pressAction(client);
  const after = (await snap(client)).state;
  log.push({
    type: "blast-step",
    target: asteroid.id,
    blastedAsteroids: after.blastedAsteroids,
    shield: after.shield,
    activeInvention: after.player.invention,
    incoming: after.asteroids.filter((candidate) => candidate.status === "incoming").length,
    beforeMessage: before.message,
    message: after.message
  });
  return true;
};

const main = async () => {
  await mkdir(dirname(SCREENSHOT), { recursive: true });
  await rm(PROFILE_DIR, { recursive: true, force: true });
  await mkdir(PROFILE_DIR, { recursive: true });

  const chrome = spawn(CHROME, [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--mute-audio",
    "--no-first-run",
    "--no-default-browser-check",
    "--remote-allow-origins=*",
    `--remote-debugging-port=${PORT}`,
    `--user-data-dir=${PROFILE_DIR}`,
    `--window-size=${WIDTH},${HEIGHT}`,
    "about:blank"
  ]);

  const fail = new Promise((_, reject) => {
    chrome.once("error", reject);
    chrome.once("exit", (code) => {
      if (code !== null && code !== 0) reject(new Error(`Chrome exited with code ${code}`));
    });
  });

  let client;
  try {
    await Promise.race([waitForJson(`http://127.0.0.1:${PORT}/json/version`), fail]);
    const targets = await fetchJson(`http://127.0.0.1:${PORT}/json/list`);
    const target = targets.find((candidate) => candidate.type === "page");
    client = new CdpClient(target.webSocketDebuggerUrl);
    await client.ready;
    await client.send("Page.enable");
    await client.send("Runtime.enable");
    await client.send("Log.enable");
    await client.send("Emulation.setDeviceMetricsOverride", {
      width: WIDTH,
      height: HEIGHT,
      deviceScaleFactor: MOBILE ? 2 : 1,
      mobile: MOBILE
    });
    if (MOBILE) {
      await client.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 });
    }
    await client.send("Page.navigate", { url: URL });

    const started = Date.now();
    while (Date.now() - started < 12000) {
      const ready = await evaluate(client, `Boolean(document.querySelector("#mischief-debug-state")?.textContent)`);
      if (ready) break;
      await sleep(100);
    }

    if (!RUN_MISSION) {
      await sleep(700);
      const smoke = await snap(client);
      const media = await evaluate(
        client,
        `({
          coarse: matchMedia("(pointer: coarse)").matches,
          hoverNone: matchMedia("(hover: none)").matches,
          width: innerWidth,
          height: innerHeight,
          touchVisible: getComputedStyle(document.querySelector(".touch-cluster")).display
        })`
      );
      const screenshot = await client.send("Page.captureScreenshot", { format: "png", fromSurface: true }, 12000);
      await writeFile(SCREENSHOT, Buffer.from(screenshot.data, "base64"));
      console.log(
        JSON.stringify(
          {
            phase: smoke.state.phase,
            canvasReady: true,
            blastedAsteroids: smoke.state.blastedAsteroids,
            partsCollected: smoke.state.partsCollected,
            shield: smoke.state.shield,
            media,
            screenshot: SCREENSHOT
          },
          null,
          2
        )
      );
      return;
    }

    await evaluate(client, `document.querySelector("canvas")?.focus?.()`);
    await click(client, { x: Math.round(WIDTH / 2), y: Math.round(HEIGHT / 2) });

    const log = [];
    await collectParts(client, log);
    for (let loop = 0; loop < 40; loop += 1) {
      const state = (await snap(client)).state;
      if (state.phase === "complete") break;
      const moved = await blastNextAsteroid(client, log);
      if (!moved) break;
    }

    await sleep(750);
    const finalSnapshot = await snap(client);
    const screenshot = await client.send("Page.captureScreenshot", { format: "png", fromSurface: true }, 12000);
    await writeFile(SCREENSHOT, Buffer.from(screenshot.data, "base64"));

    const final = finalSnapshot.state;
    console.log(
      JSON.stringify(
        {
          phase: final.phase,
          blastedAsteroids: final.blastedAsteroids,
          goalAsteroids: final.goalAsteroids,
          partsCollected: final.partsCollected,
          goalParts: final.goalParts,
          shield: final.shield,
          elapsed: Number(final.elapsed.toFixed(1)),
          asteroids: final.asteroids.map((asteroid) => ({ id: asteroid.id, status: asteroid.status, hp: asteroid.hp })),
          logCount: log.length,
          logTail: log.slice(-9),
          screenshot: SCREENSHOT
        },
        null,
        2
      )
    );

    if (final.phase !== "complete" || final.blastedAsteroids !== final.goalAsteroids) {
      process.exitCode = 1;
    }
  } finally {
    client?.close();
    chrome.kill();
  }
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
