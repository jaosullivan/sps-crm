/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        sps: {
          green: '#0B6E4F',
          'green-dark': '#085A40',
          'green-light': '#E8F5F0',
          gold: '#C4A35A',
          cream: '#F7F5F0',
          ink: '#1A1A1A',
          muted: '#6B7280',
          border: '#E5E7EB',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
