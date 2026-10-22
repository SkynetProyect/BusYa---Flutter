# syntax=docker/dockerfile:1

# ---------- Etapa 1: dependencias de produccion ----------
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# ---------- Etapa 2: imagen final ----------
FROM node:22-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

# No correr como root
USER node

# Sin puerto expuesto: es un worker que solo hace conexiones salientes.
# `node` directo (no `npm start`) para que SIGTERM llegue al proceso
# y se haga el cierre limpio (snapshot final + cierre del canal).
CMD ["node", "src/index.js"]
