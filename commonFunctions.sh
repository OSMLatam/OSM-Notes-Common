#!/bin/bash

# Common Functions for OSM-Notes-profile
# This file contains functions used across all scripts in the project.
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-13
VERSION="2025-12-13"

# shellcheck disable=SC2317,SC2155,SC2034

# Error codes (common across all scripts)
# shellcheck disable=SC2034
if [[ -z "${ERROR_HELP_MESSAGE:-}" ]]; then declare -r ERROR_HELP_MESSAGE=1; fi
if [[ -z "${ERROR_PREVIOUS_EXECUTION_FAILED:-}" ]]; then declare -r ERROR_PREVIOUS_EXECUTION_FAILED=238; fi
if [[ -z "${ERROR_CREATING_REPORT:-}" ]]; then declare -r ERROR_CREATING_REPORT=239; fi
if [[ -z "${ERROR_MISSING_LIBRARY:-}" ]]; then declare -r ERROR_MISSING_LIBRARY=241; fi
if [[ -z "${ERROR_INVALID_ARGUMENT:-}" ]]; then declare -r ERROR_INVALID_ARGUMENT=242; fi
if [[ -z "${ERROR_LOGGER_UTILITY:-}" ]]; then declare -r ERROR_LOGGER_UTILITY=243; fi
if [[ -z "${ERROR_DOWNLOADING_BOUNDARY_ID_LIST:-}" ]]; then declare -r ERROR_DOWNLOADING_BOUNDARY_ID_LIST=244; fi
if [[ -z "${ERROR_NO_LAST_UPDATE:-}" ]]; then declare -r ERROR_NO_LAST_UPDATE=245; fi
if [[ -z "${ERROR_PLANET_PROCESS_IS_RUNNING:-}" ]]; then declare -r ERROR_PLANET_PROCESS_IS_RUNNING=246; fi
if [[ -z "${ERROR_DOWNLOADING_NOTES:-}" ]]; then declare -r ERROR_DOWNLOADING_NOTES=247; fi
if [[ -z "${ERROR_EXECUTING_PLANET_DUMP:-}" ]]; then declare -r ERROR_EXECUTING_PLANET_DUMP=248; fi
if [[ -z "${ERROR_DOWNLOADING_BOUNDARY:-}" ]]; then declare -r ERROR_DOWNLOADING_BOUNDARY=249; fi
if [[ -z "${ERROR_GEOJSON_CONVERSION:-}" ]]; then declare -r ERROR_GEOJSON_CONVERSION=250; fi
if [[ -z "${ERROR_INTERNET_ISSUE:-}" ]]; then declare -r ERROR_INTERNET_ISSUE=251; fi
if [[ -z "${ERROR_DATA_VALIDATION:-}" ]]; then declare -r ERROR_DATA_VALIDATION=252; fi
if [[ -z "${ERROR_GENERAL:-}" ]]; then declare -r ERROR_GENERAL=255; fi

# Show help function
function __show_help() {
 echo "Common Functions for OSM-Notes-profile"
 echo "This file contains functions used across all scripts in the project."
 echo
 echo "Usage: source bin/commonFunctions.sh"
 echo
 echo "Available functions:"
 echo "  __log*          - Logging functions"
 echo "  __validation    - Input validation"
 echo "  __checkPrereqsCommands - Prerequisites check"
 echo "  Note: __trapOn is now only available in executable scripts, not in this library"
 echo
 echo "Author: Andres Gomez (AngocA)"
 echo "Version: ${VERSION}"
 exit "${ERROR_HELP_MESSAGE}"
}

