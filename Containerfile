# fldigi + flmsg/flamp/flwrap container - builds from upstream source so it works on amd64 and arm64.
#   podman build --build-arg FLDIGI_VERSION=4.2.13 -t fldigi:4.2.13 .
ARG DEBIAN_RELEASE=bookworm

# ---------- build stage ----------
FROM docker.io/library/debian:${DEBIAN_RELEASE}-slim AS build
ARG FLDIGI_VERSION=4.2.13
ARG FLDIGI_SHA256=
ARG FLMSG_VERSION=4.0.24
ARG FLAMP_VERSION=2.2.14
ARG FLWRAP_VERSION=1.3.6
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl pkg-config gettext \
        libfltk1.3-dev libsamplerate0-dev libsndfile1-dev \
        portaudio19-dev libpulse-dev libasound2-dev \
        libpng-dev libjpeg-dev libxft-dev libxinerama-dev libxcursor-dev \
        libx11-dev libudev-dev libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN curl -fsSL -o fldigi.tar.gz \
        "https://downloads.sourceforge.net/project/fldigi/fldigi/fldigi-${FLDIGI_VERSION}.tar.gz" \
    && if [ -n "${FLDIGI_SHA256}" ]; then echo "${FLDIGI_SHA256}  fldigi.tar.gz" | sha256sum -c -; fi \
    && tar xzf fldigi.tar.gz --strip-components=1 \
    && ./configure --prefix=/usr --disable-flarq \
    && make -j"$(nproc)" \
    && make DESTDIR=/out install-strip

# NBEMS helpers: flmsg, flamp, flwrap (launched from fldigi's menus)
WORKDIR /helpers
RUN set -e; \
    for spec in "flmsg:${FLMSG_VERSION}" "flamp:${FLAMP_VERSION}" "flwrap:${FLWRAP_VERSION}"; do \
        name="${spec%%:*}"; ver="${spec##*:}"; \
        mkdir "$name" && cd "$name"; \
        curl -fsSL -o src.tar.gz "https://downloads.sourceforge.net/project/fldigi/${name}/${name}-${ver}.tar.gz"; \
        tar xzf src.tar.gz --strip-components=1; \
        CXXFLAGS="-O2 -include pthread.h" ./configure --prefix=/usr; \
        make -j"$(nproc)"; \
        make DESTDIR=/out install-strip; \
        cd ..; \
    done

# ---------- runtime stage ----------
FROM docker.io/library/debian:${DEBIAN_RELEASE}-slim
ARG FLDIGI_VERSION=4.2.13
ARG FLMSG_VERSION=4.0.24
ARG FLAMP_VERSION=2.2.14
ARG FLWRAP_VERSION=1.3.6
LABEL org.opencontainers.image.title="fldigi" \
      org.opencontainers.image.version="${FLDIGI_VERSION}" \
      org.opencontainers.image.source="https://sourceforge.net/projects/fldigi/"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        libfltk1.3 libfltk-images1.3 libsamplerate0 libsndfile1 \
        libportaudio2 libpulse0 libasound2 alsa-utils \
        libpng16-16 libjpeg62-turbo libxft2 libxinerama1 libxcursor1 libx11-6 \
        libusb-1.0-0 libudev1 \
        fonts-dejavu-core x11-xserver-utils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/usr/ /usr/

# Run as a non-root user; compose uses keep-id so this maps to the host user.
# Home (/home/fldigi) holds ~/.fldigi (config) and ~/fldigi.files (logs, saved data).
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash -G audio,dialout fldigi
USER fldigi
WORKDIR /home/fldigi
ENV HOME=/home/fldigi

ENTRYPOINT ["fldigi"]
