# Typescript .ts -> js

#multistage build

FROM ubuntu as build

RUN apt-get update
RUN apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get upgrade -y
RUN apt-get install -y nodejs
RUN apt-get install typescript

WORKDIR /app     #after this all will be created in a working directory name app

COPY package.json package.json
COPY package-lock.json package-lock.json

RUN npm install
RUN tsc -p . # build

FROM ubuntu as runner