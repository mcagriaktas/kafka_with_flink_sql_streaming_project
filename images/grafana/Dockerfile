FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ENV GRAFANA_VERSION=10.4.14

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    software-properties-common \
    wget \
    gnupg2 \
    curl \
    ca-certificates \
    jq \
    nano \
    vim \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
RUN echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list

RUN apt-get update && apt-get install -y grafana=${GRAFANA_VERSION} \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/grafana /var/log/grafana /etc/grafana/provisioning/dashboards/json \
    /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards/provider

RUN mkdir -p /usr/bin/init-sh

COPY init-sh/grafana-starter.sh /usr/bin/grafana-starter.sh

RUN chmod +x /usr/bin/grafana-starter.sh

RUN sed -i 's/;allow_embedding = false/allow_embedding = true/' /etc/grafana/grafana.ini && \
    sed -i 's/;cookie_secure = false/cookie_secure = false/' /etc/grafana/grafana.ini && \
    sed -i 's/;cookie_samesite = lax/cookie_samesite = lax/' /etc/grafana/grafana.ini

ENV GF_USERS_ALLOW_SIGN_UP=false \
    GF_AUTH_DISABLE_LOGIN_FORM=false \
    GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_DISABLE_GRAVATAR=true \
    GF_SECURITY_ALLOW_EMBEDDING=true \
    GF_USERS_ALLOW_ORG_CREATE=false \
    GF_SECURITY_COOKIE_SECURE=false \
    GF_SECURITY_COOKIE_SAMESITE=lax \
    GF_INSTALL_PLUGINS="" \
    GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
    GF_PATHS_CONFIG=/etc/grafana/grafana.ini \
    GF_PATHS_DATA=/var/lib/grafana \
    GF_PATHS_LOGS=/var/log/grafana \
    GF_PATHS_PLUGINS=/var/lib/grafana/plugins

CMD ["/usr/bin/grafana-starter.sh"]