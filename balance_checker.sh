#!/bin/bash

# URL to fetch JSON data
URL="https://alps.dill.xyz/api/trpc/stats.getAllValidators?input=%7B%22json%22%3Anull%2C%22meta%22%3A%7B%22values%22%3A%5B%22undefined%22%5D%7D%7D"
# File containing public keys (one key per line)
PUBLIC_KEYS_FILE="public_keys.txt"
# File to store previous balances
PREVIOUS_BALANCES_FILE="previous_balances.txt"
# Log file
LOG_FILE="balance_log.txt"

# Function to fetch the JSON data and extract balances
fetch_balances() {
    curl -s "$URL" | jq -r '.result.data.json.data[] | select(.validator.pubkey != null and .balance != null) | "\(.validator.pubkey) \(.balance)"'
}

# Function to load previous balances from file into an associative array
load_previous_balances() {
    declare -A balances
    if [[ -f "$PREVIOUS_BALANCES_FILE" ]]; then
        while IFS=" " read -r pubkey balance; do
            balances["$pubkey"]="$balance"
        done < "$PREVIOUS_BALANCES_FILE"
    fi
    echo "$(declare -p balances)"
}

# Function to save current balances to file
save_current_balances() {
    declare -A balances=$1
    > "$PREVIOUS_BALANCES_FILE"
    while IFS= read -r pubkey; do
        pubkey="0x$pubkey"
        if [[ -v balances[$pubkey] ]]; then
            echo "$pubkey ${balances[$pubkey]}" >> "$PREVIOUS_BALANCES_FILE"
        fi
    done < "$PUBLIC_KEYS_FILE"
}

# Main loop
while true; do
    # Fetch current balances
    declare -A current_balances
    while IFS=" " read -r pubkey balance; do
        current_balances["$pubkey"]="$balance"
    done < <(fetch_balances)

    # Load previous balances
    eval "$(load_previous_balances)"
    declare -A previous_balances=${balances[@]}

    # Log time of the check
    next_check_time=$(date -d "+4 hours" +"%Y-%m-%d %H:%M:%S")
    echo "Next check at: $next_check_time" >> "$LOG_FILE"
    echo -e "\e[1;34mNext check at: $next_check_time\e[0m"

    # Compare balances and log the differences
    while IFS= read -r pubkey; do
        pubkey="0x$pubkey"
        if [[ -v current_balances[$pubkey] ]]; then
            if [[ -v previous_balances[$pubkey] ]]; then
                prev_balance=${previous_balances[$pubkey]}
                curr_balance=${current_balances[$pubkey]}
                difference=$((curr_balance - prev_balance))
                echo "Pubkey: $pubkey, Previous Balance: $prev_balance, Current Balance: $curr_balance, Difference: $difference" >> "$LOG_FILE"
                echo -e "\e[1;32mPubkey: $pubkey\e[0m\n  \e[1;33mPrevious Balance:\e[0m $prev_balance\n  \e[1;33mCurrent Balance:\e[0m $curr_balance\n  \e[1;33mDifference:\e[0m $difference"
            else
                curr_balance=${current_balances[$pubkey]}
                echo "Pubkey: $pubkey, Current Balance: $curr_balance, No previous balance available" >> "$LOG_FILE"
                echo -e "\e[1;32mPubkey: $pubkey\e[0m\n  \e[1;33mCurrent Balance:\e[0m $curr_balance\n  \e[1;31mNo previous balance available\e[0m"
            fi
        else
            echo -e "\e[1;31mPubkey: $pubkey not found in the current data\e[0m"
        fi
    done < "$PUBLIC_KEYS_FILE"

    # Save current balances for the next check
    save_current_balances "$(declare -p current_balances)"

    # Wait for 4 hours before the next check
    sleep 14400
done
