#!/bin/bash

# URL для получения JSON данных
URL="https://alps.dill.xyz/api/trpc/stats.getAllValidators?input=%7B%22json%22%3Anull%2C%22meta%22%3A%7B%22values%22%3A%5B%22undefined%22%5D%7D%7D"

# Файлы
PUBLIC_KEYS_FILE="public_keys.txt"
PREVIOUS_BALANCES_FILE="previous_balances.txt"
LOG_FILE="balance_log.txt"

# Функция для получения JSON данных и извлечения балансов
fetch_balances() {
    curl -s "$URL" | jq -r '.result.data.json.data[] | select(.validator.pubkey != null and .balance != null) | "\(.validator.pubkey) \(.balance)"'
}

# Функция для загрузки предыдущих балансов из файла в ассоциативный массив
load_previous_balances() {
    declare -A balances
    if [[ -f "$PREVIOUS_BALANCES_FILE" ]]; then
        while IFS=" " read -r pubkey balance; do
            balances["$pubkey"]="$balance"
        done < "$PREVIOUS_BALANCES_FILE"
    fi
    echo "$(declare -p balances)"
}

# Функция для сохранения текущих балансов в файл
save_current_balances() {
    local -n balances_ref=$1
    > "$PREVIOUS_BALANCES_FILE"
    for pubkey in "${!balances_ref[@]}"; do
        echo "$pubkey ${balances_ref[$pubkey]}" >> "$PREVIOUS_BALANCES_FILE"
    done
}

# Основной цикл
while true; do
    # Получение текущих балансов
    declare -A current_balances
    while IFS=" " read -r pubkey balance; do
        current_balances["$pubkey"]="$balance"
    done < <(fetch_balances)

    # Загрузка предыдущих балансов
    eval "$(load_previous_balances)"
    declare -A previous_balances=()
    for key in "${!balances[@]}"; do
        previous_balances["$key"]="${balances[$key]}"
    done

    # Логирование времени проверки
    next_check_time=$(date -d "+4 hours" +"%Y-%m-%d %H:%M:%S")
    echo "Next check at: $next_check_time" >> "$LOG_FILE"
    echo -e "\e[1;34mNext check at: $next_check_time\e[0m"

    # Сравнение балансов и логирование различий
    while IFS= read -r pubkey || [[ -n "$pubkey" ]]; do
        pubkey="0x$pubkey"
        if [[ -v current_balances["$pubkey"] ]]; then
            curr_balance=${current_balances["$pubkey"]}
            if [[ -v previous_balances["$pubkey"] ]]; then
                prev_balance=${previous_balances["$pubkey"]}
                difference=$((curr_balance - prev_balance))
                echo "Pubkey: $pubkey, Previous Balance: $prev_balance, Current Balance: $curr_balance, Difference: $difference" >> "$LOG_FILE"
                echo -e "\e[1;32mPubkey: $pubkey\e[0m\n  \e[1;33mPrevious Balance:\e[0m $prev_balance\n  \e[1;33mCurrent Balance:\e[0m $curr_balance\n  \e[1;33mDifference:\e[0m $difference"
            else
                echo "Pubkey: $pubkey, Current Balance: $curr_balance, No previous balance available" >> "$LOG_FILE"
                echo -e "\e[1;32mPubkey: $pubkey\e[0m\n  \e[1;33mCurrent Balance:\e[0m $curr_balance\n  \e[1;31mNo previous balance available\e[0m"
            fi
        else
            echo -e "\e[1;31mPubkey: $pubkey not found in the current data\e[0m"
        fi
    done < "$PUBLIC_KEYS_FILE"

    # Сохранение текущих балансов для следующей проверки
    save_current_balances current_balances

    # Ожидание 4 часов перед следующей проверкой
    sleep 14440
done
