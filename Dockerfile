FROM ubuntu:latest
MAINTAINER Todor Kandev <todor@kandev.com>

# Please fill the FQDN of the mail server
ENV MYHOSTNAME mail.example.org

RUN \
  apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
    postfix \
    opendkim \
    dovecot-imapd \
    dovecot-pop3d \
    dovecot-antispam \
    coreutils \
    bash \
    supervisor \
    ca-certificates \
    certbot \
    locales \
    inetutils-syslogd \
    cron \
    curl \
    vim \
    mc

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Copy all default configuration files
COPY ./files/supervisord.conf /etc/supervisor/
RUN mkdir -p /var/config/postfix
COPY ./files/opendkim.conf /var/config/
COPY ./files/dovecot.conf /var/config/
RUN sed -i "s/mail\.example\.com/${MYHOSTNAME}/g" /var/config/dovecot.conf
RUN touch /var/config/users
COPY ./files/main.cf /var/config/postfix/
RUN sed -i "s/mail\.example\.com/${MYHOSTNAME}/g" /var/config/postfix/main.cf
COPY ./files/master.cf /var/config/postfix/
COPY ./files/mailbox_domains /var/config/postfix/
COPY ./files/mailbox_maps /var/config/postfix/
COPY ./files/alias_maps /var/config/postfix/
RUN /usr/sbin/postmap /var/config/postfix/mailbox_domains; /usr/sbin/postmap /var/config/postfix/mailbox_maps; /usr/sbin/postmap /var/config/postfix/alias_maps

# Generate OpenDKIM key
RUN openssl genrsa -out /var/config/dkim_private.key 1024

# Extract public key
RUN openssl rsa -in /var/config/dkim_private.key -pubout | sed '1d;$d' | tr -d '\n' > /var/config/dkim_public.key

# Prepare Postfix chrooted environment
RUN mkdir -p /var/spool/postfix/etc/
RUN cp -f /etc/resolv.conf /var/spool/postfix/etc/
RUN cp -f /etc/services /var/spool/postfix/etc/

# Renew all available certificates
RUN echo '0 3 * * * /sr/bin/certbot renew -n --standalone' | crontab

EXPOSE 25 80 143
VOLUME ["/var/mail/domains"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
