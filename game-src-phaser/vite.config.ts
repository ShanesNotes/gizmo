import { defineConfig } from "vite";

export default defineConfig({
  base: "./",
  build: {
    emptyOutDir: false
  },
  server: {
    host: "127.0.0.1",
    port: 5186
  },
  preview: {
    host: "127.0.0.1",
    port: 4186
  }
});
