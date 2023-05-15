# AparaviReports
Reporting Script for The Aparavi Platform

The given script is a Bash script for generating reports using the Aparavi platform. It performs the following tasks:

Checks if the JQ tool is installed. If not, it installs JQ using the appropriate package manager (apt-get, yum, or zypper).
Sets the path to the settings JSON file.
Checks if the settings JSON file exists. If it does, it loads the settings from the file. Otherwise, it prompts the user to enter the settings manually.
Loads individual settings from the JSON object.
Sets up the necessary directories and log file.
Displays the loaded settings.
Initiates the report generation process.
Reads the report configuration from the JSON file.
Generates reports by making HTTP requests to the Aparavi platform's API endpoint.
Saves the generated reports to the specified directory.
Outputs log messages to both the console and the log file.
The script utilizes the JQ tool for parsing and manipulating JSON data, and it uses curl to make HTTP requests.

Please note that this is a script and may require additional setup, such as configuring the Aparavi platform and providing valid credentials and report configurations in the JSON file.
