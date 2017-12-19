FROM ubuntu:xenial

MAINTAINER Menzo Windhouwer <menzo.windhouwer@meertens.knaw.nl>

ARG PGSQLIP=localhost
ARG PGSQLHOST=oai.postgres.lo

ENV DF_USER_FN    dream
ENV DF_USER_LN    Admin
ENV DF_USER       admin
ENV DF_USER_EMAIL admin@example.com
ENV DF_USER_PWD   dreamAdmin

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
    git-core curl apache2 libapache2-mod-php7.0 php7.0-common php7.0-cli php7.0-curl php7.0-json php7.0-mcrypt php7.0-mysqlnd php7.0-pgsql php7.0-sqlite \
    php-pear php7.0-dev php7.0-ldap php7.0-sybase php7.0-mbstring php7.0-zip php7.0-soap openssl pkg-config python python-pip zip \
    supervisor expect postgresql

RUN rm -rf /var/lib/apt/lists/*

#RUN pip install bunch
#RUN mkdir -p /usr/lib /usr/include

# apache
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf && \
    a2enconf servername
RUN rm /etc/apache2/sites-enabled/000-default.conf
ADD apache/dreamfactory.conf /etc/apache2/sites-available/dreamfactory.conf
ADD apache/headers.conf /etc/apache2/mods-available/headers.conf
RUN a2ensite dreamfactory
RUN a2enmod headers
RUN a2enmod rewrite

EXPOSE 80

# get app src
RUN git clone -b 2.2.1 https://github.com/dreamfactorysoftware/dreamfactory.git /opt/dreamfactory
WORKDIR /opt/dreamfactory

# install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

# no mongodb
RUN cat composer.json | grep -v df-mongodb > composer.json.NEW &&\
    mv composer.json composer.json.ORG &&\
    mv composer.json.NEW composer.json &&\
    composer update --no-dev

# install packages
RUN composer install --no-dev

# supervisor
ADD supervisor/*.conf /etc/supervisor/conf.d/
ADD supervisor/start-*.sh /
RUN	chmod u+x /start-*.sh

# entrypoint
ADD info.txt /info.txt
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

CMD ["/docker-entrypoint.sh"]

# permissions
RUN chown -R www-data:www-data /opt/dreamfactory

# CLARIN: do our setup
ADD df-setup-db.sh /opt/dreamfactory/df-setup-db.sh
ADD df-add-user.sh /opt/dreamfactory/df-add-user.sh
RUN chmod +x df-*.sh
RUN ./df-setup-db.sh && echo "done"
RUN ./df-add-user.sh && echo "done"

# permissions (again)
RUN chown -R www-data:www-data /opt/dreamfactory

# OAI app
ADD oai-app.zip /tmp/oai-app.zip
RUN echo ${PGSQLIP} ${PGSQLHOST} >> /etc/hosts 

# forward request and error logs to docker log collector
RUN ln -sf /dev/stderr /var/log/apache2/error.log