FROM debian:trixie-slim
WORKDIR /app

# Standard/Mono edition selection
ARG EDITION=
# Options: "_mono" or "" (for standard)

ARG VERSION=4.7.1
ARG VERSION_NAME=${VERSION}-stable${EDITION}
ARG BASE_URL=https://github.com/godotengine/godot-builds/releases/download/${VERSION}-stable

ENV EDITION=${EDITION} \
    GODOT_VERSION=${VERSION}

RUN if [ "${EDITION}" = "_mono" ] || [ "${EDITION}" = "" ] ; then \
      echo "Using edition: ${EDITION}"; \
    else \
      echo "Invalid EDITION value: ${EDITION}. Use either '_mono' or '' (empty) for standard edition." && exit 1; \
    fi

VOLUME [ "/app" ]

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    wget \
    ca-certificates \
    libx11-6 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxi6 \
    libgl1 \
    libfontconfig1 \
    xz-utils \
    zstd && \
    rm -rf /var/lib/apt/lists/*

# Download Godot binary
RUN export dpkgArch=$(dpkg --print-architecture) && echo "ARCH=$dpkgArch" && \
    if [ "${EDITION}" = "_mono" ]; then \
        case "$dpkgArch" in \
            amd64) GODOT_FILE="Godot_v${VERSION_NAME}_linux_x86_64.zip" ;; \
            arm64) GODOT_FILE="Godot_v${VERSION_NAME}_linux_arm64.zip" ;; \
            i386)  GODOT_FILE="Godot_v${VERSION_NAME}_linux_x86_32.zip" ;; \
            armhf) GODOT_FILE="Godot_v${VERSION_NAME}_linux_arm32.zip" ;; \
            *) echo "No compatible architecture: ${dpkgArch}" && exit 1 ;; \
        esac; \
    else \
        case "$dpkgArch" in \
            amd64) GODOT_FILE="Godot_v${VERSION_NAME}_linux.x86_64.zip" ;; \
            arm64) GODOT_FILE="Godot_v${VERSION_NAME}_linux.arm64.zip" ;; \
            i386)  GODOT_FILE="Godot_v${VERSION_NAME}_linux.x86_32.zip" ;; \
            armhf) GODOT_FILE="Godot_v${VERSION_NAME}_linux.arm32.zip" ;; \
            *) echo "No compatible architecture: ${dpkgArch}" && exit 1 ;; \
        esac; \
    fi && \
    echo "Downloading: ${BASE_URL}/${GODOT_FILE}" && \
    wget -q -O godot.zip "${BASE_URL}/${GODOT_FILE}"

RUN unzip -q godot.zip && \
    rm godot.zip && \
    chmod +x Godot* && \
    mv -v Godot* /usr/local/bin/godot

# Download export templates
RUN if [ "${EDITION}" = "_mono" ]; then \
        TEMPLATES_DIR="${VERSION}.stable.mono"; \
    else \
        TEMPLATES_DIR="${VERSION}.stable"; \
    fi && \
    echo "Downloading: ${BASE_URL}/Godot_v${VERSION_NAME}_export_templates.tpz" && \
    wget -q -O export.zip "${BASE_URL}/Godot_v${VERSION_NAME}_export_templates.tpz" && \
    mkdir -p ~/.local/share/godot/export_templates/${TEMPLATES_DIR} && \
    unzip -q export.zip -d ~/.local/share/godot/export_templates/${TEMPLATES_DIR} && \
    mv ~/.local/share/godot/export_templates/${TEMPLATES_DIR}/templates/* ~/.local/share/godot/export_templates/${TEMPLATES_DIR}/ && \
    rmdir ~/.local/share/godot/export_templates/${TEMPLATES_DIR}/templates && \
    rm export.zip

# Verify installation (commented out for now to avoid permission issues during build)
# RUN /usr/local/bin/godot --version

CMD [ "/usr/local/bin/godot", "--headless" ]

LABEL org.opencontainers.image.title="godot-docker" \
      org.opencontainers.image.description="Godot Engine Docker image based on Debian trixie and the latest Godot stable release including export templates." \
      org.opencontainers.image.authors="SharkyRawr" \
      org.opencontainers.image.url="https://github.com/SharkyRawr/godot-docker" \
      org.opencontainers.image.source="https://github.com/SharkyRawr/godot-docker" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${VERSION}${EDITION}"
