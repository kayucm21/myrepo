#!/bin/sh
Infon()
{
 printf "\033[1;32m$@\033[0m"
}
Info()
{
 Infon "$@\n"
}
Ошибка()
{
 printf "\033[1;31m$@\033[0m\n"
}
Ошибка_n()
{
 Ошибка "$@"
}
Ошибка_s()
{
	Ошибка "${red}=================================================================================${reset}"
}
log_s()
{
	Info "${green}================================================================================${reset}"
}
cp_s ()
{
	Info "${green}================================${white}Установщик Сборку NEXTRP${green}==================================${reset}"
}
log_n()
{
 Info "$@"
}
log_t()
{
 log_s
 Info "- - - $@"
 log_s
}
log_tt()
{
 Info "- - - $@"
 log_s
}

RED=$(tput setaf 1)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
white=$(tput setaf 7)
reset=$(tput sgr0)
toend=$(tput hpa $(tput cols))$(tput cub 6)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
LIME_YELLOW=$(tput setaf 190)
CYAN=$(tput setaf 6)
VER=`cat /etc/issue.net | awk '{print $1$3}'`
OS=$(lsb_release -s -i -c -r | xargs echo |sed 's; ;-;g' | grep Ubuntu)
IP_SERV=$(echo "${SSH_CONNECTION}" | awk '{print $3}')

install_ftp() {
    log_n "${BLUE}Установка FTP сервера"
    sudo apt -y install vsftpd > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${green}[Успешно]"
        tput sgr0
    else
        echo "${red}[Ошибка]"
        tput sgr0
        exit
    fi
    
    log_n "${BLUE}Настройка FTP сервера"
    sudo sed -i 's/anonymous_enable=YES/anonymous_enable=NO/g' /etc/vsftpd.conf
    sudo sed -i 's/local_enable=NO/local_enable=YES/g' /etc/vsftpd.conf
    sudo sed -i 's/write_enable=NO/write_enable=YES/g' /etc/vsftpd.conf
    sudo systemctl restart vsftpd
    if [ $? -eq 0 ]; then
        echo "${green}[Успешно]"
        tput sgr0
    else
        echo "${red}[Ошибка]"
        tput sgr0
        exit
    fi
}

