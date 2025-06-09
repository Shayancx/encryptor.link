import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [
    react({
      include: "**/*.{jsx,tsx}",
    }),
    RubyPlugin(),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./app/javascript"),
    },
  },
  server: {
    host: 'localhost',
    port: 3036,
    strictPort: true,
    cors: {
      origin: ["http://localhost:3000", "http://127.0.0.1:3000"],
      credentials: true,
    },
    hmr: {
      host: 'localhost',
      port: 3036,
    },
  },
  build: {
    sourcemap: true,
    outDir: 'public/vite',
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
  esbuild: {
    jsx: 'automatic',
  },
})
