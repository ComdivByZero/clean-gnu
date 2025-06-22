#!/bin/sh

OUTDATE_DAYS="$1"

DO=1

log() { env echo -e "\033[1m[ $* ]\033[0m"; }
run() { echo ';' "$@" \# $echo_param; echo_param=
    if [ "$DO" = 1 ]; then "$@"; echo; fi; }

if command -v trash > /dev/null 2>&1; then
    remove()    { run trash "$1"; }
    after()     { log "Не забудьте очистить корзину, когда убедитесь, что всё в порядке"; }
    noteTrash() { echo "Данные будут удалены в корзину с помощью trash"; }
else
    remove()    { run rm -rf "$1"; }
    after()     { log "Данные были удалены сразу, но лучше установить trash-cli"; }
    noteTrash() { echo "Установите trash-cli для удаления в корзину, а не сразу через rm."; }
fi

clean() {
    log "Удаление из $HOME/.cache/ каталогов с файлами старше $OUTDATE_DAYS дней или пустых"
    for CACHE in "$HOME"/.cache/* "$HOME"/.cache/.?*; do
        if [ "$CACHE" != ".." ] && ! find "$CACHE" -type f -atime -"$OUTDATE_DAYS" 2>&1 | grep -q .; then
            echo_param="$(du -h --summarize $CACHE | awk '{print $1}')";
            remove "$CACHE"
        fi
    done
    after
}

# Go
if ! echo "$1" | grep -qE '^[0-9]+$'; then
    echo "Чистка кэша в $HOME. Лучше выйти из всех приложений."
    noteTrash
    echo "Для очистки запустите с количеством дней устаревания содержимого, например"
    echo "   $0 90"
    echo "Для просмотра команд очистки без их выполнения:"
    echo "   $0 90 show"
else
    [ "$2" = show ] && DO=0
    clean
fi
