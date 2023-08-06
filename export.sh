#!/bin/bash

# Set the URLs of the API endpoints
RENT_API_URL="https://api.propstack.de/v1/units?api_key=pKU4VNrmuixvfuokIMzIV3cmjGp-5U0hz8uo5xdZ&status=21444&marketing_type=RENT"
BUY_API_URL="https://api.propstack.de/v1/units?api_key=pKU4VNrmuixvfuokIMzIV3cmjGp-5U0hz8uo5xdZ&status=21444&marketing_type=BUY"

# Set the paths to the files where you'll save the last fetched data
SAVED_RENT_DATA_FILE="/root/dydo/pipeline/saved_rent_data.json"
SAVED_BUY_DATA_FILE="/root/dydo/pipeline/saved_buy_data.json"

# Function to fetch data from an API and save it to a file
fetch_and_save_data() {
  local api_url=$1
  local output_file=$2
  curl -s "$api_url" > "$output_file"
}

# Function to compare data with the previously saved data and trigger rebuild
compare_and_handle_changes() {
  local new_data_file=$1
  local saved_data_file=$2

  if cmp -s "$new_data_file" "$saved_data_file"; then
    echo "Data is the same. No changes for $saved_data_file."
  else
    echo "Data has changed. Triggering rebuild and upload process for $saved_data_file..."
    # Add the command here to trigger the rebuild process
    npm run export
    wait  # Wait for the npm run export command to finish

    # After successful build and upload, save the new data for the next comparison
    cp "$new_data_file" "$saved_data_file"

    # Add everything to Git, commit, and push
    git add .
    git commit -m "Automatic update: $(date)"  # Use a meaningful commit message
    git push origin master  # Assuming your branch is named "master"
  fi
}

# Fetch and compare data for RENT API
TMP_RENT_FILE=$(mktemp)
fetch_and_save_data "$RENT_API_URL" "$TMP_RENT_FILE"
compare_and_handle_changes "$TMP_RENT_FILE" "$SAVED_RENT_DATA_FILE"
rm "$TMP_RENT_FILE"

# Fetch and compare data for BUY API
TMP_BUY_FILE=$(mktemp)
fetch_and_save_data "$BUY_API_URL" "$TMP_BUY_FILE"
compare_and_handle_changes "$TMP_BUY_FILE" "$SAVED_BUY_DATA_FILE"
rm "$TMP_BUY_FILE"

