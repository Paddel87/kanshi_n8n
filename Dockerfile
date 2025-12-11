FROM n8nio/n8n:latest

USER root

# Install FFmpeg für mögliche Medienoperationen
RUN apk add --no-cache ffmpeg

USER node
