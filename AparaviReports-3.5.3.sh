#!/bin/bash
# Function to install JQ
install_jq() {
    echo "JQ is not installed. Installing JQ..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y jq
    elif command -v yum &>/dev/null; then
        sudo yum install -y epel-release
        sudo yum install -y jq
    elif command -v zypper &>/dev/null; then
        sudo zypper --non-interactive install jq
    else
        echo "Could not find a package manager to install JQ. Please install JQ manually and re-run this script."
        exit 1
    fi

    echo "JQ has been installed successfully."
}

# Check if JQ is installed
if ! command -v jq &>/dev/null; then
    install_jq
fi

# Path to the settings JSON file
settingsFile="settings.json"

# Get the directory where the script is executed
scriptDir=$(dirname "$(readlink -f "$BASH_SOURCE")")

# Default value for saved reports
defaultSaveReports="$scriptDir/Reports"

# Check if the settings JSON file exists
if [ -f "$settingsFile" ]; then
  # Load settings from the JSON file
  settings=$(cat "$settingsFile")
else
  # Prompt for the settings if the JSON file doesn't exist
  echo "Please provide the following settings:"
  read -p "Aparavi User: " aparaviuser

  # Prompt for password (twice) to confirm
  while true; do
    read -s -p "Password: " password
    echo
    read -s -p "Confirm Password: " password_confirm
    echo

    if [ "$password" == "$password_confirm" ]; then
      break
    else
      echo "Passwords do not match. Please try again."
    fi
  done

  read -p "Platform: " platform

  # Prompt for the save reports location with default option
  read -e -p "Save Reports To [$defaultSaveReports]: " savereports
  savereports="${savereports:-$defaultSaveReports}"

  # Set default report export to "reports.json"
  reportexport="reports.json"

  # Prompt for the format with default option
  options=("csv" "json")
  default_option=1
  PS3="Select Format (default: csv): "
  select opt in "${options[@]}"; do
    format=${opt:-${options[default_option]}}
    break
  done

  # Create base64AuthInfo
  base64AuthInfo=$(echo -n "$aparaviuser:$password" | base64)

  # Create the settings JSON object
  settings=$(jq -n --arg auth "$base64AuthInfo" --arg platform "$platform" --arg savereports "$savereports" --arg report "$reportexport" --arg format "$format" '{base64AuthInfo: $auth, platform: $platform, savereports: $savereports, reportexport: $report, format: $format}')

  # Save the settings to the JSON file
  echo "$settings" >"$settingsFile"
fi

# Load individual settings from the JSON object
base64AuthInfo=$(echo "$settings" | jq -r '.base64AuthInfo')
platform=$(echo "$settings" | jq -r '.platform')
savereports=$(echo "$settings" | jq -r '.savereports')
reportexport=$(echo "$settings" | jq -r '.reportexport')
format=$(echo "$settings" | jq -r '.format')

# Get the current working directory
currentDirectory=$(pwd)

# Set the Report Export JSON
configlocation="$currentDirectory/$reportexport"

# Set the folder name
folderName="reports"

# Construct the file path to the reports folder
reportFolder="$currentDirectory/$folderName"

# Check if the reports folder already exists
if [ ! -d "$reportFolder" ]; then
    # Create the reports folder if it does not exist
    mkdir -p "$reportFolder"
fi

# Set up the log file
logFile="$reportFolder/aparavi_reports_log.txt"
exec > >(tee -a "$logFile") 2>&1


# Display Settings
echo "Aparavi Reports v3.5.3"
echo "Aparavi User: $aparaviuser"
echo "Platform: $platform"
echo "Format: $format"
echo "Reports will be saved to: $reportFolder"

# Let's get this part started
timestamp=$(date "+%Y-%m-%d %H%M%S")
echo "$timestamp - Starting Reports"


# Read the report URI and name from the JSON file
report_data=$(cat "$configlocation")
report_ids=$(echo "$report_data" | jq -r 'keys[]')

# Generate the reports
uri_template="http://$platform/server/api/v3/database/query?select=%s&options=%%7B%%22format%%22:%%22$format%%22,%%22stream%%22:true%%7D"

for report_id in $report_ids; do
    reportName=$(echo "$report_data" | jq -r ".[\"$report_id\"].name")
    uri_encoded_query=$(echo "$report_data" | jq -r ".[\"$report_id\"].query.queryDisplay" | jq -sRr @uri)

    uri=$(printf "$uri_template" "$uri_encoded_query")

    timestamp=$(date "+%Y-%m-%d %H%M%S")
    outfile="$reportFolder/${reportName}_$timestamp.$format"

    echo "$timestamp - Generating report $reportName"
    echo "$timestamp - $uri"

    curl -s -H "Authorization: Basic $base64AuthInfo" -o "$outfile" "$uri"
done

# Finish Up
timestamp=$(date "+%Y-%m-%d %H%M%S")
echo "$timestamp - Reports Done"
