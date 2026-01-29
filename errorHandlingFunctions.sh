#!/bin/bash

# Error Handling Functions for OSM-Notes-profile
# This file contains error handling and retry functions.
#
# Author: Andres Gomez (AngocA)
# Version: 2025-11-25
VERSION="2025-11-25"

# shellcheck disable=SC2317,SC2155,SC2312

# Circuit breaker state
declare -A CIRCUIT_BREAKER_STATE
declare -A CIRCUIT_BREAKER_FAILURE_COUNT
declare -A CIRCUIT_BREAKER_LAST_FAILURE_TIME

# Show help function
function __show_help() {
 echo "Error Handling Functions for OSM-Notes-profile"
 echo "This file contains error handling and retry functions."
 echo
 echo "Usage: source bin/errorHandlingFunctions.sh"
 echo
 echo "Available functions:"

 echo "  __circuit_breaker_execute   - Circuit breaker pattern"
 echo "  __download_with_retry       - Download with retry logic"
 echo "  __api_call_with_retry       - API calls with retry"
 echo "  __database_operation_with_retry - Database operations with retry"
 echo "  __file_operation_with_retry - File operations with retry"
 echo "  __check_network_connectivity - Network connectivity check"
 echo "  __handle_error_with_cleanup - Error handling with cleanup"
 echo
 echo "Author: Andres Gomez (AngocA)"
 echo "Version: ${VERSION}"
 exit 1
}

# Circuit breaker pattern implementation
function __circuit_breaker_execute() {
 __log_start
 local OPERATION_NAME="${1}"
 local COMMAND="${2}"
 local FAILURE_THRESHOLD="${3:-5}"
 local TIMEOUT="${4:-30}"
 local RESET_TIMEOUT="${5:-60}"

 if [[ -z "${OPERATION_NAME}" ]] || [[ -z "${COMMAND}" ]]; then
  __loge "ERROR: Operation name and command are required"
  __log_finish
  return 1
 fi

 local CURRENT_TIME
 CURRENT_TIME=$(date +%s)

 local LAST_FAILURE_TIME="${CIRCUIT_BREAKER_LAST_FAILURE_TIME[${OPERATION_NAME}]:-0}"
 local FAILURE_COUNT="${CIRCUIT_BREAKER_FAILURE_COUNT[${OPERATION_NAME}]:-0}"
 local STATE="${CIRCUIT_BREAKER_STATE[${OPERATION_NAME}]:-CLOSED}"

 # Check if circuit breaker is open
 if [[ "${STATE}" == "OPEN" ]]; then
  local TIME_SINCE_LAST_FAILURE
  TIME_SINCE_LAST_FAILURE=$((CURRENT_TIME - LAST_FAILURE_TIME))

  if [[ "${TIME_SINCE_LAST_FAILURE}" -lt "${RESET_TIMEOUT}" ]]; then
   __logw "WARNING: Circuit breaker is OPEN for ${OPERATION_NAME}. Skipping operation."
   __log_finish
   return 1
  else
   __logi "Circuit breaker reset to HALF_OPEN for ${OPERATION_NAME}"
   CIRCUIT_BREAKER_STATE[${OPERATION_NAME}]="HALF_OPEN"
   STATE="HALF_OPEN"
  fi
 fi

 # Execute command with timeout
 local EXIT_CODE
 if timeout "${TIMEOUT}" bash -c "${COMMAND}"; then
  __logi "Operation ${OPERATION_NAME} succeeded"

  # Reset failure count on success
  CIRCUIT_BREAKER_FAILURE_COUNT[${OPERATION_NAME}]=0
  CIRCUIT_BREAKER_STATE[${OPERATION_NAME}]="CLOSED"

  __log_finish
  return 0
 else
  EXIT_CODE=$?
  __loge "ERROR: Operation ${OPERATION_NAME} failed with exit code ${EXIT_CODE}"

  # Update failure tracking
  CIRCUIT_BREAKER_FAILURE_COUNT[${OPERATION_NAME}]=$((FAILURE_COUNT + 1))
  CIRCUIT_BREAKER_LAST_FAILURE_TIME[${OPERATION_NAME}]=${CURRENT_TIME}

  # Check if threshold exceeded
  if [[ "${CIRCUIT_BREAKER_FAILURE_COUNT[${OPERATION_NAME}]}" -ge "${FAILURE_THRESHOLD}" ]]; then
   __logw "WARNING: Circuit breaker opened for ${OPERATION_NAME}"
   CIRCUIT_BREAKER_STATE[${OPERATION_NAME}]="OPEN"
  fi

  __log_finish
  return "${EXIT_CODE}"
 fi
}

