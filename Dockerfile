FROM centos:7.4.1708
MAINTAINER Linzhaoming <teleyic@gmail.com>

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV RUN_USER=logan
ENV RUN_GROUP=logan

ADD docker/nginx/nginx.repo  /etc/yum.repos.d/nginx.repo

RUN yum install -y epel-release \
    && yum install -y unzip nmap iproute net-tools wget which bind-utils \
    && yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum install -y yum-utils \
    && yum-config-manager --enable remi-php72 \
    && yum install -y nginx-1.12.1-1.el7.ngx.x86_64

RUN yum install -y \
    php-fpm \
    php-xml \
    php-cli \
    php-dba \
    php-gd \
    php-intl \
    php-mbstring \
    php-mysql \
    php-pdo \
    php-soap \
    php-pecl-apcu \
    php-pecl-imagick \
    php-pecl-redis \
    php-pecl-zip \
    php-bcmath \
    php-bz2 \
    php-opcache \
    php-posix

RUN yum -y clean all \
    && rm -rf /var/cache/yum

RUN adduser -U $RUN_USER -u 1000 \
    && mkdir -p /home/$RUN_USER/local \
    && chown -R $RUN_USER:$RUN_GROUP /home/$RUN_USER \
    && mkdir -p /opt/data \
    && chown -R $RUN_USER:$RUN_GROUP /opt/data

# PHP config
ADD docker/nginx/php-fpm.conf /etc/
RUN mkdir -p /run/php-fpm && \
    chown $RUN_USER:$RUN_GROUP /run/php-fpm

# Nginx config
ADD docker/nginx/nginx.conf  /etc/nginx/nginx.conf
ADD docker/nginx/enable-php.conf  /etc/nginx/enable-php.conf
ADD docker/nginx/fastcgi.conf /etc/nginx/fastcgi.conf
ADD docker/default.conf  /etc/nginx/conf.d/

RUN touch /var/run/nginx.pid \
  && touch /var/log/nginx/access.log \
  && chown -R $RUN_USER:$RUN_GROUP /var/run/nginx.pid \
  && chown -R $RUN_USER:$RUN_GROUP /var/cache/nginx \
  && chown -R $RUN_USER:$RUN_GROUP /etc/nginx \
  && chown -R $RUN_USER:$RUN_GROUP /var/log/nginx

RUN mkfifo -m 666 /tmp/stderr
CMD ["sh", "-c", "exec 3<>/tmp/stderr; nginx -g 'daemon on;'; php-fpm -D >/tmp/stderr 2>&1; cat <&3 >&2"]


WORKDIR /home/$RUN_USER/local
ADD . /home/$RUN_USER/work/app
RUN chown -R $RUN_USER:$RUN_GROUP /home/$RUN_USER/work
USER $RUN_USER
