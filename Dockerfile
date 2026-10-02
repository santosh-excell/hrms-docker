# syntax=docker/dockerfile:1

# ---- Build stage ----
# The output is static files, so always build on the host's native architecture
# (avoids slow emulation when the image is built for another --platform)
FROM --platform=$BUILDPLATFORM node:20-alpine AS build
WORKDIR /app

# Install dependencies first so this layer is cached until the lockfile changes
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm i --legacy-peer-deps --no-audit --no-fund

COPY . .

# Angular build configuration from angular.json: production | development | local
ARG CONFIGURATION=production
ENV NG_CLI_ANALYTICS=false
RUN npx ng build --configuration "$CONFIGURATION"

# ---- Runtime stage ----
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/master/browser /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
