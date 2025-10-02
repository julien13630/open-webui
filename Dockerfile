# ---------- Frontend build ----------
FROM node:22-alpine3.20 AS build

# Augmente la mémoire Node
ENV NODE_OPTIONS="--max-old-space-size=4096"

WORKDIR /app

# Installer git pour versioning
RUN apk add --no-cache git

# Copier package.json et installer deps
COPY package.json package-lock.json ./
RUN npm ci --force

# Copier le reste et build
COPY . .
RUN npm run build

# ---------- Backend Python ----------
FROM python:3.11-slim-bookworm AS base

WORKDIR /app/backend

# Variables d'environnement
ENV ENV=prod \
    PORT=8080 \
    WEBUI_SECRET_KEY="" \
    SCARF_NO_ANALYTICS=true \
    DO_NOT_TRACK=true \
    ANONYMIZED_TELEMETRY=false

# Installer dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential curl ffmpeg libsm6 libxext6 \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier requirements et installer Python deps
COPY ./backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copier le backend et le frontend build
COPY --from=build /app/build /app/build
COPY ./backend .

# Exposer le port attendu par Cloud Run
EXPOSE 8080

# Copier start.sh et donner les droits d’exécution
COPY start.sh /app/backend/start.sh
RUN chmod +x /app/backend/start.sh

# Utiliser un user non-root si besoin
ARG UID=0
ARG GID=0
RUN if [ $UID -ne 0 ]; then \
        if [ $GID -ne 0 ]; then addgroup --gid $GID app; fi; \
        adduser --uid $UID --gid $GID --disabled-password --no-create-home app; \
    fi
USER $UID:$GID

# Commande finale
CMD ["/app/backend/start.sh"]