#!/bin/bash

# Common functions for failed execution alerts and notifications.
# These functions are used by processAPINotes.sh, processPlanetNotes.sh
# and other scripts to send immediate alerts when critical errors occur.
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-15

# Creates a failed execution marker file with details and sends immediate
# alerts.
# This prevents subsequent executions from running until the issue is resolved.
#
# Parameters:
#   $1 - script_name: Name of the script that failed (e.g., "processAPINotes")
#   $2 - error_code: The error code that triggered the failure
#   $3 - error_message: Description of what failed
#   $4 - required_action: What action is needed to fix it
#   $5 - failed_execution_file: Path to the failed execution marker file
#
# Environment variables:
#   GENERATE_FAILED_FILE: Set to "true" to enable (default)
#   SEND_ALERT_EMAIL: Set to "true" to send email alerts (default: true)
#   ADMIN_EMAIL: Email address for alerts (default: notes@osm.lat)
#   ONLY_EXECUTION: Must be "yes" for alerts to be sent
#   TMP_DIR: Temporary directory for this execution
#   VERSION: Script version
#
# Returns:
#   None (always creates file if conditions are met)
##
# Creates failed execution marker file (common implementation)
# Creates a failed execution marker file to prevent re-execution until issue is resolved.
# Writes error details (timestamp, script name, error code, message, process ID, etc.) to
# marker file. Sends email alert if enabled. Used by all scripts for consistent error handling.
#
# Parameters:
#   $1: SCRIPT_NAME - Name of the script that failed (required)
#   $2: ERROR_CODE - Error code for the failure (required)
#   $3: ERROR_MESSAGE - Error message describing the failure (required)
#   $4: REQUIRED_ACTION - Action required to fix the issue (required)
#   $5: FAILED_FILE_PARAM - Path to failed execution marker file (optional, uses FAILED_EXECUTION_FILE if not provided)
#
# Returns:
#   Always returns 0 (marker creation is non-blocking)
#
# Error codes:
#   0: Success - Marker file created successfully (or skipped if conditions not met)
#
# Error conditions:
#   0: Success - Marker file created or skipped (based on GENERATE_FAILED_FILE and ONLY_EXECUTION)
#
# Context variables:
#   Reads:
#     - FAILED_EXECUTION_FILE: Path to failed execution marker file (used if FAILED_FILE_PARAM not provided)
#     - GENERATE_FAILED_FILE: If "true", creates marker file (optional, default: true)
#     - ONLY_EXECUTION: If "yes", creates marker file (optional, default: "no")
#     - SEND_ALERT_EMAIL: If "true", sends email alert (optional, default: true)
#     - TMP_DIR: Temporary directory (optional)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies:
#     - Creates failed execution marker file (if conditions met)
#
# Side effects:
#   - Creates failed execution marker file with error details
#   - Sends email alert if enabled (via __common_send_failure_email)
#   - Writes log messages to stderr
#   - File operations: Creates marker file
#   - Network operations: Sends email alert (if enabled)
#   - No database operations
#
# Notes:
#   - Marker file contains: timestamp, script name, error code, error message, process ID, temp dir, hostname, required action
#   - Only creates marker file if GENERATE_FAILED_FILE=true AND ONLY_EXECUTION=yes
#   - Email alert is sent automatically if SEND_ALERT_EMAIL=true
#   - Marker file prevents re-execution until manually removed
#   - Critical function: Part of error handling workflow for all scripts
#   - Used by script-specific wrapper functions (e.g., __create_failed_marker)
#
# Example:
#   __common_create_failed_marker "processAPINotes" 250 "Database connection failed" \
#    "Check PostgreSQL service status" "/tmp/processAPINotes_failed_execution"
#   # Creates marker file and sends email alert
#
# Related: __common_send_failure_email() (sends email alert)
# Related: __checkPreviousFailedExecution() (checks for marker file)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __common_create_failed_marker() {
 local SCRIPT_NAME="${1}"
 local ERROR_CODE="${2}"
 local ERROR_MESSAGE="${3}"
 local REQUIRED_ACTION="${4}"
 # Use parameter directly instead of local to avoid readonly conflict
 # FAILED_EXECUTION_FILE may be readonly, so use it directly
 local FAILED_FILE_PARAM="${5}"
 local TIMESTAMP
 TIMESTAMP=$(date)
 local HOSTNAME_VAR
 HOSTNAME_VAR=$(hostname)

 __loge "Creating failed execution marker due to: ${ERROR_MESSAGE}"

 if [[ "${GENERATE_FAILED_FILE:-true}" == "true" ]] \
  && [[ "${ONLY_EXECUTION:-no}" == "yes" ]]; then

  # Use parameter value, fallback to readonly variable if not provided
  local FILE_PATH="${FAILED_FILE_PARAM:-${FAILED_EXECUTION_FILE:-/tmp/unknown_failed_execution}}"

  # Create the failed execution marker file
  {
   echo "Execution failed at ${TIMESTAMP}"
   echo "Script: ${SCRIPT_NAME}"
   echo "Error code: ${ERROR_CODE}"
   echo "Error: ${ERROR_MESSAGE}"
   echo "Process ID: $$"
   echo "Temporary directory: ${TMP_DIR:-unknown}"
   echo "Server: ${HOSTNAME_VAR}"
   echo ""
   echo "Required action: ${REQUIRED_ACTION}"
  } > "${FILE_PATH}"
  __loge "Failed execution file created: ${FILE_PATH}"
  __loge "Remove this file after fixing the issue to allow new executions"

  # Send immediate email alert if enabled
  if [[ "${SEND_ALERT_EMAIL:-true}" == "true" ]]; then
   __common_send_failure_email "${SCRIPT_NAME}" "${ERROR_CODE}" \
    "${ERROR_MESSAGE}" "${REQUIRED_ACTION}" "${FILE_PATH}" \
    "${TIMESTAMP}" "${HOSTNAME_VAR}"
  fi


 else
  __logd "Failed file not created (GENERATE_FAILED_FILE=${GENERATE_FAILED_FILE:-true}, ONLY_EXECUTION=${ONLY_EXECUTION:-no})"
 fi
}

