FROM ubuntu:18.04
MAINTAINER zamal@inbox.ru

### Установка локалей (см. https://hub.docker.com/_/ubuntu )
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

### Установка openssh-server
RUN apt-get update \
    && apt-get install -y \
        openssh-server
### Копирование ключа для доступа по ssh
ADD ./files/authorized_keys /root/.ssh/authorized_keys

### Копирование entrypoint.sh скрипта
ADD ./files/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