# Download with retry
function __download_with_retry() {
 __log_start
 local URL="${1}"
 local OUTPUT_FILE="${2}"
 local MAX_ATTEMPTS="${3:-3}"
 local TIMEOUT="${4:-30}"

 if [[ -z "${URL}" ]] || [[ -z "${OUTPUT_FILE}" ]]; then
  __loge "ERROR: URL and output file are required"
  __log_finish
  return 1
 fi

 local COMMAND="curl -s -o '${OUTPUT_FILE}' '${URL}'"
 __circuit_breaker_execute "download_${URL}" "${COMMAND}" 3 "${TIMEOUT}" 120
 __log_finish
}

# API call with retry
function __api_call_with_retry() {
 __log_start
 local URL="${1}"
 local OUTPUT_FILE="${2}"
 local MAX_ATTEMPTS="${3:-3}"
 local TIMEOUT="${4:-30}"

 if [[ -z "${URL}" ]] || [[ -z "${OUTPUT_FILE}" ]]; then
  __loge "ERROR: URL and output file are required"
  __log_finish
  return 1
 fi

 local COMMAND="curl -s -o '${OUTPUT_FILE}' '${URL}'"
 __circuit_breaker_execute "api_call_${URL}" "${COMMAND}" 3 "${TIMEOUT}" 120
 __log_finish
}

# Database operation with retry
function __database_operation_with_retry() {
 __log_start
 local SQL_FILE="${1}"
 local MAX_ATTEMPTS="${2:-3}"
 local TIMEOUT="${3:-60}"

 if [[ -z "${SQL_FILE}" ]]; then
  __loge "ERROR: SQL file is required"
  __log_finish
  return 1
 fi

 if ! __validate_input_file "${SQL_FILE}" "SQL file"; then
  __log_finish
  return 1
 fi

 # Use default values if variables are not set (for peer authentication)
 local DB_PASSWORD_PARAM="${DB_PASSWORD:-}"
 local DB_HOST_PARAM="${DB_HOST:-localhost}"
 local DB_PORT_PARAM="${DB_PORT:-5432}"
 local DB_USER_PARAM="${DB_USER:-$(whoami)}"
 local DBNAME_PARAM="${DBNAME:-}"

 if [[ -z "${DBNAME_PARAM}" ]]; then
  __loge "ERROR: DBNAME variable is not defined"
  __log_finish
  return 1
 fi

 local COMMAND
 if [[ -n "${DB_PASSWORD_PARAM}" ]]; then
  COMMAND="PGPASSWORD='${DB_PASSWORD_PARAM}' psql -h '${DB_HOST_PARAM}' -p '${DB_PORT_PARAM}' -U '${DB_USER_PARAM}' -d '${DBNAME_PARAM}' -f '${SQL_FILE}'"
 else
  COMMAND="psql -d '${DBNAME_PARAM}' -f '${SQL_FILE}'"
 fi
 __circuit_breaker_execute "database_operation_${SQL_FILE}" "${COMMAND}" 3 "${TIMEOUT}" 300
 __log_finish
}

