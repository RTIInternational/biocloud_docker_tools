# Set a default docker base image to pass to all stages
ARG BASE_IMAGE=dhi.io/python:3.10.20-alpine3.22


##################
### Build CKAN ###
##################
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}-dev AS ckanbuild

# Used by Github Actions to tag the image with
ENV IMAGE_TAG="2.10.3"

# Set CKAN version to build
ENV GIT_URL="https://github.com/ckan/ckan.git"
ENV GIT_BRANCH="ckan-${IMAGE_TAG}"

# Set src dirs
ENV SRC_DIR="/app/src"

# Set uv config
ENV XDG_BIN_HOME="/usr/local/bin"
ENV XDG_CACHE_HOME="/app/cache"
ENV UV_COMPILE_BYTECODE="1"
ENV UV_LINK_MODE="copy"
ENV UV_PYTHON_DOWNLOADS="0"

# Set default shell to ash and enable pipefail
# This is nececary when using pipes in docker so it wont silent fail
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# System packages to build CKAN requirements and plugins
RUN apk add --no-cache \
        git \
        curl \
        postgresql17-dev

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR ${SRC_DIR}/ckan

# Fetch CKAN from github and remove git history
RUN git clone --depth=1 --branch ${GIT_BRANCH} ${GIT_URL} . && \
    rm -rf ${SRC_DIR}/.git

# Build wheels for CKAN requirements
RUN uv pip install --system -r requirements.txt


###################
### Build uWSGI ###
###################
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}-dev AS uwsgibuild

# Set uWSGI version to build
ENV UWSGI_VERSION=2.0.28

# Set uv config
ENV XDG_BIN_HOME="/usr/local/bin"
ENV XDG_CACHE_HOME="/app/cache"
ENV UV_COMPILE_BYTECODE="1"
ENV UV_LINK_MODE="copy"
ENV UV_PYTHON_DOWNLOADS="0"

# Set default shell to ash and enable pipefail
# This is nececary when using pipes in docker so it wont silent fail
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

# System packages to build CKAN requirements and plugins
RUN apk add --no-cache \
        curl \
        linux-headers \
        musl-dev \
        gcc

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Compile uWSGI
RUN uv pip install --system uwsgi==${UWSGI_VERSION}


############
### MAIN ###
############
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}-dev

LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL org.opencontainers.image.source="https://github.com/RTIInternational/biocloud_docker_tools/ckan/"

# Default CKAN Extensions
ENV ENVVARS_GIT_URL="https://github.com/okfn/ckanext-envvars"
ENV ENVVARS_GIT_VERSION="v0.0.6"
ENV XLOADER_GIT_URL="https://github.com/ckan/ckanext-xloader.git"
ENV XLOADER_GIT_VERSION="2.2.0"
ENV XLOADER_REQUIREMENTS_URL="https://raw.githubusercontent.com/ckan/ckanext-xloader/refs/tags/${XLOADER_GIT_VERSION}/requirements.txt"

# CKAN env
ENV APP_DIR="/app"
ENV SRC_DIR="/app/src"
ENV CKAN_DIR="${SRC_DIR}/ckan"
ENV DATA_DIR="/app/data"
ENV CKAN_SITE_URL="http://localhost:5000"
ENV CKAN__PLUGINS="envvars activity image_view text_view datatables_view datastore xloader"

# Set uv config
ENV XDG_BIN_HOME="/usr/local/bin"
ENV XDG_CACHE_HOME="/app/cache"
ENV UV_PYTHON_DOWNLOADS="0"

# Install necessary packages to run CKAN
RUN apk add --no-cache \
        bash \
        git \
        curl \
        # Required for CKAN
        libmagic \
        postgresql17-client

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR ${APP_DIR}

# Create a local user and group to run the app
RUN addgroup -g 92 -S ckan && \
    adduser -u 92 -h /app -H -D -S -G ckan ckan && \
    chown -R ckan:ckan /app

# Get artifacts from build stages
COPY --from=uwsgibuild /opt/python/bin/uwsgi /usr/local/bin/uwsgi
COPY --from=ckanbuild --chown=ckan:ckan /app/cache /app/cache
COPY --from=ckanbuild --chown=ckan:ckan /app/src/ckan ${CKAN_DIR}

WORKDIR ${CKAN_DIR}

# Install CKAN
RUN uv pip install --system pip --upgrade setuptools wheel && \
    uv pip install --system -r requirements.txt && \
    uv pip install --system -e ${CKAN_DIR}

# Install extensions and create directory structure
RUN /opt/python/bin/pip install git+${ENVVARS_GIT_URL}@${ENVVARS_GIT_VERSION} && \
    /opt/python/bin/pip install git+${XLOADER_GIT_URL}@${XLOADER_GIT_VERSION} && \
    /opt/python/bin/pip install -r ${XLOADER_REQUIREMENTS_URL} && \
    /opt/python/bin/pip install requests[security] && \
    # Create the data directory
    mkdir -p ${DATA_DIR} && \
    # Create and set timezone
    echo "UTC" > /etc/timezone && \
    chown -R ckan:ckan ${APP_DIR} && \
    # Remove pip cache
    rm -rf ~/.cache/pip /app/cache

# Copy necessary scripts
COPY --chown=ckan:ckan setup/app ${APP_DIR}

WORKDIR ${APP_DIR}

# Create entrypoint directory for children image scripts
ONBUILD RUN mkdir docker-entrypoint.d

# Create afterinit directory for children image scripts
ONBUILD RUN mkdir docker-afterinit.d

EXPOSE 5000

HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD curl --fail http://localhost:5000/api/3/action/status_show || exit 1

USER ckan

# Startup options for uwsgi, set UWSGI_OPTS env variable on runtime to override
ENV UWSGI_PROC_NU="2"
ENV UWSGI_OPTS="--socket /tmp/uwsgi.sock --uid ckan --gid ckan --http :5000 --master --enable-threads --wsgi-file $APP_DIR/wsgi.py --module wsgi:application --lazy-apps -p ${UWSGI_PROC_NU} -L --vacuum --harakiri 50 --callable application"

CMD ["/app/start_ckan.sh"]
