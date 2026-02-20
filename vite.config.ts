import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { compression } from 'vite-plugin-compression2'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    compression(), // Defaults to gzip and brotli
  ],
})
