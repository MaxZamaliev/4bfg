#!/bin/bash
#
# Сборка, запуск и конфигурирование контейнера для сервиса stack_over_search
#
# 14.01.2022                                                  zamal@inbox.ru
#


SCRIPT=$(readlink -f $0)
SCRIPT_DIR=`dirname ${SCRIPT}`
SCRIPT_NAME=`basename ${SCRIPT}`



#-------------------------------------------   Инициализация переменных -----------------------------------------

SERVICE_NAME="oversearch"
IMAGE_NAME=${SERVICE_NAME}
CONTAINER_NAME=${SERVICE_NAME}
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.log"



#-------------------------------------------   Функции ----------------------------------------------------------

# Проверка запущен ли уже наш сервис
isServiceRunned() {
    local REZ="NO"
    docker ps -a --filter "name=${SERVICE_NAME}" --filter "ancestor=${IMAGE_NAME}" | grep oversearch &>/dev/null && REZ="YES"
    echo "${REZ}"
}


# Проверка запущен ли уже наш сервис
serviceCheck() {
    local SERVICE_STARTED="NO"
    docker ps --filter "name=${SERVICE_NAME}" --filter "ancestor=${IMAGE_NAME}" | grep oversearch &>/dev/null && SERVICE_STARTED="YES"
    echo "${SERVICE_STARTED}"
}

# Проверка запущен ли уже наш сервис
serviceHTTPCheck() {
    local SERVICE_HTTP_STARTED="NO"
    local SERVICE_IP=$(serviceGetIP)
    curl "http://${SERVICE_IP}/" &>/dev/null && SERVICE_HTTP_STARTED="YES"
    echo "${SERVICE_HTTP_STARTED}"
}

# Сборка образа
serviceBuild() {
    local BR="failed"
    cd ${SCRIPT_DIR}/docker
    docker build -t ${IMAGE_NAME} . &>> ${LOG_FILE} && BR="ok"
    cd ${SCRIPT_DIR}
    echo "${BR}"
}

# Запуск контейнера
serviceRun() {
    docker run --detach --name ${SERVICE_NAME} ${IMAGE_NAME} &>> ${LOG_FILE}
}

serviceInstall() {
    local SERVICE_IP=$(serviceGetIP)
    sed "s/%IPADDR%/${SERVICE_IP}/g" ${SCRIPT_DIR}/ansible/configs/inventory.yml_template >  ${SCRIPT_DIR}/ansible/configs/inventory.yml
    cd ${SCRIPT_DIR}/ansible
    export ANSIBLE_CONFIG="${SCRIPT_DIR}/ansible/configs/ansible.cfg"
    ansible-playbook start_role_oversearch.yml
}

# Запуск сервиса
serviceStart() {
    docker start ${SERVICE_NAME} &>> ${LOG_FILE}
}


# Остановка сервиса
serviceStop() {
    docker stop ${SERVICE_NAME} &>> ${LOG_FILE}
}

# Удаление сервиса
serviceRemove() {
    docker rm ${SERVICE_NAME} &>> ${LOG_FILE}
    docker rm ${IMAGE_NAME} &>> ${LOG_FILE}
}


