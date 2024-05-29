#!/bin/sh

#=============================================================
# Файл: postinstall.sh
# Назначение: Настройка ОС
# Версия: 1.0
# Автор: Пахомов Г.Д.
# Дата: 24.05.2024
#=============================================================


#=============================================================
# Переменные
#=============================================================

USER_NAME=astra
PASSWORD=12345678
DIR=/your_dir
IP=192.168.31.97
FILE=test.txt
LOG_TAG=postinstall

#=============================================================
# Раздел настройки ОС
#=============================================================

# Удаление пароля из GRUB
function disable_grub_password() {
  if sed -i 's/set\ superusers=/#set\ superusers=/g' /etc/grub.d/07_password &&
     sed -i 's/set\ superusers=/#set\ superusers=/g' /boot/grub/grub.cfg &&
     sed -i 's/password_pbkdf2/#password_pbkdf2/g' /etc/grub.d/07_password &&
     sed -i 's/password_pbkdf2/#password_pbkdf2/g' /boot/grub/grub.cfg
  then
    logger -t "$LOG_TAG" "disable_grub_password - success"
  else
    logger -t "$LOG_TAG" "disable_grub_password - failed"
  fi
}


# Проверка наличия пользователя astra
function check_user() {
  # Проверяем, существует ли пользователь с таким именем
  if id -u $USER_NAME >/dev/null 2>&1;
  then
    usermod -a -G libvirt-admin,libvirt-qemu,libvirt,disk,kvm,astra-admin,astra-console $USER_NAME &&
    logger -t "$LOG_TAG" "check_user - success"
  else
    useradd -m -d /bin/bash $USER_NAME &&
    echo $USER_NAME:$PASSWORD | chpasswd &&
    pdpl-user -i 63 $USER_NAME &&
    usermod -aG sudo $USER_NAME &&
    usermod -a -G libvirt-admin,libvirt-qemu,libvirt,disk,kvm,astra-admin,astra-console $USER_NAME &&
    logger -t "$LOG_TAG" "check_user - success"
  fi
}


# Создание автологина
function autologin() {
  if sed -i "/AutoLoginEnable=/c\AutoLoginEnable=true" /etc/X11/fly-dm/fly-dmrc &&
     sed -i "/AutoLoginUser=/c\AutoLoginUser=$USER_NAME" /etc/X11/fly-dm/fly-dmrc &&
     sed -i "/AutoLoginPass=/c\AutoLoginPass=$PASSWORD" /etc/X11/fly-dm/fly-dmrc &&
     sed -i "/AutoLoginMAC=/c\AutoLoginMAC=0:63:0x0:0x0!" /etc/X11/fly-dm/fly-dmrc
  then
    logger -t "$LOG_TAG" "autologin - success"
  else
    logger -t "$LOG_TAG" "autologin - failed"
  fi
}


#=============================================================
# Раздел решения
#=============================================================

# Функция проверки доступности архива
function server_http_status() {
    # Проверяем, доступен ли HTTP-сервер
  if ! curl --silent --fail "http://$IP" >/dev/null 2>&1;
  then
    logger -t "$LOG_TAG" "server_http_status $IP - failed"
  fi

  # Проверяем, существуют ли файлы
  if curl  --silent --fail --head "http://$IP/$FILE" | grep -qE 'HTTP/[0-9\.]+ 200 OK';
  then
     logger -t "$LOG_TAG" "server_http_status Файлы - success"
  else
    logger -t "$LOG_TAG" "server_http_status Файл tac_rdy.tar.gz - failed"
  fi
}

# Функция коприрования
function dir_copy() {
  if mkdir $DIR &&
     wget http://$IP/$FILE -P $DIR
  then
    logger -t "$LOG_TAG" "dir_copy - success"
  else
    logger -t "$LOG_TAG" "dir_copy - failed"
  fi
}



#=============================================================
# Основной модуль
#=============================================================
main() {
  if  disable_grub_password; then
     if  check_user; then
        autologin || true;
     if  server_http_status; then
        dir_copy || true;
     else
        logger -t "$LOG_TAG" "main - failed"
        exit 1
     fi
  fi
  fi
  logger -t "$LOG_TAG" "main - success"
  exit 0
}


main "$@"