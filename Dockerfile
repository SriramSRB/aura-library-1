FROM node:20
WORKDIR /aura-library
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3000
CMD [ "node", "server.js" ]