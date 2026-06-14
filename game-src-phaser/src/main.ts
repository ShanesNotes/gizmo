import Phaser from "phaser";
import { BootScene } from "./phaser/BootScene";
import { MischiefScene } from "./phaser/MischiefScene";
import { createHud } from "./ui/hud";
import "./styles.css";

const root = document.querySelector<HTMLDivElement>("#game-root");

if (!root) {
  throw new Error("Missing #game-root");
}

const hud = createHud(document.body);

new Phaser.Game({
  type: Phaser.AUTO,
  parent: root,
  backgroundColor: "#f6edd8",
  scale: {
    mode: Phaser.Scale.RESIZE,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: 1280,
    height: 720
  },
  render: {
    antialias: true,
    pixelArt: false
  },
  scene: [new BootScene(), new MischiefScene(hud)]
});