# File operation with retry
##
# Performs file operations with retry logic using circuit breaker pattern
# Executes file operations (copy, move, delete) with automatic retry and circuit breaker
# protection. Uses circuit breaker to prevent repeated failures from overwhelming the system.
#
# Parameters:
#   $1: Operation - File operation type: "copy", "move", or "delete" (required)
#   $2: Source - Source file path (required)
#   $3: Destination - Destination file path (required for copy/move, ignored for delete)
#   $4: Max attempts - Maximum retry attempts (optional, default: 3)
#
# Returns:
#   0: Success - File operation completed successfully
#   1: Failure - Operation failed, invalid parameters, or circuit breaker open
#
# Error codes:
#   0: Success - File operation completed successfully
#   1: Failure - Missing required parameters (operation or source)
#   1: Failure - Missing destination for copy/move operations
#   1: Failure - Unsupported operation type
#   1: Failure - Circuit breaker is open (too many failures)
#   1: Failure - File operation failed after retries
#
# Error conditions:
#   0: Success - File operation succeeded (possibly after retries)
#   1: Invalid operation - Operation type not "copy", "move", or "delete"
#   1: Missing source - Source file path is empty
#   1: Missing destination - Destination required but not provided for copy/move
#   1: Circuit breaker open - Too many failures, circuit breaker prevents execution
#   1: Operation failed - File operation failed after all retry attempts
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies:
#     - Circuit breaker state (via __circuit_breaker_execute)
#
# Side effects:
#   - Executes file operations (cp, mv, rm)
#   - Modifies circuit breaker state for operation tracking
#   - Writes log messages to stderr
#   - No database or network operations
#
# Notes:
#   - Uses circuit breaker pattern to prevent repeated failures
#   - Circuit breaker thresholds: 3 failures, 30s timeout, 120s recovery
#   - Operations are executed via command string (uses eval internally in circuit breaker)
#   - Delete operation does not require destination parameter
#   - Source and destination paths are single-quoted in command (basic protection)
#
# Example:
#   # Copy file with retry
#   __file_operation_with_retry "copy" "/tmp/source.txt" "/tmp/dest.txt"
#
#   # Move file with retry
#   __file_operation_with_retry "move" "/tmp/old.txt" "/tmp/new.txt"
#
#   # Delete file with retry
#   __file_operation_with_retry "delete" "/tmp/temp.txt"
#
# Related: __retry_file_operation() (alternative retry implementation)
# Related: __circuit_breaker_execute() (circuit breaker implementation)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __file_operation_with_retry() {
 __log_start
 local OPERATION="${1}"
 local SOURCE="${2}"
 local DESTINATION="${3}"
 local MAX_ATTEMPTS="${4:-3}"

 if [[ -z "${OPERATION}" ]] || [[ -z "${SOURCE}" ]]; then
  __loge "ERROR: Operation and source are required"
  __log_finish
  return 1
 fi

 local COMMAND
 case "${OPERATION}" in
 copy)
  if [[ -z "${DESTINATION}" ]]; then
   __loge "ERROR: Destination is required for copy operation"
   __log_finish
   return 1
  fi
  COMMAND="cp '${SOURCE}' '${DESTINATION}'"
  ;;
 move)
  if [[ -z "${DESTINATION}" ]]; then
   __loge "ERROR: Destination is required for move operation"
   __log_finish
   return 1
  fi
  COMMAND="mv '${SOURCE}' '${DESTINATION}'"
  ;;
 delete)
  COMMAND="rm -f '${SOURCE}'"
  ;;
 *)
  __loge "ERROR: Unsupported operation: ${OPERATION}"
  __log_finish
  return 1
  ;;
 esac

 __circuit_breaker_execute "file_operation_${OPERATION}_${SOURCE}" "${COMMAND}" 3 30 120
 __log_finish
}

