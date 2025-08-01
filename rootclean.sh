#!/bin/sh

JOURNAL_SIZE=101M
OUTDATE_CACHE=17
OUTDATE_LOGS=111

DO=1

log() { env echo -e "\033[1m[ $* ]\033[0m"; }
run() { echo ';' "$@"; if [ "$DO" = 1 ]; then "$@"; echo; fi; }

clean() {
    log "Урезание системного лога до $JOURNAL_SIZE"
    run journalctl --vacuum-size=$JOURNAL_SIZE

    log "Удаление файлов в /var/log/ старше $OUTDATE_LOGS дней"
    find /var/log -type f -mtime +$OUTDATE_LOGS |
        while read -r file; do
            run rm -f "$file"
        done

    log "Удаление deb-пакетов — устаревших зависимостей"
    run apt autoremove
    run apt autoclean

    log "Удаление кэша deb-пакетов"
    run apt clean

    if type snap > /dev/null 2>&1; then
        log "Удаление выключенных ревизий snap-пакетов"
        echo '; snap list --all'
        LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
            while read -r snapname revision; do
                run snap remove "$snapname" --revision="$revision"
            done
    fi

    log "Удаление каталогов из /var/cache старше $OUTDATE_CACHE дней"
    for CACHE in /var/cache/*; do
        if ! find "$CACHE" -type f -mtime -$OUTDATE_CACHE | grep -q .; then
            run rm -rf "$CACHE"
        fi
    done
}

# Go
if [ "$(id -u)" -ne 0 ]; then
    echo Чистка кэша и лога системного раздела для дистрибутивов, основанных на Debian.
    echo Лучше выйти из всех приложений. Запустите очистку так:
    echo "    /usr/bin/sudo $0"
    echo "Для просмотра команд очистки без их выполнения:"
    echo "    /usr/bin/sudo $0 show"
else
    [ "$1" = show ] && DO=0
    clean
fi
