#!/bin/sh

clean() {
    #local keep_days now purge_list current_kernel kernel_pkgs vmlinuz_path timestamp age pkg version

    keep_days=$1

    now=$(date +%s)
    purge_list=''

    current_kernel=$(uname -r)

    kernel_pkgs=$(dpkg -l 'linux-image-[0-9]*-generic' | awk '/^ii/ { print $2 }')

    for pkg in $kernel_pkgs; do
        version=$(echo "$pkg" | awk -F'linux-image-' '{ print $2 }')

        if [ "$version" != "$current_kernel" ]; then
            vmlinuz_path=$(dpkg -L "$pkg" | awk "/\/boot\/vmlinuz-$version/"' { print $0; exit }')

            if [ -n "$vmlinuz_path" ]; then
                timestamp=$(stat -c %Y "$vmlinuz_path")
                age=$(( (now - timestamp) / 86400 ))

                if [ "$age" -gt "$keep_days" ]; then
                    purge_list="$purge_list $pkg"
                fi
            fi
        fi
    done

    if [ -n "$purge_list" ]; then
        echo "Текущее ядро — $current_kernel"
        echo /usr/bin/sudo apt purge $purge_list
    fi
}


if ! echo "$1" | grep -qE '^[0-9]+$'; then
    echo Очистка старых версий ядра Linux. Запустите с кол-вом дней хранения ядер:
    echo "    $0 42"
elif [ "$(id -u)" -ne 0 ]; then
    echo "Необходимо запускать от суперпользователя:"
    echo "        /usr/bin/sudo $0 $1"
else
    clean "$1"
fi
