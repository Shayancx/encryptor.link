import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [
    react(),
    RubyPlugin(),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./app/javascript"),
    },
  },
  server: {
    host: '127.0.0.1',
    port: 3036,
    strictPort: true,
    cors: true,
    hmr: {
      protocol: 'ws',
      host: '127.0.0.1',
      port: 3036,
    },
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom'],
  },
})
