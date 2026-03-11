# ==========================================
# STAGE 1: Builder (Compiling & Downloading)
# ==========================================
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install only the tools needed to build the venv and download assets
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-full python3-venv python3-dev build-essential gcc g++ libffi-dev \
    wget curl unzip git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 1. Build the Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Download and extract fonts to a staging directory
WORKDIR /build-fonts
RUN git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git \
    && curl -sSL https://github.com/google/fonts/archive/main.zip -o gfonts.zip \
    && unzip -q gfonts.zip \
    && mkdir -p /staging/fonts \
    && cp -R nerd-fonts/patched-fonts/* /staging/fonts/ 2>/dev/null || true \
    && cp -R fonts-main/ofl/* /staging/fonts/ 2>/dev/null || true \
    && cp -R fonts-main/apache/* /staging/fonts/ 2>/dev/null || true \
    && cp -R fonts-main/ufl/* /staging/fonts/ 2>/dev/null || true

# 3. Download the latest PlantUML
RUN wget "https://sourceforge.net/projects/plantuml/files/plantuml.jar" -O /staging/plantuml.jar --no-check-certificate

# 4. Install d2 binary, as this is used in e.g. the 'terrastruct.d2' vscode extension
RUN curl -fsSL https://d2lang.com/install.sh | sh -s --

# ==========================================
# STAGE 2: Final Runtime Environment
# ==========================================
FROM ubuntu:24.04
LABEL maintainer="Jens Frey <jens.frey@coffeecrew.org>" Version="2026-03-11"

# Setup Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}" \
    TEXMFCACHE=/var/lib/texmf \
    LUAOTFLOAD_CACHE=/var/lib/texmf/luatex-cache \
    LC_ALL=C \
    DRAWIO_BINARY=/usr/local/bin/drawio-headless
    
ARG DRAWIO_VER=29.5.2

COPY .bashrc /root/.bashrc
COPY default.template /etc/nginx/templates/default.template

# 1. Install System and Runtime Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget python3-minimal aria2 \
    graphviz imagemagick make git git-lfs \
    openjdk-25-jdk-headless plantuml docutils \
    latexmk xindy lmodern texlive-full \
    texlive-fonts-extra texlive-fonts-recommended texlive-font-utils \
    ghostscript dvipng qpdf tikzit qtikz \
    nginx xvfb fontconfig ca-certificates \
    # Draw.io dependencies
    libgtk-3-0 libnss3 libxss1 libasound2t64 libgbm1 libx11-xcb1 \
    libxcomposite1 libxrandr2 libxdamage1 libxi6 libxtst6 \
    libglib2.0-0 libxext6 libxfixes3 libdrm2 libxshmfence1 \
    libpangocairo-1.0-0 fonts-liberation libgl1 libsecret-1-0 \
    libappindicator3-1 libnotify4 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 2. Install Draw.io
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VER}/drawio-amd64-${DRAWIO_VER}.deb"; \
    elif [ "$ARCH" = "arm64" ]; then \
        URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VER}/drawio-arm64-${DRAWIO_VER}.deb"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -q -O /tmp/drawio.deb "$URL" && \
    apt-get update && apt-get install -y --no-install-recommends /tmp/drawio.deb && \
    apt-get clean && rm -f /tmp/drawio.deb && rm -rf /var/lib/apt/lists/*

# 3. Create Draw.io headless wrapper
RUN printf '#!/bin/sh\nexec xvfb-run -a -s "-screen 0 1920x1080x24" drawio --disable-dev-shm-usage --disable-gpu --no-sandbox "$@"\n' \
    > /usr/local/bin/drawio-headless && chmod +x /usr/local/bin/drawio-headless

# 4. Copy compiled assets from Builder Stage
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /staging/fonts /usr/share/fonts/truetype/custom
COPY --from=builder /staging/plantuml.jar /usr/local/plantuml/plantuml.jar
COPY --from=builder /usr/local/bin/d2 /usr/local/bin/d2

# 5. Final Configurations (PlantUML symlink & Font Cache)
RUN ln -sf /usr/local/plantuml/plantuml.jar /usr/share/plantuml/plantuml.jar && \
    fc-cache -f && luaotfload-tool --update --force && \
    mkdir -p /var/lib/texmf/luatex-cache && \
    chmod -R 777 /var/lib/texmf/luatex-cache

WORKDIR /workspaces