install_nextrp()
{
	clear
        log_n "${BLUE}Установка панели управления"
        ADMIN_PASS=$(pwgen -cns -1 12) > /dev/null 2>&1
        echo "admin:$ADMIN_PASS" | chpasswd > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "${green}[Успешно]"
            tput sgr0
        else
            echo "${red}[Ошибка]"
            tput sgr0
            exit
        fi

		log_n "${BLUE}Обновление пакетов"
		sudo apt -y update && apt upgrade > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Установка Apache2"
		sudo apt -y install apache2 > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Включаем установленный Apache2"
		sudo systemctl enable apache2.service > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Установка MariaDB-Server и MariaDB-Client"
		sudo apt -y install mariadb-server mariadb-client > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Включаем установленные MariaDB-Server и MariaDB-Client"
		sudo systemctl enable mariadb.service > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi	

		log_n "${BLUE}Подгрузка компонентов"
		apt-get install -y curl pwgen sudo unzip openssh-server > /dev/null 2>&1
		PASSBAZ=$(pwgen -cns -1 16) > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Установка пароля на базу-данных"
		sudo mysql_secure_installation 2>/dev/null <<MSI2
		${PASSBAZ}
		y
		${PASSBAZ}
		${PASSBAZ}
		y
		y
		y
		y	
MSI2
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi	

		log_n "${BLUE}Настраиваем базу-данных #1"
		mysql -e "GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY '$PASSBAZ' WITH GRANT OPTION" > /dev/null 2>&1
		mysql -e "FLUSH PRIVILEGES" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi
	
		log_n "${BLUE}Установка подкомпонентов #1"
		sudo apt-get -y install software-properties-common > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi	

		log_n "${BLUE}Установка подкомпонентов #2"
		sudo apt -y install php7.4 libapache2-mod-php7.4 php7.4-gmp php7.4-curl php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-mysql php7.4-gd php7.4-bcmath php7.4-xml php7.4-cli php7.4-zip > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Установка PhpMyAdmin"
		echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections > /dev/null 2>&1
		echo "phpmyadmin phpmyadmin/mysql/admin-user string admin" | debconf-set-selections > /dev/null 2>&1
		echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSBAZ" | debconf-set-selections > /dev/null 2>&1
		echo "phpmyadmin phpmyadmin/mysql/app-pass password $PASSBAZ" |debconf-set-selections > /dev/null 2>&1
		echo "phpmyadmin phpmyadmin/app-password-confirm password $PASSBAZ" | debconf-set-selections > /dev/null 2>&1
		echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections > /dev/null 2>&1
		apt-get install -y phpmyadmin > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Установка подкомпонентов #3"
		sudo apt -y install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi	

		log_n "${BLUE}Установка подкомпонентов #4"
		apt-get -y install default-libmysqlclient-dev git unzip > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi							

		log_n "${BLUE}Установка подкомпонентов #5"
		apt -y install screen > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Загрузка сборки"
		cd /root > /dev/null 2>&1
		mkdir next > /dev/null 2>&1
		wget https://my-files.su/Save/57vcx8/nrp.zip > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Подключение базы-данных к сборке"
		sed -i "s/paroltas/${PASSBAZ}/g" /root/next/mods/deathmatch/resources/[gamemode]/interfacer/Extend/SDB.lua
		sed -i "s/paroltas2/${PASSBAZ}/g" /root/next/mods/deathmatch/resources/[gamemode]/nrp_mariadb/SDatabase.lua
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Загрузка и установка дампа базы-данных"
		mkdir /var/lib/mysql/next > /dev/null 2>&1
		chown -R mysql:mysql /var/lib/mysql/next > /dev/null 2>&1
		mysql next < /root/next/nrp.sql > /dev/null 2>&1
		rm -rf /root/next/nrp.sql > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi		

		log_n "${BLUE}Установка прав"
		chmod -R 777 /root/next/x64
		chmod 777 /root/next/mta-server64
		chmod 777 /root/next/net.so
		chmod 777 /root/next/net_d.so
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi	

		log_n "${BLUE}Настройка оптимизации сервера"
		sysctl -w net.ipv4.tcp_window_scaling=1 > /dev/null 2>&1
		sysctl -w net.core.rmem_max=16777216 > /dev/null 2>&1
		sysctl -w net.core.wmem_max=16777216 > /dev/null 2>&1
		sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" > /dev/null 2>&1
		sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" > /dev/null 2>&1
		sysctl -w net.ipv4.tcp_low_latency=1 > /dev/null 2>&1
		sysctl -w net.ipv4.tcp_mtu_probing=1 > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi

		log_n "${BLUE}Запуск сервера"
		cd /root/next
		screen -S next -d -m
        screen -S next -X exec ./mta-server64
		if [ $? -eq 0 ]; then
			echo "${green}[Успешно]"
			tput sgr0
		else
			echo "${red}[Ошибка]"
			tput sgr0
			exit
		fi	

		cd /root
		echo "Установка сборки NRP успешно завершена! \n База данных - http://$IP_SERV/phpmyadmin/ \n Логин - admin \n Пароль - $PASSBAZ \n \n SFTP Доступ - $IP_SERV \n Логин - root \n Пароль - от вашей VDS, не от базы-данных \n Порт - 22 \n \n Панель управления: \n Логин: admin \n Пароль: $ADMIN_PASS \n \n IP и порт для входа в игру: $IP_SERV:22003 \n \n Команды для управления сервером: \n Бан по IP: /banip [IP] \n Разбан по IP: /unbanip [IP] \n Бан по серийному номеру: /banserial [serial] \n Разбан по серийному номеру: /unbanserial [serial] \n Установить пароль на сервер: /setpassword [пароль] \n Снять пароль с сервера: /removepassword \n \n Для повторного запуска установщика используйте команду: \n ./setup.sh \n \n Команды для запуска сервера в PuTTY \n 1 - cd /root/next \n 2 - screen -S next \n 3 - ./mta-server64 \n \n Если сервер уже запущен, войти в консоль PuTTY \n 1 - screen -x next" > info_nextrp.txt
		log_n "================== Установка Сборки NEXTRP успешно завершена =================="
		Ошибка_n "${blue}BY TANJIRO"
		Ошибка_n ""
		Ошибка_n "${green}База данных - ${white}http://$IP_SERV/phpmyadmin/"
		Ошибка_n "${green}Логин - ${white}admin"
		Ошибка_n "${green}Пароль - ${white}$PASSBAZ"
		Ошибка_n ""
		Ошибка_n "${green}SFTP Доступ - ${white}$IP_SERV"
		Ошибка_n "${green}Логин - ${white}root"
		Ошибка_n "${green}Пароль - ${white}от вашей VDS, не от базы-данных"
		Ошибка_n "${green}Порт - ${white}22"
		Ошибка_n ""
		Ошибка_n "${green}Панель управления:"
		Ошибка_n "${green}Логин: ${white}admin"
		Ошибка_n "${green}Пароль: ${white}$ADMIN_PASS"
		Ошибка_n ""
		Ошибка_n "${green}IP и порт для входа в игру: ${white}$IP_SERV:22003"
		Ошибка_n ""
		Ошибка_n "${green}Команды для управления сервером:"
		Ошибка_n "${white}Бан по IP: /banip [IP]"
		Ошибка_n "${white}Разбан по IP: /unbanip [IP]"
		Ошибка_n "${white}Бан по серийному номеру: /banserial [serial]"
		Ошибка_n "${white}Разбан по серийному номеру: /unbanserial [serial]"
		Ошибка_n "${white}Установить пароль на сервер: /setpassword [пароль]"
		Ошибка_n "${white}Снять пароль с сервера: /removepassword"
		Ошибка_n ""
		Ошибка_n "${green}Для повторного запуска установщика используйте команду:"
		Ошибка_n "${white}./setup.sh"
		Ошибка_n ""
		Ошибка_n "${green}Сервер уже запущен ${white}IP: $IP_SERV:22003"
		Ошибка_n "${green}Данные успешно скопированы в файл! Путь к файлу: ${white}/root/info_nextrp.txt"
		Ошибка_n ""
		Ошибка_n "${red}BY TANJIRO"
		log_n "================== Установка Сборки NEXTRP успешно завершена =================="
		Info
		Info "- ${white}2 ${green}- ${white}Выход в главное меню"
		Info "- ${white}1 ${green}- ${white}Animesnik#7567"
		Info "- ${white}0 ${green}- ${white}Выход из установщика"
		log_s
		Info
		read -p "Пожалуйста, введите пункт меню: " case
		case $case in
		  2) menu;;
		  0) exit;;
		esac
}

