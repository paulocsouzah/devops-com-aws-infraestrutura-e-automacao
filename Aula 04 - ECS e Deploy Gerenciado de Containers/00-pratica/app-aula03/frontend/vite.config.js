import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Em "npm run dev" (fora de container), o Vite serve o frontend sozinho
// na porta 5173. O proxy abaixo redireciona "/api" para a API rodando
// localmente na porta 4000, so para esse cenario de desenvolvimento
// rapido. Dentro dos containers (docker compose / EC2), quem faz esse
// redirecionamento e o nginx.conf do proprio container do frontend.
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:4000',
    },
  },
});
