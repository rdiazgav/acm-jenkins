FROM node:18-alpine
WORKDIR /opt/app

COPY package*.json ./

RUN npm install --omit=dev

COPY . .

EXPOSE 3000
USER node
CMD ["node", "app.js"]
