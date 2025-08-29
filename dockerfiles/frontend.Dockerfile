FROM node:20-alpine AS deps
WORKDIR /app
# Install deps using the frontend package files
COPY frontend/package*.json ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
# Bring the frontend source into the build context
COPY frontend/ ./
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
# Copy the built app and runtime files
COPY --from=builder /app ./
CMD ["npm", "run", "start"]


