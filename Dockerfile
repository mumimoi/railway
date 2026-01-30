FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Basic tools + SSH + Python untuk web server "Hello World"
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    openssh-server \
    python3 \
    tini \
  && rm -rf /var/lib/apt/lists/*

# Install cloudflared dari repo resmi Cloudflare (APT)
# (mengikuti instruksi pkg.cloudflare.com)
RUN mkdir -p --mode=0755 /usr/share/keyrings \
  && curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
     | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null \
  && echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
     > /etc/apt/sources.list.d/cloudflared.list \
  && apt-get update && apt-get install -y cloudflared \
  && rm -rf /var/lib/apt/lists/*
# Referensi instruksi repo/resmi: 1

# Siapkan folder sshd + HTML
RUN mkdir -p /run/sshd /var/www \
  && printf "Hello World\n" > /var/www/index.html \
  && mkdir -p /etc/ssh/sshd_config.d \
  && printf "PermitRootLogin yes\nPasswordAuthentication yes\n" \
     > /etc/ssh/sshd_config.d/99-root-password.conf

EXPOSE 22 6080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/entrypoint.sh"]