# Получение IP-адреса запущенного сервиса
serviceGetIP() {
    local SERVICE_IP=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${SERVICE_NAME}`
    echo "${SERVICE_IP}"
}



#-------------------------------------------   Основной код ----------------------------------------------------------

#--------------------------------
# 'status'
#--------------------------------
if [[ "${1}" == "status" ]]
then
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        echo "Сервис ${SERVICE_NAME} запущен."
        SERVICE_IP=$(serviceGetIP)
        echo "IP-адрес сервиса: ${SERVICE_IP}"
        SERVICE_STATUS=$(serviceHTTPCheck)
        if [[ ${SERVICE_STATUS} == "YES" ]]
        then
          echo "Веб сервер сервиса отвечает."
        else
          echo "Веб сервер сервиса не отвечает."
        fi
        exit 0
    else
        echo "Сервис ${SERVICE_NAME} остановлен."
        exit 0
    fi
fi


#--------------------------------
# 'run' - первый запуск контейнера
#--------------------------------
if [[ "${1}" == "run" ]]
then
    # Проверяем создан ли уже сервис
    SERVICE_STARTED=$(isServiceRunned)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        echo "Контейнер ${SERVICE_NAME} уже создан."
        echo "Используйте параметр remove чтобы его остановить и удалить."
        exit 1
    fi

    # Запускаем сервис
    echo -n "Запускаем сервис..."
    serviceRun

    # Проверяем запустился ли сервис
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        echo "..ok"
        SERVICE_IP=$(serviceGetIP)
        echo "IP-адрес сервиса: ${SERVICE_IP}"
        exit 0
    else
        echo "..failed"
        exit 1
    fi
fi

#--------------------------------
# 'install' - конфигурирование сервиса
#--------------------------------
if [[ "${1}" == "install" ]]
then
    # Проверяем запущен ли уже сервис
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "NO" ]]
    then
        echo "Сервис ${SERVICE_NAME} не запущен."
        exit 1
    fi
    SERVICE_STATUS=$(serviceHTTPCheck)
    if [[ ${SERVICE_STATUS} == "YES" ]]
    then
        echo "Сервис уже установлен и работает."
        echo "Используйте параметр remove чтобы его удалить."
        exit 1
    fi
    serviceInstall
    exit 0
fi


#--------------------------------
# 'start' - запуск сервиса
#--------------------------------
if [[ "${1}" == "start" ]]
then
    # Проверяем запущен ли уже сервис
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        echo "Сервис ${SERVICE_NAME} уже запущен."
        echo "Используйте параметр stop чтобы его остановить."
        exit 1
    fi

    # Запускаем сервис
    echo -n "Запускаем сервис..."
    serviceStart

    # Проверяем запустился ли сервис
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        echo "..ok"
        SERVICE_IP=$(serviceGetIP)
        echo "IP-адрес сервиса: ${SERVICE_IP}"
        exit 0
    else
        echo "..failed"
        exit 1
    fi
fi


#--------------------------------
# 'stop' - остановка сервиса
#--------------------------------
if [[ "${1}" == "stop" ]]
then
    # Проверяем запущен ли уже сервис
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "NO" ]]
    then
        echo "Сервис ${SERVICE_NAME} уже остановлен."
        exit 1
    fi

    # Останавливаем сервис
    echo -n "Останавливаем сервис..."
    serviceStop

    # Проверяем остановился ли сервис
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        echo "..failed"
        exit 1
    else
        echo "..ok"
        exit 0
    fi
fi

#--------------------------------
# 'remove' - удаление сервиса и собранного образа
#--------------------------------
if [[ "${1}" == "remove" ]]
then
    # Проверяем запущен ли уже сервис
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        # Останавливаем сервис
        echo -n "Останавливаем сервис..."
        serviceStop
        # Проверяем остановился ли сервис
        SERVICE_STARTED=$(serviceCheck)
        if [[ ${SERVICE_STARTED} == "YES" ]]
        then
            echo "..failed"
            exit 1
        else
            echo "..ok"
        fi
    fi
    echo -n "Удаляем сервис..."
    serviceRemove
    echo ".ok"
    exit 0
fi

#--------------------------------
# 'build' - сборка образа
#--------------------------------
if [[ "${1}" == "build" ]]
then
    echo -n "Пересобираем образ контейнера..."
    BUILD_REZULT=$(serviceBuild)
    echo "..${BUILD_REZULT}"
    exit 0
fi

#--------------------------------
# 'fullinit' - последовательное выполнение build + run + install
#--------------------------------
if [[ "${1}" == "fullinit" ]]
then
    SERVICE_STARTED=$(serviceCheck)
    if [[ ${SERVICE_STARTED} == "YES" ]]
    then
        echo "Сервис ${SERVICE_NAME} уже запущен."
        echo "Используйте параметр remove чтобы его удалить."
        exit 1
    fi
    ${SCRIPT_DIR}/${SCRIPT_NAME} build && \
    ${SCRIPT_DIR}/${SCRIPT_NAME} run && \
    ${SCRIPT_DIR}/${SCRIPT_NAME} install && \
    exit 0

    exit 1
fi

#--------------------------------
#            HELP
#--------------------------------
echo "Не указан один из обязательных параметров:
        fullinit - последовательно запустить build+run+install
        status   - информация о состоянии сервиса
        build    - собрать docker контейнер
        run      - первичный запуск контейнера
        install  - установить ansible роль
        start    - запуск контейнера
        stop     - остановка контейнера
        remove   - удалить контейнер и собранный образ"

exit 1

#EOF