##
# Checks network connectivity by testing HTTP connection to a URL
# Verifies that the system can reach external networks by attempting to connect
# to a test URL (default: Google). Useful for validating network availability
# before attempting network operations.
#
# Parameters:
#   $1: Timeout - Maximum seconds to wait for connection (optional, default: 10)
#   $2: Test URL - URL to test connectivity against (optional, default: https://www.google.com)
#
# Returns:
#   0: Success - Network connectivity confirmed
#   1: Failure - Network connectivity failed or timeout exceeded
#
# Error codes:
#   0: Success - Successfully connected to test URL within timeout
#   1: Failure - Connection failed, timeout exceeded, or curl command failed
#
# Error conditions:
#   0: Success - HTTP connection to test URL succeeded
#   1: Network failure - Cannot reach test URL (DNS failure, network down, firewall blocking)
#   1: Timeout - Connection attempt exceeded timeout limit
#   1: Missing dependency - timeout or curl command not found
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Executes curl command to test HTTP connection
#   - Writes log messages to stderr
#   - No file or database operations
#   - No persistent state changes
#
# Notes:
#   - Uses curl with silent mode (-s) to avoid output
#   - Uses timeout command to limit connection attempt duration
#   - Default test URL is Google (https://www.google.com)
#   - Can be customized to test specific endpoints
#   - Useful as a prerequisite check before network operations
#
# Example:
#   if __check_network_connectivity; then
#     echo "Network is available"
#   else
#     echo "Network is unavailable"
#   fi
#
#   # Custom timeout and URL
#   __check_network_connectivity 5 "https://api.openstreetmap.org"
#
# Related: __retry_network_operation() (network operations with retry)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __check_network_connectivity() {
 __log_start
 local TIMEOUT="${1:-10}"
 local TEST_URL="${2:-https://www.google.com}"

 __logi "=== CHECKING NETWORK CONNECTIVITY ==="
 __logd "Testing connectivity to ${TEST_URL} with timeout ${TIMEOUT}s"

 if timeout "${TIMEOUT}" curl -s --max-time "${TIMEOUT}" "${TEST_URL}" > /dev/null 2>&1; then
  __logi "Network connectivity confirmed"
  __logi "=== NETWORK CONNECTIVITY CHECK COMPLETED SUCCESSFULLY ==="
  __log_finish
  return 0
 else
  __loge "ERROR: Network connectivity failed"
  __logi "=== NETWORK CONNECTIVITY CHECK FAILED ==="
  __log_finish
  return 1
 fi
}

##
# Handles errors with optional cleanup command execution
# Centralized error handling function that logs errors, executes cleanup commands,
# generates failed execution markers, and exits (or returns in test mode).
# This function is critical for consistent error handling across all scripts.
#
# Parameters:
#   $1: Error code - Exit/return code to use (required)
#   $2: Error message - Descriptive error message to log (required)
#   $3: Cleanup command - Command to execute for cleanup (optional)
#       Command is executed via eval, so use with caution
#
# Returns:
#   In production: Exits script with error_code (never returns)
#   In test environment: Returns with error_code
#
# Error codes:
#   Exits/returns with the provided error_code parameter
#   Function itself never fails (always executes cleanup and exits/returns)
#
# Error conditions:
#   Always exits/returns with provided error_code
#   Cleanup command failures are logged but do not prevent exit/return
#
# Context variables:
#   Reads:
#     - TEST_MODE: If "true", uses return instead of exit (for testing)
#     - BATS_TEST_NAME: If set, uses return instead of exit (BATS testing)
#     - CLEAN: If "false", skips cleanup command execution (optional, default: true)
#     - GENERATE_FAILED_FILE: If "true", writes to failed execution file (optional, default: false)
#     - FAILED_EXECUTION_FILE: Path to failed execution marker file (optional)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Writes error log messages to stderr
#   - Executes cleanup command via eval (if provided and CLEAN=true)
#   - Writes to failed execution file (if GENERATE_FAILED_FILE=true)
#   - Exits script in production mode (does not return)
#   - Returns error code in test mode (TEST_MODE or BATS_TEST_NAME set)
#   - No database operations
#
# Notes:
#   - CRITICAL: This function exits the script in production mode
#   - Cleanup command execution respects CLEAN environment variable
#   - Failed execution file is appended (not overwritten)
#   - Test mode detection: checks TEST_MODE or BATS_TEST_NAME
#   - Cleanup command failures are logged but do not prevent exit
#   - Use eval for cleanup command - ensure command is safe
#
# Example:
#   # Production usage (exits script)
#   __handle_error_with_cleanup "${ERROR_DATA_VALIDATION}" \
#     "Invalid JSON structure" \
#     "rm -f ${TEMP_FILE}"
#
#   # Test usage (returns error code)
#   export TEST_MODE=true
#   __handle_error_with_cleanup 1 "Test error" "rm -f /tmp/test"
#   # Script continues after return
#
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __handle_error_with_cleanup() {
 __log_start
 local ERROR_CODE="${1}"
 local ERROR_MESSAGE="${2}"
 local CLEANUP_COMMAND="${3:-}"

 __loge "=== ERROR HANDLING WITH CLEANUP === Error occurred: ${ERROR_MESSAGE}"

 # Execute cleanup command if provided and CLEAN is true
 if [[ -n "${CLEANUP_COMMAND}" ]] && [[ "${CLEAN:-true}" == "true" ]]; then
  echo "Executing cleanup command: ${CLEANUP_COMMAND}"
  __logd "Executing cleanup command: ${CLEANUP_COMMAND}"
  if eval "${CLEANUP_COMMAND}"; then
   __logd "Cleanup command executed successfully"
  else
   __logw "WARNING: Cleanup command failed"
  fi
 elif [[ -n "${CLEANUP_COMMAND}" ]]; then
  echo "Skipping cleanup command due to CLEAN=false: ${CLEANUP_COMMAND}"
  __logd "Skipping cleanup command due to CLEAN=false: ${CLEANUP_COMMAND}"
 fi

 # Generate failed execution file if enabled
 if [[ "${GENERATE_FAILED_FILE:-false}" == "true" ]] && [[ -n "${FAILED_EXECUTION_FILE:-}" ]]; then
  # shellcheck disable=SC2312  # date failure is acceptable, we still want to log
  echo "$(date || echo 'unknown date'): ${ERROR_MESSAGE}" >> "${FAILED_EXECUTION_FILE}"
 fi

 __log_finish
 # Use exit in production, return in test environment
 # Detect test environment via TEST_MODE or BATS_TEST_NAME variables
 if [[ "${TEST_MODE:-false}" == "true" ]] || [[ -n "${BATS_TEST_NAME:-}" ]]; then
  __logd "Test environment detected, using return instead of exit"
  return "${ERROR_CODE}"
 else
  __logd "Production environment detected, using exit"
  exit "${ERROR_CODE}"
 fi
}

