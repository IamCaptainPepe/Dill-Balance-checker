# Validator Balance Tracker

This script periodically checks the balance of validators by querying a specified URL for JSON data. It then compares the current balance to the previous balance and logs the results.

## Prerequisites

- **curl**: Required to fetch the JSON data from the URL.
- **jq**: Used to parse the JSON response.

## Setup and Usage

1. **Edit Public Keys**:
   ```bash
   nano public_keys.txt
   ```
   Add each public key on a separate line (without the `0x` prefix).

2. **Create a Screen Session**:
   ```bash
   screen -S balance_checker
   ```


3. **Download and Run Script in One Command**:
   ```bash
   wget https://github.com/IamCaptainPepe/Dill-Balance-checker/raw/main/balance_checker.sh && chmod +x balance_checker.sh && ./balance_checker.sh
   ```


   To detach from the screen session, press `CTRL+A` followed by `D`. To reattach, use:
   ```bash
   screen -r balance_checker
   ```
## Notes

- **Infinite Loop**: The script runs in an infinite loop. To stop it, use `CTRL+C`.
- **Modify Interval**: You can modify the time interval by changing the `sleep 14400` command (14400 seconds = 4 hours).

## Dependencies

- **curl**: For making HTTP requests.
- **jq**: For parsing JSON data.