menu_install_next_build()
{
 clear
 cp_s
 log_tt "${white}Выберите версию"
 Info "- ${white}1 ${green}- ${white}Ручная установка и подключение всей сборки ${red}NEXT RP"
 Info "- ${white}0 ${green}- ${white}Назад"
 log_s
 Info
 read -p "Пожалуйста, введите пункт меню: " case
 case $case in
  1) install_nextrp;;      
  0) menu;;
 esac
}	

menu()
{
 clear
 cp_s
 log_tt "${white}Автоустановщик ${red}сборок,скриптов,билдов ${white}и т.п. для ${BLUE}MTA ${white}на ${BLUE}Ubuntu 20.04"
 Info "- ${white}1 ${green}- ${white}Автоматическая установка и подключение всей сборки ${red}NEXT RP"
 Info "- ${white}2 ${green}- ${white}Установка FTP сервера"
 Info "- ${white}0 ${green}- ${white}Выход"
 log_s
 Info
 read -p "Пожалуйста, введите пункт меню: " case
 case $case in
  1) menu_install_next_build;;
  2) install_ftp;;      
  0) exit;;
 esac
}

if [ "$1" != "installed" ]; then
    clear
    cp_s
    log_tt "${white}Добро пожаловать в установщик NEXTRP"
    log_n "${green}Для начала установки введите команду: ${white}./setup.sh install"
    log_n "${green}После завершения установки вы сможете запускать сервер командой: ${white}./setup.sh"
    log_s
    exit
elif [ "$1" = "install" ]; then
    menu
else
    cd /root/next
    screen -S next -d -m
    screen -S next -X exec ./mta-server64
    echo "${green}Сервер NEXTRP запущен!"
    echo "${white}Для подключения к консоли сервера используйте команду: screen -x next"
fi