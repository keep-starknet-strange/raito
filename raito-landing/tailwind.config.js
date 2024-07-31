/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      fontFamily: {
        electrolize: ["Electrolize", "sans-serif"],
      },
      colors: {
        yellow: {
          500: "#FFD700",
        },
      },
    },
  },
  plugins: [],
};
