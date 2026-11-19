FROM node:latest
ADD . /juice-shop
WORKDIR /juice-shop
RUN npm install
ENV SESSION_SECRET=cambiame-123456
EXPOSE 22 3000
CMD npm start
