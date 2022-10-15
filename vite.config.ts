import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import viteCompression from 'vite-plugin-compression'

export default defineConfig({
  plugins: [
    RubyPlugin(), viteCompression()
  ],
})
