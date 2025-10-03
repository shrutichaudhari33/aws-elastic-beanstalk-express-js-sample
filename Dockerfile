# Runtime must also be Node 16 per assignment
FROM node:16-alpine

WORKDIR /app

# Install only production deps
COPY package*.json ./
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm install --omit=dev; \
    fi

# App files
COPY . .

ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

CMD ["node", "app.js"]
