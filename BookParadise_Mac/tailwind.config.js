/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        mac: {
          bg: '#16161a',
          surface: '#1e1e24',
          subtle: '#26262e',
          border: 'rgba(255, 255, 255, 0.08)',
          accent: '#10b981', // Изумрудный BookParadise
          accentHover: '#059669',
        }
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', '"SF Pro Display"', '"SF Pro Text"', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        'mac-window': '0 24px 60px rgba(0, 0, 0, 0.55), 0 0 1px rgba(255, 255, 255, 0.1)',
        'mac-modal': '0 30px 80px rgba(0, 0, 0, 0.65), 0 0 1px rgba(255, 255, 255, 0.15)',
        'mac-card': '0 4px 20px rgba(0, 0, 0, 0.25)',
        'mac-card-hover': '0 12px 30px rgba(0, 0, 0, 0.45)',
      }
    },
  },
  plugins: [],
}
