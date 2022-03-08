An example Dockerfile for a Java webapp + a few dependencies:

- NodeJS 17.6

## Prerequisites

I assume you have installed Docker and it is running.

See the [Docker website](http://www.docker.io/gettingstarted/#h_installation) for installation instructions.

## Usage

```docker
FROM carlosmarte/alpine3_14_nodejs17_6_base:latest

USER node

WORKDIR /opt/app-root
COPY package*.json ./
COPY node_modules ./node_modules
COPY src ./src
EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bash", "-c", "node ./src/index.js"]
```