# Common variables
# shellcheck disable=SC2034
if [[ -z "${GENERATE_FAILED_FILE:-}" ]]; then declare GENERATE_FAILED_FILE=true; fi
# Create a unique failed execution file name based on script name
# Only define if not already set by the calling script
if [[ -z "${FAILED_EXECUTION_FILE:-}" ]]; then
 # Try to get the calling script name from BASH_SOURCE
 if [[ ${#BASH_SOURCE[@]} -gt 1 ]]; then
  # Get the calling script (index 1) instead of this script (index 0)
  SCRIPT_NAME=$(basename "${BASH_SOURCE[1]:-unknown_script}" .sh)
 else
  # Fallback to current script if no calling context
  SCRIPT_NAME=$(basename "${BASH_SOURCE[0]:-unknown_script}" .sh)
 fi
 if [[ -z "${FAILED_EXECUTION_FILE:-}" ]]; then
  declare -r FAILED_EXECUTION_FILE="/tmp/${SCRIPT_NAME}_failed_execution"
 fi
fi
if [[ -z "${PREREQS_CHECKED:-}" ]]; then declare PREREQS_CHECKED=false; fi

# Logger framework
# shellcheck disable=SC2034
if [[ -z "${SCRIPT_BASE_DIRECTORY:-}" ]]; then
 # Try to find the project root by looking for the project directory
 CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 if [[ "${CURRENT_DIR}" == */bin ]]; then
  SCRIPT_BASE_DIRECTORY="$(cd "${CURRENT_DIR}/.." && pwd)"
 elif [[ "${CURRENT_DIR}" == */lib/osm-common ]]; then
  # We're in lib/osm-common, go up two levels to project root
  SCRIPT_BASE_DIRECTORY="$(cd "${CURRENT_DIR}/../.." && pwd)"
 else
  SCRIPT_BASE_DIRECTORY="$(cd "${CURRENT_DIR}/../.." && pwd)"
 fi
fi

# Load bash logger functions - this provides all logging functionality
if [[ -f "${SCRIPT_BASE_DIRECTORY}/lib/osm-common/bash_logger.sh" ]]; then
 # shellcheck source=lib/osm-common/bash_logger.sh
 source "${SCRIPT_BASE_DIRECTORY}/lib/osm-common/bash_logger.sh"
else
 # If bash_logger.sh is not available, this is a critical error
 # We should fail fast rather than provide fallback implementations
 echo "ERROR: Required logging library not found: ${SCRIPT_BASE_DIRECTORY}/lib/osm-common/bash_logger.sh" >&2
 echo "ERROR: This library is essential for proper operation" >&2
 exit "${ERROR_LOGGER_UTILITY}"
fi

# Logger initialization function
# This function initializes the logger system and sets up logging
# Parameters: None
# Returns: None
function __start_logger {
 # Silently initialize logger - only log errors
 # Set log level from environment if not already set
 if [[ -n "${LOG_LEVEL:-}" ]]; then
  __set_log_level "${LOG_LEVEL}"
 fi

 # Set log file if LOG_FILE environment variable is set
 if [[ -n "${LOG_FILE:-}" ]]; then
  __set_log_file "${LOG_FILE}"
 fi
}

##
# Validates that a required parameter is not empty
# Simple validation function that checks if a parameter is empty and exits
# with ERROR_INVALID_ARGUMENT if validation fails. Used for basic parameter validation.
#
# Parameters:
#   $1: Value to validate - The value to check (required)
#   $2: Error message - Error message to display if validation fails (required)
#
# Returns:
#   Exits with ERROR_INVALID_ARGUMENT if value is empty
#   Returns 0 if value is not empty
#
# Error codes:
#   0: Success - Value is not empty
#   ERROR_INVALID_ARGUMENT: Failure - Value is empty (exits script)
#
# Error conditions:
#   0: Success - Value is not empty, validation passes
#   ERROR_INVALID_ARGUMENT: Empty value - First parameter is empty string
#
# Context variables:
#   Reads:
#     - ERROR_INVALID_ARGUMENT: Error code for invalid arguments (defined in commonFunctions.sh)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Writes error message to stdout if validation fails
#   - Exits script with ERROR_INVALID_ARGUMENT if value is empty
#   - Writes log messages to stderr
#   - No file, database, or network operations
#
# Notes:
#   - Simple validation - only checks for empty string
#   - Exits script immediately on failure (does not return)
#   - Use for critical parameter validation at script start
#   - For more complex validation, use specialized validation functions
#
# Example:
#   __validation "${DBNAME}" "Database name is required"
#   __validation "${INPUT_FILE}" "Input file path is required"
#
# Related: __validate_input_file() (file validation)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validation {
 __log_start
 if [[ "${1}" == "" ]]; then
  echo "ERROR: ${2}"
  __log_finish
  exit "${ERROR_INVALID_ARGUMENT}"
 fi
 __log_finish
}

##
# Checks that all required system commands are available
# Validates that essential commands required by the OSM-Notes system are installed
# and available in PATH. Exits with ERROR_MISSING_LIBRARY if any required command
# is missing. This function should be called early in script execution.
#
# Parameters:
#   None (checks predefined list of commands)
#
# Returns:
#   Exits with ERROR_MISSING_LIBRARY if any required command is missing
#   Returns 0 if all commands are available
#
# Error codes:
#   0: Success - All required commands are available
#   ERROR_MISSING_LIBRARY: Failure - One or more required commands are missing (exits script)
#
# Error conditions:
#   0: Success - All required commands found in PATH
#   ERROR_MISSING_LIBRARY: Missing commands - One or more required commands not found
#
# Context variables:
#   Reads:
#     - ERROR_MISSING_LIBRARY: Error code for missing library/command (defined in commonFunctions.sh)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Executes command -v for each required command
#   - Writes log messages to stderr
#   - Exits script with ERROR_MISSING_LIBRARY if commands are missing
#   - No file, database, or network operations
#
# Commands checked:
#   Required:
#     - psql: PostgreSQL client
#     - curl: HTTP client
#     - grep: Text search
#     - free, uptime, ulimit, prlimit, bc, timeout: System utilities
#     - jq: JSON processor
#     - ogr2ogr, gdalinfo: Geospatial tools
#   Optional (warns only):
#     - xmllint: XML validator (optional, can skip with SKIP_XML_VALIDATION=true)
#
# Notes:
#   - Should be called early in script execution
#   - Exits script immediately if commands are missing
#   - xmllint is optional and only generates a warning
#   - All other commands are required and cause script exit if missing
#
# Example:
#   __checkPrereqsCommands
#   # Script continues only if all commands are available
#
# Related: __checkPrereqs_functions() (function availability check)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __checkPrereqsCommands {
 __log_start
 __logd "Checking prerequisites commands."

 # Check if required commands are available
 local MISSING_COMMANDS=()

 # Check basic commands (required)
 for CMD in psql curl grep; do
  if ! command -v "${CMD}" > /dev/null 2>&1; then
   MISSING_COMMANDS+=("${CMD}")
  fi
 done

 # Check optional commands (for XML validation)
 # xmllint is optional - validation can be skipped with SKIP_XML_VALIDATION=true
 if ! command -v xmllint > /dev/null 2>&1; then
  __logw "xmllint not available - XML validation will be skipped (set SKIP_XML_VALIDATION=true to suppress this warning)"
 fi

 # Check parallel processing commands
 for CMD in free uptime ulimit prlimit bc timeout; do
  if ! command -v "${CMD}" > /dev/null 2>&1; then
   MISSING_COMMANDS+=("${CMD}")
  fi
 done

 # Check JSON processing commands
 if ! command -v jq > /dev/null 2>&1; then
  MISSING_COMMANDS+=("jq")
 fi

 # Check geospatial processing commands
 for CMD in ogr2ogr gdalinfo; do
  if ! command -v "${CMD}" > /dev/null 2>&1; then
   MISSING_COMMANDS+=("${CMD}")
  fi
 done

 # Report missing commands
 if [[ ${#MISSING_COMMANDS[@]} -gt 0 ]]; then
  __loge "ERROR: Missing required commands: ${MISSING_COMMANDS[*]}"
  exit "${ERROR_MISSING_LIBRARY}"
 fi

 __logi "All required commands are available."
 __log_finish
}

##
# Checks that all required Bash functions are available
# Validates that essential functions required by the OSM-Notes system are defined
# and available. Exits with ERROR_MISSING_LIBRARY if any required function is missing.
# This function is useful for verifying that required libraries have been sourced.
#
# Parameters:
#   None (checks predefined list of functions)
#
# Returns:
#   Exits with ERROR_MISSING_LIBRARY if any required function is missing
#   Returns 0 if all functions are available
#
# Error codes:
#   0: Success - All required functions are available
#   ERROR_MISSING_LIBRARY: Failure - One or more required functions are missing (exits script)
#
# Error conditions:
#   0: Success - All required functions are defined
#   ERROR_MISSING_LIBRARY: Missing functions - One or more required functions not defined
#
# Context variables:
#   Reads:
#     - ERROR_MISSING_LIBRARY: Error code for missing library/function (defined in commonFunctions.sh)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Executes declare -f for each required function
#   - Writes log messages to stderr
#   - Exits script with ERROR_MISSING_LIBRARY if functions are missing
#   - No file, database, or network operations
#
# Functions checked:
#   Required logger functions:
#     - __log: Basic logging function
#     - __logi: Info logging function
#     - __loge: Error logging function
#
# Notes:
#   - Should be called after sourcing required libraries
#   - Exits script immediately if functions are missing
#   - Useful for verifying library dependencies
#   - Currently checks only logger functions (can be extended)
#
# Example:
#   source "${SCRIPT_BASE_DIRECTORY}/lib/osm-common/commonFunctions.sh"
#   __checkPrereqs_functions
#   # Script continues only if all functions are available
#
# Related: __checkPrereqsCommands() (command availability check)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __checkPrereqs_functions {
 __log_start
 __logd "Checking prerequisites functions."

 # Check if required functions are available
 local MISSING_FUNCTIONS=()

 # Check logger functions
 for FUNC in __log __logi __loge; do
  if ! declare -f "${FUNC}" > /dev/null 2>&1; then
   MISSING_FUNCTIONS+=("${FUNC}")
  fi
 done

 # Report missing functions
 if [[ ${#MISSING_FUNCTIONS[@]} -gt 0 ]]; then
  __loge "ERROR: Missing required functions: ${MISSING_FUNCTIONS[*]}"
  exit "${ERROR_MISSING_LIBRARY}"
 fi

 __logi "All required functions are available."
 __log_finish
}

# Drop generic objects
function __dropGenericObjects {
 __log_start
 __logd "Dropping generic objects."

 # Validate that POSTGRES_12_DROP_GENERIC_OBJECTS is defined
 if [[ -z "${POSTGRES_12_DROP_GENERIC_OBJECTS:-}" ]]; then
  __loge "ERROR: POSTGRES_12_DROP_GENERIC_OBJECTS variable is not defined. This variable should be defined in the calling script"
  exit "${ERROR_MISSING_LIBRARY}"
 fi

 # Validate that the SQL file exists
 if [[ ! -f "${POSTGRES_12_DROP_GENERIC_OBJECTS}" ]]; then
  __loge "ERROR: SQL file not found: ${POSTGRES_12_DROP_GENERIC_OBJECTS}"
  exit "${ERROR_MISSING_LIBRARY}"
 fi

 # Validate that DBNAME is defined
 if [[ -z "${DBNAME:-}" ]]; then
  __loge "ERROR: DBNAME variable is not defined. This variable should be defined in the calling script"
  exit "${ERROR_MISSING_LIBRARY}"
 fi

 psql -d "${DBNAME}" -f "${POSTGRES_12_DROP_GENERIC_OBJECTS}"
 __log_finish
}

# Set log file for output redirection
# Parameters:
#   $1 - Log file path
# Returns:
#   0 if successful, 1 if failed
function __set_log_file() {
 local LOG_FILE="${1}"

 if [[ -z "${LOG_FILE}" ]]; then
  __loge "ERROR: Log file path not provided"
  return 1
 fi

 # Create directory if it doesn't exist
 local LOG_DIR
 LOG_DIR=$(dirname "${LOG_FILE}")
 if [[ ! -d "${LOG_DIR}" ]]; then
  mkdir -p "${LOG_DIR}" 2> /dev/null || {
   __loge "ERROR: Cannot create log directory: ${LOG_DIR}"
   return 1
  }
 fi

 # Ensure the log file is writable
 touch "${LOG_FILE}" 2> /dev/null || {
  __loge "ERROR: Cannot create or write to log file: ${LOG_FILE}"
  return 1
 }

 # Set logger file descriptor so __output_log (bash_logger) writes to this file.
 # Without this, __log_fd is never set and log lines may not appear in the log file.
 if declare -p __log_fd &>/dev/null 2>&1; then
  exec {__log_fd}>> "${LOG_FILE}"
 fi
 return 0
}
