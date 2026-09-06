/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        sps: {
          green: '#025C23',
          'green-dark': '#014a1c',
          'green-body': '#418458',
          'green-sage': '#81AD8E',
          'green-pale': '#C0D5C3',
          'green-light': '#E8F3EB',
          orange: '#F58426',
          gold: '#F58426',
          cream: '#FFFDF8',
          ink: '#111111',
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
