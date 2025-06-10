#!/usr/bin/env bash
set -e  # Остановить выполнение при ошибке

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ENDCOLOR='\033[0m'

# Цветные echo
print_blue()  { echo -e "${BLUE}${1}${ENDCOLOR}"; }
print_green() { echo -e "${GREEN}${1}${ENDCOLOR}"; }
print_red()   { echo -e "${RED}${1}${ENDCOLOR}"; }

# Печать баннера
print_banner() {
    print_blue "_  _   ___   _____   ___   ___ ___  ___     _   ___ __  __ "
    print_blue "| || | /_\ \ / / _ \ / __| | __/ _ \| _ \   /_\ | _ \  \/  |"
    print_blue "| __ |/ _ \ V / (_) | (__  | _| (_) |   /  / _ \|   / |\/| |"
    print_blue "|_||_/_/ \_\_/ \___/ \___| |_| \___/|_|_\ /_/ \_\_|_\_|  |_|"
    print_blue "                                                            "
}

# Проверка пакетов
check_package() {
    if dpkg -s "$1" &> /dev/null; then
        print_green "Package $1 is already installed."
    else
        print_red "Installing missing package: $1"
        sudo apt-get install -y "$1"
    fi
}

# Установка pyenv при необходимости
install_pyenv() {
    if command -v pyenv >/dev/null 2>&1; then
        print_green "pyenv уже установлен."
        return
    fi

    print_blue "Устанавливаем pyenv..."
    curl -fsSL https://pyenv.run | bash

    # Настройка окружения
    {
        echo 'export PYENV_ROOT="$HOME/.pyenv"'
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
        echo 'eval "$(pyenv init --path)"'
    } >> ~/.bashrc

    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
}

# Клонирование репозитория Havoc
clone_repo() {
    local branch=$1
    if [ ! -d "Havoc" ]; then
        print_blue "Клонируем репозиторий Havoc (ветка: $branch)..."
        git clone -b "$branch" https://github.com/HavocFramework/Havoc.git Havoc
        print_green "Клонирование завершено!"
    else
        print_green "Папка Havoc уже существует, пропускаем клонирование."
    fi
}

# Сборка teamserver
build_teamserver_binary() {
    cd teamserver
    go mod tidy
    go mod download
    cd ..
    make ts-build && print_green "Teamserver собран." || print_red "Ошибка сборки teamserver."
}

# Сборка клиента
build_client_binary() {
    make client-build && print_green "Client собран." || print_red "Ошибка сборки client."
}

# Проверка системы и запуск сборки
main() {
    print_banner

    sudo -v # Проверка sudo

    print_blue "Проверяем характеристики системы..."
    total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024 / 1024}')
    cpu_cores=$(nproc)
    echo "RAM: ${total_ram} GB | CPU cores: $cpu_cores"

    if (( $(echo "$total_ram < 4" | bc -l) )); then
        print_red "Предупреждение: RAM < 4GB — сборка может быть медленной."
    fi
    if [ "$cpu_cores" -lt 4 ]; then
        print_red "Предупреждение: < 4 ядер — сборка может быть медленной."
    fi

    # Пакеты
    apt_packages=(
        qemu-user-static binfmt-support git build-essential apt-utils cmake
        libfontconfig1 libglu1-mesa-dev libgtest-dev libspdlog-dev libboost-all-dev
        libncurses-dev libgdbm-dev libssl-dev libreadline-dev libffi-dev
        libsqlite3-dev libbz2-dev mesa-common-dev qtbase5-dev qtchooser
        qt5-qmake qtbase5-dev-tools libqt5websockets5 libqt5websockets5-dev
        qtdeclarative5-dev golang-go python3-dev mingw-w64 nasm bc
    )

    print_blue "Проверка и установка необходимых пакетов..."
    for pkg in "${apt_packages[@]}"; do
        check_package "$pkg"
    done

    # Проверка версии Python
    required_version="3.10"
    py_version=$(python3 --version 2>&1 | awk '{print $2}')
    if [[ "$py_version" != "$required_version" ]]; then
        print_red "Требуется Python $required_version, найдено $py_version"
        read -p "Установить Python $required_version через pyenv? (y/n): " yn
        [[ "$yn" =~ ^[Yy]$ ]] && install_pyenv
    else
        print_green "Python $required_version уже установлен."
    fi

    # Выбор ветки
    print_blue "Выберите ветку для клонирования:"
    echo "1) Stable (main)"
    echo "2) Development (dev)"
    read -p "Ваш выбор (1/2): " choice
    case "$choice" in
        1) clone_repo "main" ;;
        2) print_red "Предупреждение: ветка dev может быть нестабильной"; clone_repo "dev" ;;
        *) print_red "Неверный выбор, выход..."; exit 1 ;;
    esac

    # Переход в каталог
    cd Havoc

    # Патч для CVE
    sed -i '/case COMMAND_SOCKET:/,/return true/d' teamserver/pkg/agent/agent.go

    # Сборка
    [ ! -f "havoc" ] && build_teamserver_binary || print_green "Teamserver уже собран."
    [ ! -f "client/Havoc" ] && build_client_binary || print_green "Client уже собран."
}

main

