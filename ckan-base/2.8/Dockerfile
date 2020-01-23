FROM alpine:3.7

# Internals, you probably don't need to change these
ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV CKAN_INI=${APP_DIR}/production.ini
ENV PIP_SRC=${SRC_DIR}
ENV CKAN_STORAGE_PATH=/var/lib/ckan
ENV GIT_URL=https://github.com/ckan/ckan.git
# CKAN version to build
ENV GIT_BRANCH=ckan-2.8.3
# Customize these on the .env file if needed
ENV CKAN_SITE_URL=http://localhost:5000
ENV CKAN_EXTENSIONS="ckanext-oauth2 ckanext-privatedatasets ckanext-right_time_context \
        ckanext-baepublisher ckanext-wirecloud_view ckanext-datarequests"

WORKDIR ${APP_DIR}

# Install necessary packages to run CKAN
RUN apk add --no-cache tzdata \
        git \
        gettext \
        postgresql-client \
        python \
        apache2-utils \
        libxml2 \
        libxslt \
        musl-dev \
        uwsgi \
        uwsgi-http \
        uwsgi-corerouter \
        uwsgi-python \
        py2-gevent \
        uwsgi-gevent \
        libmagic \
        curl \
        sudo && \
    # Packages to build CKAN requirements and plugins
    apk add --no-cache --virtual .build-deps \
        postgresql-dev \
        gcc \
        make \
        g++ \
        autoconf \
        automake \
	libtool \
        python-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers && \
    # Create SRC_DIR
    mkdir -p ${SRC_DIR} && \
    # Install pip, supervisord and uwsgi
    curl -o ${SRC_DIR}/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python ${SRC_DIR}/get-pip.py && \
    pip install supervisor && \
    mkdir /etc/supervisord.d && \
    #pip wheel --wheel-dir=/wheels uwsgi gevent && \
    rm -rf ${SRC_DIR}/get-pip.py

#RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
#    apk add --update --no-cache geos@testing geos-dev@testing

RUN cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime && echo "Europe/Amsterdam" > /etc/timezone

COPY setup/supervisord.conf /etc

# Install CKAN
RUN pip install -e git+${GIT_URL}@${GIT_BRANCH}#egg=ckan && \
    cd ${SRC_DIR}/ckan && \
    cp who.ini ${APP_DIR} && \
    pip install --no-binary :all: -r requirements.txt && \
    # Install CKAN envvars to support loading config from environment variables
    pip install -e git+https://github.com/okfn/ckanext-envvars.git#egg=ckanext-envvars && \
    pip install ${CKAN_EXTENSIONS} && \
    # Create and update CKAN config
    paster --plugin=ckan make-config ckan ${CKAN_INI} && \
    paster --plugin=ckan config-tool ${CKAN_INI} "ckan.plugins = ${CKAN__PLUGINS}" && \
    paster --plugin=ckan config-tool ${CKAN_INI} "ckan.views.default_views = ${CKAN__VIEWS}" && \
    paster --plugin=ckan config-tool ${CKAN_INI} "ckan.site_url = ${CKAN__SITE_URL}" && \
    paster --plugin=ckan config-tool ${CKAN_INI} "ckan.wirecloud_view.url = ${CKAN__WIRECLOUD_VIEW_URL}" && \
    paster --plugin=ckan config-tool ${CKAN_INI} "ckan.wirecloud_view.editor_dashboard = wirecloud/ckan-editor"

# Create a local user and group to run the app
RUN addgroup -g 92 -S ckan && \
    adduser -u 92 -h /srv/app -H -D -S -G ckan ckan

# Create local storage folder
RUN mkdir -p $CKAN_STORAGE_PATH && \
    mkdir -p $CKAN_STORAGE_PATH/storage/uploads && \
    chown -R ckan:ckan $CKAN_STORAGE_PATH

# Copy setup files to image to set the instance of CKAN up.
COPY setup ${APP_DIR}
COPY setup/supervisor.worker.conf /etc/supervisord.d/worker.conf
COPY setup/uwsgi.conf /srv/app/uwsgi.conf
COPY setup/start_ckan.sh /srv/app/start_ckan.sh

# Create entrypoint directory for children image scripts
ONBUILD RUN mkdir /docker-entrypoint.d

# Set permissions right to start CKAN.
RUN chown ckan -R /srv/app && \ 
    chmod a+x /srv/app/start_ckan.sh

EXPOSE 5000

HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD curl --fail http://localhost:5000/api/3/action/status_show || exit 1

CMD ["/srv/app/start_ckan.sh"]