# Sends an email alert about the failed execution.
# This is called automatically by __common_create_failed_marker.
# Uses mutt (required prerequisite for external SMTP).
#
# Parameters:
#   $1 - script_name
#   $2 - error_code
#   $3 - error_message
#   $4 - required_action
#   $5 - failed_execution_file
#   $6 - timestamp
#   $7 - hostname
function __common_send_failure_email() {
 local SCRIPT_NAME="${1}"
 local ERROR_CODE="${2}"
 local ERROR_MESSAGE="${3}"
 local REQUIRED_ACTION="${4}"
 # Use parameter directly instead of local to avoid readonly conflict
 local FAILED_FILE_PARAM="${5}"
 local TIMESTAMP="${6}"
 local HOSTNAME_VAR="${7}"
 local EMAIL_TO="${ADMIN_EMAIL:-notes@osm.lat}"

 # Use parameter value, fallback to readonly variable if not provided
 local FILE_PATH="${FAILED_FILE_PARAM:-${FAILED_EXECUTION_FILE:-/tmp/unknown_failed_execution}}"

 # mutt is a required prerequisite (checked in __checkPrereqsCommands)
 # so it should always be available at this point
 local SUBJECT="ALERT: OSM Notes ${SCRIPT_NAME} Failed - ${HOSTNAME_VAR}"
 local BODY
 BODY=$(cat << EOF
ALERT: OSM Notes Processing Failed
===================================

Script: ${SCRIPT_NAME}.sh
Time: ${TIMESTAMP}
Server: ${HOSTNAME_VAR}
Failed marker file: ${FILE_PATH}

Error Details:
--------------
Error code: ${ERROR_CODE}
Error: ${ERROR_MESSAGE}

Process Information:
--------------------
Process ID: $$
Temporary directory: ${TMP_DIR:-unknown}
Script version: ${VERSION:-unknown}

Action Required:
----------------
${REQUIRED_ACTION}

Recovery Steps:
---------------
1. Read the error details above
2. Follow the required action instructions
3. After fixing, delete the marker file:
   rm ${FILE_PATH}
4. Run the script again to verify the fix

Logs:
-----
Check logs at: ${TMP_DIR}/${SCRIPT_NAME}.log

---
This is an automated alert from OSM Notes Ingestion system.
EOF
)

 # Send email using mutt (required prerequisite)
 local TEMP_BODY_FILE
 TEMP_BODY_FILE=$(mktemp)
 echo "${BODY}" > "${TEMP_BODY_FILE}"
 if echo "" | mutt -s "${SUBJECT}" -i "${TEMP_BODY_FILE}" -- "${EMAIL_TO}" 2>/dev/null; then
  __logi "Email alert sent successfully to ${EMAIL_TO}"
  rm -f "${TEMP_BODY_FILE}"
 else
  __logw "Failed to send email alert to ${EMAIL_TO}"
  rm -f "${TEMP_BODY_FILE}"
 fi
}


