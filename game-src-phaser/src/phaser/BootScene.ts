import Phaser from "phaser";
import { createTextures } from "./createTextures";
import { preloadGameArt } from "./loadGameArt";
import { preloadTitleArt } from "./titleArt";

export class BootScene extends Phaser.Scene {
  constructor() {
    super("BootScene");
  }

  preload() {
    preloadTitleArt(this);
    preloadGameArt(this);
    createTextures(this);
  }

  create() {
    this.scene.start("MischiefScene");
  }
}