# Get circuit breaker status
function __get_circuit_breaker_status() {
 __log_start
 local OPERATION_NAME="${1}"

 if [[ -z "${OPERATION_NAME}" ]]; then
  __loge "ERROR: Operation name is required"
  __log_finish
  return 1
 fi

 local STATE="${CIRCUIT_BREAKER_STATE[${OPERATION_NAME}]:-CLOSED}"
 local FAILURE_COUNT="${CIRCUIT_BREAKER_FAILURE_COUNT[${OPERATION_NAME}]:-0}"
 local LAST_FAILURE_TIME="${CIRCUIT_BREAKER_LAST_FAILURE_TIME[${OPERATION_NAME}]:-0}"

 echo "Operation: ${OPERATION_NAME}"
 echo "State: ${STATE}"
 echo "Failure Count: ${FAILURE_COUNT}"
 echo "Last Failure Time: ${LAST_FAILURE_TIME}"
 __log_finish
}

# Reset circuit breaker
function __reset_circuit_breaker() {
 local OPERATION_NAME="${1}"
 __log_start

 if [[ -z "${OPERATION_NAME}" ]]; then
  __loge "ERROR: Operation name is required"
  __log_finish
  return 1
 fi

 __logi "Resetting circuit breaker for ${OPERATION_NAME}"
 CIRCUIT_BREAKER_STATE[${OPERATION_NAME}]="CLOSED"
 CIRCUIT_BREAKER_FAILURE_COUNT[${OPERATION_NAME}]=0
 CIRCUIT_BREAKER_LAST_FAILURE_TIME[${OPERATION_NAME}]=0
 __log_finish
}

