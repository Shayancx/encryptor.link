import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
  ],
  resolve: {
    extensions: ['.mjs', '.js', '.jsx', '.ts', '.tsx', '.json'],
    alias: {
      '@': path.resolve(__dirname, './app/javascript'),
    },
  },
  server: {
    host: 'localhost',
    port: 3036,
    strictPort: true,
    hmr: {
      protocol: 'ws',
      host: 'localhost',
      port: 3036,
    },
  },
})
