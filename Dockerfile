FROM node:18-alpine
WORKDIR /app
RUN apk update && apk upgrade --no-cache

COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --only=production; else npm install --production; fi
COPY . .
ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080
RUN npm install -g npm@10.2.0
CMD ["node", "app.js"]