##
# Retries file operations with exponential backoff and optional cleanup
# Executes file operations (copy, move, delete) with automatic retry using exponential
# backoff. Supports optional cleanup command execution between retry attempts.
# Alternative to __file_operation_with_retry() without circuit breaker pattern.
#
# Parameters:
#   $1: Operation - File operation type: "copy", "move", or "delete" (required)
#   $2: Source - Source file path (required)
#   $3: Destination - Destination file path (optional for delete, required for copy/move)
#   $4: Max attempts - Maximum retry attempts (optional, default: 3)
#   $5: Cleanup command - Command to execute between retries (optional)
#       Command is executed via eval, so use with caution
#
# Returns:
#   0: Success - File operation completed successfully
#   1: Failure - Operation failed or invalid parameters
#
# Error codes:
#   0: Success - File operation completed successfully (possibly after retries)
#   1: Failure - Missing required parameters (operation or source)
#   1: Failure - Missing destination for copy/move operations
#   1: Failure - Unsupported operation type
#   1: Failure - File operation failed after all retry attempts
#
# Error conditions:
#   0: Success - File operation succeeded on any attempt
#   1: Invalid operation - Operation type not "copy", "move", or "delete"
#   1: Missing source - Source file path is empty
#   1: Missing destination - Destination required but not provided for copy/move
#   1: Operation failed - File operation failed after MAX_ATTEMPTS retries
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Executes file operations (cp, mv, rm)
#   - Executes cleanup command via eval between retries (if provided)
#   - Sleeps between retry attempts (exponential backoff: 1s, 2s, 4s, ..., max 60s)
#   - Writes log messages to stderr
#   - No database or network operations
#
# Notes:
#   - Uses exponential backoff: delay doubles each retry (1s, 2s, 4s, 8s, ...)
#   - Maximum delay is capped at 60 seconds
#   - Cleanup command is executed after each failed attempt (before retry)
#   - Cleanup command failures are ignored (|| true)
#   - File operation errors are suppressed (2> /dev/null)
#   - Does not use circuit breaker pattern (unlike __file_operation_with_retry)
#
# Example:
#   # Copy file with retry and cleanup
#   __retry_file_operation "copy" "/tmp/source.txt" "/tmp/dest.txt" 5 \
#     "rm -f /tmp/dest.txt"
#
#   # Delete file with retry
#   __retry_file_operation "delete" "/tmp/temp.txt"
#
#   # Move file with retry and cleanup
#   __retry_file_operation "move" "/tmp/old.txt" "/tmp/new.txt" 3 \
#     "rm -f /tmp/new.txt"
#
# Related: __file_operation_with_retry() (circuit breaker version)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __retry_file_operation() {
 __log_start
 local OPERATION="${1}"
 local SOURCE="${2}"
 local DESTINATION="${3:-}"
 local MAX_ATTEMPTS="${4:-3}"
 local CLEANUP_COMMAND="${5:-}"

 if [[ -z "${OPERATION}" ]] || [[ -z "${SOURCE}" ]]; then
  __loge "ERROR: Operation and source are required"
  __log_finish
  return 1
 fi

 local ATTEMPT=1
 local DELAY=1

 while [[ "${ATTEMPT}" -le "${MAX_ATTEMPTS}" ]]; do
  __logd "File operation attempt ${ATTEMPT}/${MAX_ATTEMPTS}: ${OPERATION} ${SOURCE}"

  case "${OPERATION}" in
  copy)
   if [[ -z "${DESTINATION}" ]]; then
    __loge "ERROR: Destination is required for copy operation"
    __log_finish
    return 1
   fi
   if cp "${SOURCE}" "${DESTINATION}" 2> /dev/null; then
    __logi "File copy succeeded on attempt ${ATTEMPT}"
    __log_finish
    return 0
   fi
   ;;
  move)
   if [[ -z "${DESTINATION}" ]]; then
    __loge "ERROR: Destination is required for move operation"
    __log_finish
    return 1
   fi
   if mv "${SOURCE}" "${DESTINATION}" 2> /dev/null; then
    __logi "File move succeeded on attempt ${ATTEMPT}"
    __log_finish
    return 0
   fi
   ;;
  delete)
   if rm -f "${SOURCE}" 2> /dev/null; then
    __logi "File delete succeeded on attempt ${ATTEMPT}"
    __log_finish
    return 0
   fi
   ;;
  *)
   __loge "ERROR: Unsupported operation: ${OPERATION}"
   __log_finish
   return 1
   ;;
  esac

  __logw "WARNING: File operation failed on attempt ${ATTEMPT}"

  # Execute cleanup command if provided
  if [[ -n "${CLEANUP_COMMAND}" ]]; then
   __logd "Executing cleanup command: ${CLEANUP_COMMAND}"
   eval "${CLEANUP_COMMAND}" || true
  fi

  if [[ "${ATTEMPT}" -eq "${MAX_ATTEMPTS}" ]]; then
   __loge "ERROR: File operation failed after ${MAX_ATTEMPTS} attempts"
   __log_finish
   return 1
  fi

  __logd "Waiting ${DELAY} seconds before retry"
  sleep "${DELAY}"

  ATTEMPT=$((ATTEMPT + 1))
  DELAY=$((DELAY * 2))
  if [[ "${DELAY}" -gt 60 ]]; then
   DELAY=60
  fi
 done

 __log_finish
 return 1
}
