#!/bin/sh

JOURNAL_SIZE=101M
OUTDATE_DAYS=17

log() { echo "\033[1m[ $* ]\033[0m"; }
run() { echo ';' "$@"; "$@"; echo; }

clean() {
    log "Урезание системного лога до $JOURNAL_SIZE"
    run journalctl --vacuum-size=$JOURNAL_SIZE

    log "Удаление deb-пакетов — устаревших зависимостей"
    run apt autoclean
    run apt autoremove

    log "Удаление кэша deb-пакетов"
    run apt clean

    if type snap > /dev/null 2>&1; then
        log "Удаление выключенных старых ревизий snap-пакетов"
        LANG=C run snap list --all | awk '/disabled/{print $1, $3}' |
            while read snapname revision; do
                run snap remove "$snapname" --revision="$revision"
            done
    fi

    log "Удаление каталогов из /var/cache старше $OUTDATE_DAYS дней"
    for CACHE in /var/cache/*; do
        if ! find "$CACHE" -type f -mtime -$OUTDATE_DAYS | grep -q .; then
            run rm -rf "$CACHE"
        fi
    done
}

# Go
if [ "$(id -u)" -ne 0 ]; then
    echo Чистка кэша и лога системного раздела для дистрибутивов, основанных на Debian.
    echo Запустите скрипт через sudo. Лучше выйти из всех приложений.
else
    clean
fi
