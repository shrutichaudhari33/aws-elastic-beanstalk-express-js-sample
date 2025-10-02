FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --only=production; else npm install --production; fi

COPY . .
ENV PORT=8080
EXPOSE 8080
CMD ["node", "app.js"]
