FROM docker.esf.fangdd.net/fdd-ci:latest as builder
WORKDIR /app
COPY package.json .
COPY package-lock.json .
COPY angular.json .
RUN npm i && mkdir -p dist
COPY . .
RUN pwd && ls -ltr && npm run build

FROM nginx
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
