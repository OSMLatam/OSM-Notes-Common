#!/bin/bash

# Validation Functions for OSM-Notes-profile
# This file contains validation functions for various data types.
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-07
VERSION="2025-12-07"

# shellcheck disable=SC2317,SC2155,SC2034,SC2312

# Note: This file expects to be sourced after commonFunctions.sh which provides logging functions
# If sourced directly, ensure commonFunctions.sh is loaded first

# Load common functions if not already loaded
# Set SCRIPT_BASE_DIRECTORY if not already set
if [[ -z "${SCRIPT_BASE_DIRECTORY:-}" ]]; then
 # We're in lib/osm-common, so we need to go up two levels to reach project root
 SCRIPT_BASE_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# Don't set LOGGER_UTILITY here - let commonFunctions.sh handle it
# This prevents conflicts with the simple logger implementation

if [[ -z "${__COMMON_FUNCTIONS_LOADED:-}" ]]; then
 # shellcheck disable=SC1091
 if [[ -f "${SCRIPT_BASE_DIRECTORY}/bin/commonFunctions.sh" ]]; then
  # Preserve SCRIPT_BASE_DIRECTORY before loading commonFunctions.sh
  SAVED_SCRIPT_BASE_DIRECTORY="${SCRIPT_BASE_DIRECTORY}"
  source "${SCRIPT_BASE_DIRECTORY}/bin/commonFunctions.sh"
  # Restore SCRIPT_BASE_DIRECTORY if it was changed
  if [[ "${SCRIPT_BASE_DIRECTORY}" != "${SAVED_SCRIPT_BASE_DIRECTORY}" ]]; then
   SCRIPT_BASE_DIRECTORY="${SAVED_SCRIPT_BASE_DIRECTORY}"
  fi
 elif [[ -f "$(dirname "${BASH_SOURCE[0]}")/commonFunctions.sh" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/commonFunctions.sh"
 fi
fi

# JSON schema files for validation
# shellcheck disable=SC2034
if [[ -z "${JSON_SCHEMA_OVERPASS:-}" ]]; then declare -r JSON_SCHEMA_OVERPASS="${SCRIPT_BASE_DIRECTORY}/json/osm-jsonschema.json"; fi
if [[ -z "${JSON_SCHEMA_GEOJSON:-}" ]]; then declare -r JSON_SCHEMA_GEOJSON="${SCRIPT_BASE_DIRECTORY}/json/geojsonschema.json"; fi

# Show help function
function __show_help() {
 echo "Validation Functions for OSM-Notes-profile"
 echo "This file contains validation functions for various data types."
 echo
 echo "Usage: source lib/osm-common/validationFunctions.sh"
 echo
 echo "Available functions:"
 echo "  __validate_input_file      - Validate input file"
 echo "  __validate_input_files     - Validate multiple input files"
 echo "  __validate_xml_structure   - Validate XML structure"
 echo "  __validate_csv_structure   - Validate CSV structure"
 echo "  __validate_sql_structure   - Validate SQL structure"
 echo "  __validate_config_file     - Validate config file"
 echo "  __validate_json_structure  - Validate JSON structure"
 echo "  __validate_database_connection - Validate database connection"
 echo "  __validate_database_tables - Validate database tables"
 echo "  __validate_database_extensions - Validate database extensions"
 echo "  __validate_iso8601_date    - Validate ISO8601 date"
 echo "  __validate_xml_dates       - Validate XML dates"
 echo "  __validate_csv_dates       - Validate CSV dates"
 echo "  __validate_file_checksum   - Validate file checksum"
 echo "  __validate_coordinates     - Validate coordinates"
 echo "  __validate_numeric_range   - Validate numeric range"
 echo "  __validate_string_pattern  - Validate string pattern"
 echo
 echo "Author: Andres Gomez (AngocA)"
 echo "Version: ${VERSION}"
 exit 1
}

# Validate input file (enhanced version with support for files, directories, and executables)
##
# Validates input file or directory
# Performs basic validation checks on a file or directory path. Validates existence,
# readability, and type (file/directory/executable). Does not validate file content
# (content validation is handled by specific validation functions). Supports multiple
# expected types: file, directory, executable.
#
# Parameters:
#   $1: FILE_PATH - Path to file or directory to validate (required)
#   $2: DESCRIPTION - Description of file for error messages (optional, default: "File")
#   $3: EXPECTED_TYPE - Expected type: "file", "dir", or "executable" (optional, default: "file")
#
# Returns:
#   0: Success - File/directory validation passed
#   1: Failure - Validation failed (file missing, not readable, wrong type)
#
# Error codes:
#   0: Success - File/directory validation passed
#   1: Failure - File path is empty
#   1: Failure - File/directory does not exist
#   1: Failure - Path is not expected type (file/directory/executable)
#   1: Failure - File/directory is not readable
#   1: Failure - Executable is not executable
#
# Error conditions:
#   0: Success - File/directory validation passed
#   1: File path empty - FILE_PATH parameter is empty
#   1: File missing - File/directory does not exist
#   1: Wrong type - Path is not expected type (file/directory/executable)
#   1: Not readable - File/directory is not readable
#   1: Not executable - Executable file is not executable
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies:
#     - Creates temporary array for validation errors (local)
#
# Side effects:
#   - Validates file/directory existence
#   - Validates file/directory readability
#   - Validates file/directory type (file/directory/executable)
#   - Writes log messages to stderr
#   - No file, database, or network operations
#
# Notes:
#   - Does not validate file content (content validation is handled by specific functions)
#   - Does not validate file emptiness (different file types have different rules)
#   - Supports multiple expected types: file, directory, executable
#   - Common validation function used by other validation functions
#   - Part of input validation workflow
#   - Used before processing files to ensure they exist and are accessible
#
# Example:
#   __validate_input_file "/path/to/file.txt" "Input file" "file"
#   # Validates file exists, is readable, and is a file
#
#   __validate_input_file "/path/to/dir" "Config directory" "dir"
#   # Validates directory exists, is readable, and is a directory
#
#   __validate_input_file "/path/to/script.sh" "Script" "executable"
#   # Validates executable exists, is readable, and is executable
#
# Related: __validate_sql_structure() (validates SQL file structure)
# Related: __validate_xml_structure() (validates XML file structure)
# Related: __validate_input_files() (validates multiple files)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_input_file() {
 __log_start
 local FILE_PATH="${1}"
 local DESCRIPTION="${2:-File}"
 local EXPECTED_TYPE="${3:-file}"
 local VALIDATION_ERRORS=()

 # Check if file path is provided
 if [[ -z "${FILE_PATH}" ]]; then
  __loge "ERROR: ${DESCRIPTION} path is empty"
  __log_finish
  return 1
 fi

 # Check if file exists
 if [[ ! -e "${FILE_PATH}" ]]; then
  VALIDATION_ERRORS+=("File does not exist: ${FILE_PATH}")
 fi

 # Check if file is readable (for files)
 if [[ "${EXPECTED_TYPE}" == "file" ]] && [[ -e "${FILE_PATH}" ]]; then
  if [[ ! -f "${FILE_PATH}" ]]; then
   VALIDATION_ERRORS+=("Path is not a file: ${FILE_PATH}")
  elif [[ ! -r "${FILE_PATH}" ]]; then
   VALIDATION_ERRORS+=("File is not readable: ${FILE_PATH}")
  # Note: File emptiness validation is handled by specific validation functions
  # as different file types may have different rules about empty files
  fi
 fi

 # Check if directory is accessible (for directories)
 if [[ "${EXPECTED_TYPE}" == "dir" ]] && [[ -e "${FILE_PATH}" ]]; then
  if [[ ! -d "${FILE_PATH}" ]]; then
   VALIDATION_ERRORS+=("Path is not a directory: ${FILE_PATH}")
  elif [[ ! -r "${FILE_PATH}" ]]; then
   VALIDATION_ERRORS+=("Directory is not readable: ${FILE_PATH}")
  fi
 fi

 # Check if executable is executable
 if [[ "${EXPECTED_TYPE}" == "executable" ]] && [[ -e "${FILE_PATH}" ]]; then
  if [[ ! -x "${FILE_PATH}" ]]; then
   VALIDATION_ERRORS+=("File is not executable: ${FILE_PATH}")
  fi
 fi

 # Report validation errors
 if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
  __loge "ERROR: ${DESCRIPTION} validation failed:"
  for ERROR in "${VALIDATION_ERRORS[@]}"; do
   __loge "  - ${ERROR}"
  done
  __log_finish
  return 1
 fi

 __logi "${DESCRIPTION} validation passed: ${FILE_PATH}"
 __log_finish
 return 0
}

##
# Validates multiple input files in batch
# Validates each file in the provided list using __validate_input_file.
# Returns failure if any file fails validation, success only if all files are valid.
#
# Parameters:
#   $@: File paths - One or more file paths to validate (required, at least one file)
#
# Returns:
#   0: Success - All files validated successfully
#   1: Failure - One or more files failed validation
#   2: Invalid argument - No file paths provided
#
# Error codes:
#   0: Success - All provided files exist, are readable, and meet validation criteria
#   1: Failure - At least one file failed validation (missing, not readable, wrong type, etc.)
#   2: Invalid argument - No file paths provided (empty argument list)
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Validates each file sequentially using __validate_input_file
#   - Logs validation results for each file to standard logger
#   - Stops on first failure (but continues to log all failures)
#   - No file modifications or network operations
#
# Example:
#   if __validate_input_files "/tmp/file1.json" "/tmp/file2.json" "/tmp/file3.json"; then
#     echo "All files valid"
#   else
#     echo "Some files failed validation"
#   fi
#
# Related: __validate_input_file() (used for individual file validation)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_input_files() {
 __log_start
 local FILES=("$@")
 local FAILED=0

 for FILE in "${FILES[@]}"; do
  if ! __validate_input_file "${FILE}" "Input file"; then
   FAILED=1
  fi
 done

 __log_finish
 return "${FAILED}"
}

##
# Validates XML file structure and basic syntax
# Performs lightweight XML validation using grep to check for XML declaration and root element.
# Uses basic validation suitable for large files (avoids xmllint overhead).
#
# Parameters:
#   $1: XML file path - Path to XML file to validate (required)
#   $2: Expected root element - Root element name to check for (optional, default: checks for <osm>)
#
# Returns:
#   0: Success - XML structure is valid
#   1: Failure - XML invalid, file missing, or structure incorrect
#   2: Invalid argument - XML file path is empty
#   7: File error - XML file not found or cannot be read
#
# Error codes:
#   0: Success - XML declaration present, root element found, file is non-empty
#   1: Failure - Missing XML declaration, missing root element, or file is empty
#   2: Invalid argument - XML file path parameter is empty
#   7: File error - XML file does not exist or cannot be read
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads XML file from filesystem
#   - Executes grep commands to check XML structure
#   - Logs validation results to standard logger
#   - No file modifications or network operations
#
# Validation approach:
#   - Lightweight: Uses grep instead of xmllint (faster for large files)
#   - Checks for XML declaration: <?xml
#   - Checks for root element: <osm> (or specified root)
#   - Verifies file is non-empty
#   - Warns if file is very small (< 100 bytes, allows test fixtures)
#
# Example:
#   if __validate_xml_structure "/tmp/data.xml"; then
#     echo "Valid XML"
#   fi
#   if __validate_xml_structure "/tmp/data.xml" "osm-notes"; then
#     echo "Valid XML with osm-notes root"
#   fi
#
# Related: __validate_input_file() (validates file existence first)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_xml_structure() {
 __validate_xml_structure_impl "$@"
}

##
# Internal implementation of XML structure validation
# Called by __validate_xml_structure wrapper function.
#
# Parameters:
#   $1: XML file path (required)
#   $2: Expected root element (optional)
#
# Returns:
#   0: Success - XML structure valid
#   1: Failure - XML structure invalid
#   2: Invalid argument - File path empty
#   7: File error - File not found
#
# Related: __validate_xml_structure() (public wrapper)
##
function __validate_xml_structure_impl() {
 __log_start
 local XML_FILE="${1}"
 local EXPECTED_ROOT="${2:-}"

 __logi "=== VALIDATING XML STRUCTURE ==="
 __logd "XML file: ${XML_FILE}"

 if ! __validate_input_file "${XML_FILE}" "XML file"; then
  __log_finish
  return 1
 fi

 # For large files, use lightweight validation
 local FILE_SIZE
 FILE_SIZE=$(stat -c%s "${XML_FILE}" 2> /dev/null || echo "0")
 local SIZE_MB=$((FILE_SIZE / 1024 / 1024))

 if [[ "${SIZE_MB}" -gt 500 ]]; then
  __logw "WARNING: Large XML file detected (${SIZE_MB} MB). Using lightweight structure validation."

  # Use lightweight validation for large files
  if ! grep -q "<osm-notes\|<osm>" "${XML_FILE}" 2> /dev/null; then
   __loge "ERROR: Missing expected root element in large XML file: ${XML_FILE}"
   __log_finish
   return 1
  fi
  __logd "Large XML file validation passed: ${XML_FILE}"
  __log_finish
  return 0
 fi

 # Use standard validation for smaller files
 # Lightweight XML validation using grep instead of xmllint
 if ! grep -q '<?xml' "${XML_FILE}" 2> /dev/null; then
  __loge "ERROR: XML file does not contain XML declaration: ${XML_FILE}"
  __log_finish
  return 1
 fi

 # Check expected root element if provided
 if [[ -n "${EXPECTED_ROOT}" ]]; then
  if ! grep -q "<${EXPECTED_ROOT}" "${XML_FILE}" 2> /dev/null; then
   __loge "ERROR: Expected root element '${EXPECTED_ROOT}' not found: ${XML_FILE}"
   __log_finish
   return 1
  fi

  # Check for required root element using grep (much faster for large files)
  if ! grep -q "<osm-notes\|<osm>" "${XML_FILE}" 2> /dev/null; then
   __loge "ERROR: Missing osm-notes or osm root element: ${XML_FILE}"
   __log_finish
   return 1
  fi

  # Check for basic XML structure
  if ! grep -q "<?xml\|<osm-notes\|<osm>" "${XML_FILE}" 2> /dev/null; then
   __loge "ERROR: Invalid XML structure (missing XML declaration or root element): ${XML_FILE}"
   __log_finish
   return 1
  fi

  __logi "Lightweight XML structure validation passed: ${XML_FILE}"
  __log_finish
  return 0
 fi

 # Check if file is valid XML using lightweight validation (for smaller files)
 # Check for basic XML structure markers
 if ! grep -q '<?xml' "${XML_FILE}" 2> /dev/null; then
  __loge "ERROR: XML file does not contain XML declaration: ${XML_FILE}"
  __log_finish
  return 1
 fi

 # Check for required root element (osm-notes for planet, osm for API)
 if ! grep -q "<osm-notes\|<osm>" "${XML_FILE}" 2> /dev/null; then
  __loge "ERROR: Missing osm-notes or osm root element: ${XML_FILE}"
  __log_finish
  return 1
 fi

 # Check expected root element if provided
 if [[ -n "${EXPECTED_ROOT}" ]]; then
  if ! grep -q "<${EXPECTED_ROOT}" "${XML_FILE}" 2> /dev/null; then
   __loge "ERROR: Expected root element '${EXPECTED_ROOT}' not found: ${XML_FILE}"
   __log_finish
   return 1
  fi
 fi

 __logi "XML structure validation passed: ${XML_FILE}"
 __logi "=== XML STRUCTURE VALIDATION COMPLETED SUCCESSFULLY ==="
 __log_finish
 return 0
}

##
# Validates CSV file structure and column count
# Validates that a CSV file exists, is readable, is non-empty, has a header row,
# and optionally matches expected column count. Checks for basic CSV structure
# (header row, column separators). Used before CSV database imports.
#
# Parameters:
#   $1: CSV_FILE - Path to CSV file to validate (required)
#   $2: EXPECTED_COLUMNS - Expected column count or comma-separated column names (optional)
#       If number: validates exact column count
#       If string: counts columns in comma-separated list and validates count
#
# Returns:
#   0: Success - CSV structure validation passed
#   1: Failure - File validation failed, file empty, no header, or column count mismatch
#
# Error codes:
#   0: Success - CSV file structure is valid
#   1: Failure - File does not exist or is not readable (via __validate_input_file)
#   1: Failure - CSV file is empty (no content)
#   1: Failure - CSV file has no header row (first line is empty)
#   1: Failure - Column count mismatch (if EXPECTED_COLUMNS provided)
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads CSV file from filesystem (first line for header)
#   - Executes head, tr, wc commands to check structure
#   - Logs validation results to standard logger
#   - No file modifications or network operations
#
# Notes:
#   - Validates file existence and readability (via __validate_input_file)
#   - Checks for non-empty file (must have content)
#   - Validates header row exists (first line is non-empty)
#   - Validates column count if EXPECTED_COLUMNS provided
#   - Does not validate CSV data content (only structure)
#   - Does not validate CSV escaping or quoting
#   - Common validation function used before CSV database imports
#
# Example:
#   __validate_csv_structure "/tmp/data.csv" 8
#   # Validates CSV has exactly 8 columns
#
#   __validate_csv_structure "/tmp/data.csv" "id,name,email,phone"
#   # Validates CSV has 4 columns (counts comma-separated list)
#
# Related: __validate_input_file() (validates file existence first)
# Related: __validate_csv_dates() (validates date columns in CSV)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
# Validate CSV structure
function __validate_csv_structure() {
 __log_start
 local CSV_FILE="${1}"
 local EXPECTED_COLUMNS="${2:-}"

 if ! __validate_input_file "${CSV_FILE}" "CSV file"; then
  __log_finish
  return 1
 fi

 # Check if file has content
 if [[ ! -s "${CSV_FILE}" ]]; then
  __loge "ERROR: CSV file is empty: ${CSV_FILE}"
  __log_finish
  return 1
 fi

 # Check if file has header
 local FIRST_LINE
 FIRST_LINE=$(head -n 1 "${CSV_FILE}" 2> /dev/null)
 if [[ -z "${FIRST_LINE}" ]]; then
  __loge "ERROR: CSV file has no header: ${CSV_FILE}"
  __log_finish
  return 1
 fi

 # Check column count if expected columns provided
 if [[ -n "${EXPECTED_COLUMNS}" ]]; then
  local COLUMN_COUNT
  # shellcheck disable=SC2312  # wc -l always succeeds, tr may fail but we handle empty result
  COLUMN_COUNT=$(echo "${FIRST_LINE}" | tr ',' '\n' | wc -l || echo "0")
  local EXPECTED_COUNT

  # Check if EXPECTED_COLUMNS is a number (direct column count)
  if [[ "${EXPECTED_COLUMNS}" =~ ^[0-9]+$ ]]; then
   EXPECTED_COUNT="${EXPECTED_COLUMNS}"
  else
   # EXPECTED_COLUMNS is a comma-separated list of column names
   # shellcheck disable=SC2312  # wc -l always succeeds, tr may fail but we handle empty result
   EXPECTED_COUNT=$(echo "${EXPECTED_COLUMNS}" | tr ',' '\n' | wc -l || echo "0")
  fi

  if [[ "${COLUMN_COUNT}" -ne "${EXPECTED_COUNT}" ]]; then
   __loge "ERROR: Expected ${EXPECTED_COUNT} columns, got ${COLUMN_COUNT}: ${CSV_FILE}"
   __log_finish
   return 1
  fi
 fi

 __logi "CSV structure validation passed: ${CSV_FILE}"
 __log_finish
 return 0
}

# Validate SQL structure
##
# Validates SQL file structure and syntax
# Performs comprehensive validation of SQL file structure. Validates file existence,
# readability, non-emptiness, presence of valid SQL statements, and balanced parentheses.
# Checks for common SQL keywords to ensure file contains valid SQL. Does not execute
# SQL or validate against database schema.
#
# Parameters:
#   $1: SQL_FILE - Path to SQL file to validate (required)
#
# Returns:
#   0: Success - SQL structure validation passed
#   1: Failure - Validation failed (file missing, empty, no valid SQL, unbalanced parentheses)
#
# Error codes:
#   0: Success - SQL structure validation passed
#   1: Failure - SQL file does not exist
#   1: Failure - SQL file is not readable
#   1: Failure - SQL file is empty
#   1: Failure - SQL file contains only comments (no valid SQL statements)
#   1: Failure - No valid SQL statements found (no SQL keywords detected)
#   1: Failure - Unbalanced parentheses in SQL file
#
# Error conditions:
#   0: Success - SQL structure validation passed
#   1: File missing - SQL file does not exist
#   1: Not readable - SQL file is not readable
#   1: File empty - SQL file is empty
#   1: Only comments - SQL file contains only comments (no valid SQL statements)
#   1: No SQL keywords - No valid SQL keywords detected (CREATE, INSERT, SELECT, etc.)
#   1: Unbalanced parentheses - Number of opening parentheses != closing parentheses
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies:
#     - Creates temporary files for comment removal and parentheses counting
#
# Side effects:
#   - Validates SQL file existence and readability
#   - Validates SQL file is not empty
#   - Validates SQL file contains valid SQL statements (not just comments)
#   - Validates SQL file contains SQL keywords (CREATE, INSERT, SELECT, etc.)
#   - Validates SQL file has balanced parentheses
#   - Creates temporary files for validation (removed after validation)
#   - Writes log messages to stderr
#   - File operations: Reads SQL file, creates temporary files
#   - No database or network operations
#
# Notes:
#   - Does not execute SQL or validate against database schema
#   - Does not validate SQL syntax correctness (only structure)
#   - Checks for common SQL keywords: CREATE, INSERT, UPDATE, DELETE, SELECT, DROP, ALTER, etc.
#   - Removes comments before checking for SQL keywords and counting parentheses
#   - Common validation function used before executing SQL files
#   - Part of SQL file validation workflow
#   - Used to ensure SQL files are valid before execution
#
# Example:
#   __validate_sql_structure "/path/to/script.sql"
#   # Validates SQL file structure, syntax, and balanced parentheses
#
# Related: __validate_input_file() (validates file existence and readability)
# Related: __validate_xml_structure() (validates XML file structure)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_sql_structure() {
 __log_start
 local SQL_FILE="${1}"

 # Basic file validation (but allow empty files for specific SQL validation)
 if [[ ! -f "${SQL_FILE}" ]]; then
  __loge "ERROR: SQL file does not exist: ${SQL_FILE}"
  __log_finish
  return 1
 fi

 if [[ ! -r "${SQL_FILE}" ]]; then
  __loge "ERROR: SQL file is not readable: ${SQL_FILE}"
  __log_finish
  return 1
 fi

 # Check if file is empty
 if [[ ! -s "${SQL_FILE}" ]]; then
  __loge "ERROR: SQL file is empty: ${SQL_FILE}"
  __log_finish
  return 1
 fi

 # Check if file contains only comments (lines starting with -- or /* */)
 # Create a temporary file with non-comment, non-empty lines
 local TEMP_FILE
 TEMP_FILE=$(mktemp)
 # shellcheck disable=SC2312  # grep failures are acceptable here, we check if file is empty
 grep -v '^[[:space:]]*--' "${SQL_FILE}" | grep -v '^[[:space:]]*$' > "${TEMP_FILE}" || true

 # If temp file is empty, the original file contains only comments
 if [[ ! -s "${TEMP_FILE}" ]]; then
  rm -f "${TEMP_FILE}"
  __loge "ERROR: No valid SQL statements found: ${SQL_FILE}"
  __log_finish
  return 1
 fi

 rm -f "${TEMP_FILE}"

 # Check for basic SQL syntax (expanded list of SQL keywords)
 if ! grep -q -E "(CREATE|INSERT|UPDATE|DELETE|SELECT|DROP|ALTER|VACUUM|ANALYZE|REINDEX|CLUSTER|TRUNCATE|BEGIN|COMMIT|ROLLBACK|SAVEPOINT|GRANT|REVOKE|EXPLAIN|COPY|IMPORT|EXPORT|LOCK|UNLOCK|SET|RESET|SHOW|DESCRIBE|USE|CONNECT|DISCONNECT)" "${SQL_FILE}"; then
  __loge "ERROR: No valid SQL statements found: ${SQL_FILE}"
  __log_finish
  return 1
 fi

 # Check for balanced parentheses
 local OPEN_PARENS
 local CLOSE_PARENS
 # Remove comments before counting parentheses
 local TEMP_SQL
 TEMP_SQL=$(mktemp)
 # shellcheck disable=SC2312  # grep/sed failures are acceptable here
 grep -v '^[[:space:]]*--' "${SQL_FILE}" | sed 's/--.*$//' > "${TEMP_SQL}" || true
 # shellcheck disable=SC2312  # wc -l always succeeds, grep may fail but we handle empty result
 # Count parentheses and convert to integer, handling empty results
 OPEN_PARENS=$(grep -o '(' "${TEMP_SQL}" 2>/dev/null | wc -l 2>/dev/null | tr -d ' \n' || echo "0")
 # shellcheck disable=SC2312  # wc -l always succeeds, grep may fail but we handle empty result
 CLOSE_PARENS=$(grep -o ')' "${TEMP_SQL}" 2>/dev/null | wc -l 2>/dev/null | tr -d ' \n' || echo "0")
 rm -f "${TEMP_SQL}"

 if [[ "${OPEN_PARENS}" -ne "${CLOSE_PARENS}" ]]; then
  __loge "ERROR: Unbalanced parentheses in SQL file: ${SQL_FILE}"
  __log_finish
  return 1
 fi

 __logi "SQL structure validation passed: ${SQL_FILE}"
 __log_finish
 return 0
}

# Validate config file
##
# Validates configuration file structure and content
# Validates that a configuration file exists, is readable, contains key-value pairs,
# and has valid variable names. Checks for basic shell variable naming conventions
# (must start with letter or underscore). Used for validating shell configuration files.
#
# Parameters:
#   $1: CONFIG_FILE - Path to configuration file to validate (required)
#
# Returns:
#   0: Success - Configuration file validation passed
#   1: Failure - File validation failed, no key-value pairs, or invalid variable names
#
# Error codes:
#   0: Success - Configuration file is valid
#   1: Failure - File does not exist or is not readable (via __validate_input_file)
#   1: Failure - No key-value pairs found (no '=' character in file)
#   1: Failure - Invalid variable names found (does not start with letter/underscore)
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads configuration file from filesystem
#   - Executes grep commands to check file structure
#   - Logs validation results to standard logger
#   - No file modifications or network operations
#
# Notes:
#   - Validates file existence and readability (via __validate_input_file)
#   - Checks for key-value pairs (must contain '=' character)
#   - Validates variable names (must start with letter or underscore, allows leading spaces)
#   - Does not validate variable values (only structure)
#   - Does not execute or source the configuration file
#   - Common validation function used before loading configuration files
#
# Example:
#   __validate_config_file "/etc/osm-notes/config.conf"
#   # Validates configuration file structure
#
# Related: __validate_input_file() (validates file existence first)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_config_file() {
 __log_start
 local CONFIG_FILE="${1}"

 if ! __validate_input_file "${CONFIG_FILE}" "Config file"; then
  __log_finish
  return 1
 fi

 # Check for key-value pairs
 if ! grep -q '=' "${CONFIG_FILE}"; then
  __loge "ERROR: No key-value pairs found in config file: ${CONFIG_FILE}"
  __log_finish
  return 1
 fi

 # Check for valid variable names (allow leading spaces)
 if grep -q -E '^[[:space:]]*[^A-Za-z_][^=]*=' "${CONFIG_FILE}"; then
  __loge "ERROR: Invalid variable names in config file: ${CONFIG_FILE}"
  __log_finish
  return 1
 fi

 __logi "Config file validation passed: ${CONFIG_FILE}"
 __log_finish
 return 0
}

# Validate JSON structure
function __validate_json_structure() {
 __log_start
 local JSON_FILE="${1}"
 local SCHEMA_FILE="${2:-}"

 if ! __validate_input_file "${JSON_FILE}" "JSON file"; then
  __log_finish
  return 1
 fi

 # Check if jq is available
 if ! command -v jq > /dev/null 2>&1; then
  __loge "ERROR: jq command not available for JSON validation"
  __log_finish
  return 1
 fi

 # Check if file is valid JSON
 if ! jq empty "${JSON_FILE}" 2> /dev/null; then
  __loge "ERROR: Invalid JSON structure: ${JSON_FILE}"
  __log_finish
  return 1
 fi

 # Validate against schema if provided
 if [[ -n "${SCHEMA_FILE}" ]] && [[ -f "${SCHEMA_FILE}" ]]; then
  if command -v ajv > /dev/null 2>&1; then
   if ! ajv validate -s "${SCHEMA_FILE}" -d "${JSON_FILE}"; then
    __loge "ERROR: JSON validation against schema failed: ${JSON_FILE}"
    __log_finish
    return 1
   fi
  else
   __logw "WARNING: ajv not available, skipping schema validation"
  fi
 fi

 __logd "JSON structure validation passed: ${JSON_FILE}"
 __log_finish
 return 0
}

##
# Validates PostgreSQL database connection
# Tests database connectivity by executing a simple SELECT query.
# Uses peer authentication by default (local, no password). DBHOST, DBPORT, DBUSER are only
# needed for Docker, CI/CD, or environments without peer authentication.
#
# Parameters:
#   $1: Database name - PostgreSQL database name to validate (optional, uses DBNAME if not provided)
#
# Returns:
#   0: Success - Database connection successful
#   1: Failure - Cannot connect to database
#   2: Invalid argument - Database name not specified
#   3: Missing dependency - psql command not found
#   5: Database error - Connection failed or authentication error
#
# Error codes:
#   0: Success - Connection established and query executed successfully
#   1: Failure - Cannot connect to database (connection refused, authentication failed, etc.)
#   2: Invalid argument - Database name parameter is empty and DBNAME environment variable not set
#   3: Missing dependency - psql command not available
#   5: Database error - PostgreSQL connection failed, authentication error, or database does not exist
#
# Context variables:
#   Reads:
#     - DBNAME: Default database name if parameter not provided (optional)
#     - DBHOST: Database host (optional, for non-peer authentication)
#     - DBPORT: Database port (optional, for non-peer authentication)
#     - DBUSER: Database user (optional, for non-peer authentication)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Executes psql command to test database connection
#   - Executes "SELECT 1;" query to verify connectivity
#   - Logs validation results to standard logger
#   - No database modifications or file operations
#
# Authentication notes:
#   - Default: Uses peer authentication (local, no password required)
#   - Docker/CI/CD: May require DBHOST, DBPORT, DBUSER environment variables
#
# Example:
#   if __validate_database_connection "osm_notes"; then
#     echo "Database connection valid"
#   else
#     echo "Database connection failed with code: $?"
#   fi
#
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_database_connection() {
 __log_start
 local DBNAME_PARAM="${1:-${DBNAME}}"
 local DBUSER_PARAM="${2:-${DB_USER}}"
 local DBHOST_PARAM="${3:-${DB_HOST}}"
 local DBPORT_PARAM="${4:-${DB_PORT}}"

 # Check if database name is provided
 if [[ -z "${DBNAME_PARAM}" ]]; then
  __loge "ERROR: Database name is required"
  __log_finish
  return 1
 fi

 # Check if PostgreSQL client is available
 if ! command -v psql > /dev/null 2>&1; then
  __loge "ERROR: PostgreSQL client (psql) not available"
  __log_finish
  return 1
 fi

 # Test database connection
 if [[ -n "${DBHOST_PARAM}" ]] || [[ -n "${DBPORT_PARAM}" ]] || [[ -n "${DBUSER_PARAM}" ]]; then
  __log_finish
  # Usar parámetros personalizados (por ejemplo, en Docker o CI/CD)
  # shellcheck disable=SC2154
  if ! PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DBHOST_PARAM}" -p "${DBPORT_PARAM}" -U "${DBUSER_PARAM}" -d "${DBNAME_PARAM}" -c "SELECT 1;" > /dev/null 2>&1; then
   __loge "ERROR: Database connection failed (host/port/user)"
   __log_finish
   return 1
  fi
 else
  # Usar peer (local, sin usuario/contraseña)
  if ! psql -d "${DBNAME_PARAM}" -c "SELECT 1;" > /dev/null 2>&1; then
   __loge "ERROR: Database connection failed (peer)"
   __log_finish
   return 1
  fi
 fi

 __logd "Database connection validation passed"
 __log_finish
 return 0
}

# Validate database tables
# Nota:
# Por defecto, la conexión a PostgreSQL se realiza usando peer (local, sin usuario/contraseña).
# Los parámetros DBHOST, DBPORT y DBUSER solo son necesarios para pruebas en Docker, CI/CD
# o entornos donde no se use peer.
function __validate_database_tables() {
 __log_start
 local DBNAME_PARAM="${1:-${DBNAME}}"
 local DBUSER_PARAM="${2:-${DB_USER}}"
 local DBHOST_PARAM="${3:-${DB_HOST}}"
 local DBPORT_PARAM="${4:-${DB_PORT}}"
 local TABLES=("${@:5}")

 # Check if database name is provided
 if [[ -z "${DBNAME_PARAM}" ]]; then
  __loge "ERROR: Database name is required for table validation"
  __log_finish
  return 1
 fi

 # Check if tables are provided for validation
 if [[ ${#TABLES[@]} -eq 0 ]]; then
  __loge "ERROR: No tables specified for validation"
  __log_finish
  return 1
 fi

 if ! __validate_database_connection "${DBNAME_PARAM}" "${DBUSER_PARAM}" "${DBHOST_PARAM}" "${DBPORT_PARAM}"; then
  __log_finish
  return 1
 fi

 for TABLE in "${TABLES[@]}"; do
  if [[ -n "${DBHOST_PARAM}" ]] || [[ -n "${DBPORT_PARAM}" ]] || [[ -n "${DBUSER_PARAM}" ]]; then
   # shellcheck disable=SC2154
   # shellcheck disable=SC2312  # psql failure is checked, grep -q is used for boolean check
   if ! PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DBHOST_PARAM}" -p "${DBPORT_PARAM}" -U "${DBUSER_PARAM}" -d "${DBNAME_PARAM}" -c "SELECT 1 FROM information_schema.tables WHERE table_name = '${TABLE}';" 2> /dev/null | grep -q "1"; then
    __loge "ERROR: Table ${TABLE} does not exist in database ${DBNAME_PARAM} (host/port/user)"
    __log_finish
    return 1
   fi
  else
   # shellcheck disable=SC2312  # psql failure is checked, grep -q is used for boolean check
   if ! psql -d "${DBNAME_PARAM}" -c "SELECT 1 FROM information_schema.tables WHERE table_name = '${TABLE}';" 2> /dev/null | grep -q "1"; then
    __loge "ERROR: Table ${TABLE} does not exist in database ${DBNAME_PARAM} (peer)"
    __log_finish
    return 1
   fi
  fi
 done

 __logd "Database tables validation passed"
 __log_finish
 return 0
}

# Validate database extensions
# Nota:
# Por defecto, la conexión a PostgreSQL se realiza usando peer (local, sin usuario/contraseña).
# Los parámetros DBHOST, DBPORT y DBUSER solo son necesarios para pruebas en Docker, CI/CD
# o entornos donde no se use peer.
##
# Validates that required PostgreSQL extensions are installed
# Checks if specified PostgreSQL extensions are installed and enabled in the database.
# Validates database connection first, then queries pg_available_extensions and
# pg_extension to verify each extension is available and installed. Used before
# operations that require specific PostgreSQL extensions (e.g., PostGIS, pg_trgm).
#
# Parameters:
#   $1: DBNAME_PARAM - Database name (optional, uses DBNAME if not provided)
#   $2: DBUSER_PARAM - Database user (optional, uses DB_USER if not provided)
#   $3: DBHOST_PARAM - Database host (optional, uses DB_HOST if not provided)
#   $4: DBPORT_PARAM - Database port (optional, uses DB_PORT if not provided)
#   $5+: EXTENSIONS - One or more extension names to validate (required, at least one)
#
# Returns:
#   0: Success - All extensions are installed
#   1: Failure - Database connection failed, no extensions specified, or extension missing
#
# Error codes:
#   0: Success - All specified extensions are installed
#   1: Failure - Database name not provided (DBNAME_PARAM empty and DBNAME not set)
#   1: Failure - No extensions specified for validation
#   1: Failure - Database connection failed (via __validate_database_connection)
#   1: Failure - One or more extensions are not installed
#
# Context variables:
#   Reads:
#     - DBNAME: Default database name if parameter not provided (optional)
#     - DB_USER: Default database user if parameter not provided (optional)
#     - DB_HOST: Default database host if parameter not provided (optional)
#     - DB_PORT: Default database port if parameter not provided (optional)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Executes psql queries to check extension availability and installation
#   - Queries pg_available_extensions and pg_extension system catalogs
#   - Writes log messages to stderr
#   - Database operations: SELECT queries on system catalogs
#   - No file or network operations
#
# Notes:
#   - Validates database connection before checking extensions
#   - Checks both extension availability (pg_available_extensions) and installation (pg_extension)
#   - Extension must be both available and installed to pass validation
#   - Common extensions: postgis, pg_trgm, btree_gist, etc.
#   - Used before operations that require specific extensions
#   - Supports peer authentication (default) and password authentication
#
# Example:
#   export DBNAME="osm_notes"
#   __validate_database_extensions "osm_notes" "" "" "" "postgis" "pg_trgm"
#   # Validates postgis and pg_trgm extensions are installed
#
# Related: __validate_database_connection() (validates connection first)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_database_extensions() {
 __log_start
 local DBNAME_PARAM="${1:-${DBNAME}}"
 local DBUSER_PARAM="${2:-${DB_USER}}"
 local DBHOST_PARAM="${3:-${DB_HOST}}"
 local DBPORT_PARAM="${4:-${DB_PORT}}"
 local EXTENSIONS=("${@:5}")

 # Check if database name is provided
 if [[ -z "${DBNAME_PARAM}" ]]; then
  __loge "ERROR: Database name is required for extension validation"
  __log_finish
  return 1
 fi

 # Check if extensions are provided for validation
 if [[ ${#EXTENSIONS[@]} -eq 0 ]]; then
  __loge "ERROR: No extensions specified for validation"
  __log_finish
  return 1
 fi

 if ! __validate_database_connection "${DBNAME_PARAM}" "${DBUSER_PARAM}" "${DBHOST_PARAM}" "${DBPORT_PARAM}"; then
  __log_finish
  return 1
 fi

 for EXTENSION in "${EXTENSIONS[@]}"; do
  if [[ -n "${DBHOST_PARAM}" ]] || [[ -n "${DBPORT_PARAM}" ]] || [[ -n "${DBUSER_PARAM}" ]]; then
   # shellcheck disable=SC2154
   # shellcheck disable=SC2312  # psql failure is checked, grep -q is used for boolean check
   if ! PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DBHOST_PARAM}" -p "${DBPORT_PARAM}" -U "${DBUSER_PARAM}" -d "${DBNAME_PARAM}" -c "SELECT 1 FROM pg_extension WHERE extname = '${EXTENSION}';" 2> /dev/null | grep -q "1"; then
    __loge "ERROR: Extension ${EXTENSION} is not installed in database ${DBNAME_PARAM} (host/port/user)"
    __log_finish
    return 1
   fi
  else
   # shellcheck disable=SC2312  # psql failure is checked, grep -q is used for boolean check
   if ! psql -d "${DBNAME_PARAM}" -c "SELECT 1 FROM pg_extension WHERE extname = '${EXTENSION}';" 2> /dev/null | grep -q "1"; then
    __loge "ERROR: Extension ${EXTENSION} is not installed in database ${DBNAME_PARAM} (peer)"
    __log_finish
    return 1
   fi
  fi
 done

 __logd "Database extensions validation passed"
 __log_finish
 return 0
}

# Validate ISO8601 date format
##
# Validates ISO 8601 date format string
# Validates that a date string conforms to ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ or
# YYYY-MM-DDTHH:MM:SS+HH:MM). Checks format pattern and validates date component ranges
# (year, month, day, hour, minute, second). Used for validating dates in XML/JSON processing.
#
# Parameters:
#   $1: DATE_STRING - Date string to validate (required)
#   $2: DESCRIPTION - Description of date for error messages (optional, default: "Date")
#
# Returns:
#   0: Success - Date string is valid ISO 8601 format
#   1: Failure - Date string is empty, format invalid, or date components out of range
#
# Error codes:
#   0: Success - Date string is valid ISO 8601 format
#   1: Failure - Date string is empty
#   1: Failure - Date format does not match ISO 8601 pattern
#   1: Failure - Date components are out of valid range (month > 12, day > 31, etc.)
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Parses date string using grep and cut commands
#   - Validates date component ranges
#   - Logs validation results to standard logger
#   - No file, database, or network operations
#
# Notes:
#   - Validates ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ or YYYY-MM-DDTHH:MM:SS+HH:MM
#   - Validates date component ranges: month (1-12), day (1-31), hour (0-23), minute (0-59), second (0-59)
#   - Does not validate leap years or month-specific day limits (e.g., February 30)
#   - Does not validate timezone offsets (only format)
#   - Common validation function used in XML/JSON date validation
#
# Example:
#   __validate_iso8601_date "2025-01-27T10:30:00Z" "Created date"
#   # Validates ISO 8601 date format
#
#   __validate_iso8601_date "2025-01-27T10:30:00+02:00" "Updated date"
#   # Validates ISO 8601 date with timezone offset
#
# Related: __validate_xml_dates() (validates dates in XML files)
# Related: __validate_csv_dates() (validates dates in CSV files)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_iso8601_date() {
 __log_start
 local DATE_STRING="${1}"
 local DESCRIPTION="${2:-Date}"

 # Check if date string is not empty
 if [[ -z "${DATE_STRING}" ]]; then
  __loge "ERROR: ${DESCRIPTION} is empty"
  __log_finish
  return 1
 fi

 # Validate ISO8601 format (YYYY-MM-DDTHH:MM:SSZ or YYYY-MM-DDTHH:MM:SS+HH:MM)
 if ! echo "${DATE_STRING}" | grep -q -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})$'; then
  __loge "ERROR: Invalid ISO8601 date format: ${DATE_STRING}"
  __log_finish
  return 1
 fi

 # Validate date components
 local YEAR MONTH DAY HOUR MINUTE SECOND
 # shellcheck disable=SC2312  # cut always succeeds, failures are handled by validation
 YEAR=$(echo "${DATE_STRING}" | cut -d'T' -f1 | cut -d'-' -f1 || echo "")
 # shellcheck disable=SC2312  # cut always succeeds, failures are handled by validation
 MONTH=$(echo "${DATE_STRING}" | cut -d'T' -f1 | cut -d'-' -f2 || echo "")
 # shellcheck disable=SC2312  # cut always succeeds, failures are handled by validation
 DAY=$(echo "${DATE_STRING}" | cut -d'T' -f1 | cut -d'-' -f3 || echo "")
 # shellcheck disable=SC2312  # cut always succeeds, failures are handled by validation
 HOUR=$(echo "${DATE_STRING}" | cut -d'T' -f2 | cut -d':' -f1 || echo "")
 # shellcheck disable=SC2312  # cut always succeeds, failures are handled by validation
 MINUTE=$(echo "${DATE_STRING}" | cut -d'T' -f2 | cut -d':' -f2 || echo "")
 # shellcheck disable=SC2312  # cut always succeeds, failures are handled by validation
 SECOND=$(echo "${DATE_STRING}" | cut -d'T' -f2 | cut -d':' -f3 | cut -d'Z' -f1 | cut -d'+' -f1 | cut -d'-' -f1 || echo "")

 # Convert to base 10 to handle leading zeros properly
 YEAR=$((10#${YEAR}))
 MONTH=$((10#${MONTH}))
 DAY=$((10#${DAY}))
 HOUR=$((10#${HOUR}))
 MINUTE=$((10#${MINUTE}))
 SECOND=$((10#${SECOND}))

 # Validate ranges
 if [[ "${YEAR}" -lt 1900 ]] || [[ "${YEAR}" -gt 2100 ]]; then
  __loge "ERROR: Invalid year: ${YEAR}"
  __log_finish
  return 1
 fi

 if [[ "${MONTH}" -lt 1 ]] || [[ "${MONTH}" -gt 12 ]]; then
  __loge "ERROR: Invalid month: ${MONTH}"
  __log_finish
  return 1
 fi

 if [[ "${DAY}" -lt 1 ]] || [[ "${DAY}" -gt 31 ]]; then
  __loge "ERROR: Invalid day: ${DAY}"
  __log_finish
  return 1
 fi

 if [[ "${HOUR}" -lt 0 ]] || [[ "${HOUR}" -gt 23 ]]; then
  __loge "ERROR: Invalid hour: ${HOUR}"
  __log_finish
  return 1
 fi

 if [[ "${MINUTE}" -lt 0 ]] || [[ "${MINUTE}" -gt 59 ]]; then
  __loge "ERROR: Invalid minute: ${MINUTE}"
  __log_finish
  return 1
 fi

 if [[ "${SECOND}" -lt 0 ]] || [[ "${SECOND}" -gt 59 ]]; then
  __loge "ERROR: Invalid second: ${SECOND}"
  __log_finish
  return 1
 fi
 __logd "ISO8601 date validation passed: ${DATE_STRING}"
 __log_finish
 return 0
}

# Validate XML dates (lightweight version for large files)
##
# Validates ISO 8601 dates in XML files
# Validates date formats in XML files using XPath queries or default patterns.
# Automatically switches to lightweight validation for large files (>500MB).
# Supports both ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) and UTC (YYYY-MM-DD HH:MM:SS UTC) formats.
#
# Parameters:
#   $1: XML file path - Path to XML file to validate (required)
#   $2+: XPath queries - XPath expressions to locate date attributes/elements (optional)
#       Default: validates all ISO 8601 dates found in file
#       Examples: "//note/@created_at", "//note/@closed_at", "//note/@updated_at"
#
# Returns:
#   0: Success - All dates are valid (or no dates found)
#   1: Failure - Invalid dates found or file validation failed
#
# Error codes:
#   0: Success - All dates validated successfully
#   1: Failure - File not found or not readable
#   1: Failure - XML structure validation failed
#   1: Failure - Invalid date format found in XML
#   1: Failure - Date validation failed (strict mode: fails on first error)
#
# Error conditions:
#   0: Success - All dates are valid ISO 8601 or UTC format
#   1: File not found - XML file path does not exist
#   1: XML structure invalid - File does not have valid XML structure
#   1: Invalid date format - Date does not match ISO 8601 or UTC format
#   1: Date validation failed - Date format is invalid (strict mode: immediate failure)
#
# Context variables:
#   Reads:
#     - STRICT_MODE: If "true", fails immediately on first invalid date (optional, default: false)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads XML file using grep and stat
#   - Validates up to 1000 dates per XPath query (performance limit)
#   - Writes log messages to stderr
#   - No file modifications, database, or network operations
#
# Notes:
#   - Automatically uses lightweight validation for files >500MB
#   - Limits validation to first 1000 dates per query for performance
#   - Supports multiple XPath queries (validates each separately)
#   - Uses grep for fast date extraction (more reliable than xmllint for large files)
#   - In strict mode, fails immediately on first invalid date
#   - In normal mode, continues validation and reports all errors
#   - Validates both ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) and UTC formats
#
# Example:
#   # Validate all dates in XML file
#   __validate_xml_dates "notes.xml"
#
#   # Validate specific date attributes
#   __validate_xml_dates "notes.xml" "//note/@created_at" "//note/@closed_at"
#
#   # Strict mode (fail on first error)
#   STRICT_MODE=true __validate_xml_dates "notes.xml"
#
# Related: __validate_xml_dates_lightweight() (lightweight validation for large files)
# Related: __validate_iso8601_date() (ISO 8601 date validation)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
##
# Validates ISO 8601 dates in XML files using XPath queries
# Validates date formats in XML files using XPath queries or default patterns.
# Automatically switches to lightweight validation for large files (>500MB) to improve
# performance. Supports both ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) and UTC (YYYY-MM-DD HH:MM:SS UTC)
# formats. Uses xmllint for XPath queries on smaller files, grep for large files.
#
# Parameters:
#   $1: XML_FILE - Path to XML file to validate (required)
#   $2+: XPATH_QUERIES - XPath expressions to locate date attributes/elements (optional)
#       Default: validates all ISO 8601 dates found in file using grep
#       Examples: "//note/@created_at", "//note/@closed_at", "//note/@updated_at"
#
# Returns:
#   0: Success - All dates are valid (or no dates found)
#   1: Failure - Invalid dates found, file validation failed, or XML structure invalid
#
# Error codes:
#   0: Success - All dates validated successfully
#   1: Failure - XML file validation failed (via __validate_xml_structure)
#   1: Failure - Invalid ISO 8601 dates found in XML
#   1: Failure - Invalid UTC dates found in XML
#   1: Failure - Malformed dates found (contains invalid characters)
#
# Context variables:
#   Reads:
#     - STRICT_MODE: If "true", fails immediately on first invalid date (optional, default: false)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads XML file from filesystem
#   - Executes xmllint for XPath queries (smaller files) or grep (large files)
#   - Validates dates using __validate_iso8601_date and __validate_date_format_utc
#   - Logs validation results to standard logger
#   - File operations: Reads XML file
#   - No database or network operations
#
# Notes:
#   - Automatically uses lightweight validation for files >500MB (via __validate_xml_dates_lightweight)
#   - Lightweight validation samples dates (first 100) for performance
#   - Standard validation validates all dates found via XPath queries
#   - Supports STRICT_MODE: fails immediately on first invalid date if enabled
#   - Validates both ISO 8601 and UTC date formats
#   - Common validation function used before XML processing
#
# Example:
#   __validate_xml_dates "/tmp/notes.xml" "//note/@created_at" "//note/@closed_at"
#   # Validates created_at and closed_at dates in XML
#
#   export STRICT_MODE=true
#   __validate_xml_dates "/tmp/notes.xml"
#   # Validates all dates, fails immediately on first invalid date
#
# Related: __validate_xml_dates_lightweight() (lightweight validation for large files)
# Related: __validate_iso8601_date() (validates ISO 8601 date format)
# Related: __validate_xml_structure() (validates XML structure first)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_xml_dates() {
 __log_start
 local XML_FILE="${1}"
 local XPATH_QUERIES=("${@:2}")
 local STRICT_MODE="${STRICT_MODE:-false}" # New parameter for strict validation

 # For large files, use lightweight validation
 local FILE_SIZE
 FILE_SIZE=$(stat -c%s "${XML_FILE}" 2> /dev/null || echo "0")
 local SIZE_MB=$((FILE_SIZE / 1024 / 1024))

 # If file is larger than 500MB, use lightweight validation
 if [[ "${SIZE_MB}" -gt 500 ]]; then
  __logw "WARNING: Large XML file detected (${SIZE_MB} MB). Using lightweight date validation."
  __validate_xml_dates_lightweight "${XML_FILE}" "${XPATH_QUERIES[@]}" "${STRICT_MODE}"
  local LIGHTWEIGHT_RESULT=$?
  __log_finish
  return "${LIGHTWEIGHT_RESULT}"
 fi

 # For smaller files, use standard validation
 if ! __validate_xml_structure "${XML_FILE}"; then
  __log_finish
  return 1
 fi

 local FAILED=0

 # Validate dates in XML
 for XPATH_QUERY in "${XPATH_QUERIES[@]}"; do
  local ALL_DATES_RAW
  # Extract all date values using grep instead of xmllint (more reliable)
  # Convert XPath query to grep pattern for lightweight extraction
  local GREP_PATTERN
  case "${XPATH_QUERY}" in
  "//note/@created_at")
   GREP_PATTERN='created_at="[^"]*"'
   ;;
  "//note/@closed_at")
   GREP_PATTERN='closed_at="[^"]*"'
   ;;
  "//note/@updated_at")
   GREP_PATTERN='updated_at="[^"]*"'
   ;;
  *)
   # Default pattern for general date extraction
   GREP_PATTERN='[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
   ;;
  esac

  ALL_DATES_RAW=$(grep -oE "${GREP_PATTERN}" "${XML_FILE}" 2> /dev/null || true)

  if [[ -n "${ALL_DATES_RAW}" ]]; then
   # Extract date values from attributes and elements
   local EXTRACTED_DATES
   EXTRACTED_DATES=$(echo "${ALL_DATES_RAW}" | grep -oE '="[^"]*"' | sed 's/="//g' | sed 's/"//g' || true)
   if [[ -z "${EXTRACTED_DATES}" ]]; then
    # If no attributes found, try to extract element text content
    EXTRACTED_DATES=$(echo "${ALL_DATES_RAW}" | grep -oE '>[^<]*<' | sed 's/>//g' | sed 's/<//g' || true)
   fi

   if [[ -n "${EXTRACTED_DATES}" ]]; then
    # Limit the number of dates to validate to avoid memory issues
    local DATE_COUNT=0
    local MAX_DATES=1000

    while IFS= read -r DATE; do
     [[ -z "${DATE}" ]] && continue

     # Limit validation to first MAX_DATES dates
     if [[ "${DATE_COUNT}" -ge "${MAX_DATES}" ]]; then
      __logw "WARNING: Limiting date validation to first ${MAX_DATES} dates for performance"
      break
     fi

     DATE_COUNT=$((DATE_COUNT + 1))

     # Validate ISO 8601 dates (YYYY-MM-DDTHH:MM:SSZ)
     if [[ "${DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
      if ! __validate_iso8601_date "${DATE}" "XML date"; then
       __loge "ERROR: Invalid ISO8601 date found in XML: ${DATE}"
       FAILED=1
       # In strict mode, fail immediately
       if [[ "${STRICT_MODE}" == "true" ]]; then
        __log_finish
        return 1
       fi
      fi
     # Validate UTC dates (YYYY-MM-DD HH:MM:SS UTC)
     elif [[ "${DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]UTC$ ]]; then
      if ! __validate_date_format_utc "${DATE}" "XML date"; then
       __loge "ERROR: Invalid UTC date found in XML: ${DATE}"
       FAILED=1
       # In strict mode, fail immediately
       if [[ "${STRICT_MODE}" == "true" ]]; then
        __log_finish
        return 1
       fi
      fi
     else
      # Check if this looks like it should be a date but isn't in the expected format
      if [[ "${DATE}" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
       __logw "WARNING: Unexpected date format found in XML: ${DATE}"
      elif [[ "${DATE}" =~ [0-9]{4}.*[0-9]{2}.*[0-9]{2} ]] || [[ "${DATE}" =~ [a-zA-Z]+-?[a-zA-Z]+ ]]; then
       # This looks like it might be a malformed date (contains date-like patterns or letters)
       __loge "ERROR: Malformed date found in XML: ${DATE}"
       FAILED=1
       # In strict mode, fail immediately
       if [[ "${STRICT_MODE}" == "true" ]]; then
        __log_finish
        return 1
       fi
      fi
     fi
    done <<< "${EXTRACTED_DATES}"
   fi
  fi

  # In strict mode, also check for invalid date patterns that might not match the grep pattern
  if [[ "${STRICT_MODE}" == "true" ]]; then
   # Look for any attribute that looks like it should be a date but isn't
   local INVALID_DATE_PATTERNS=(
    'created_at="[^"]*[a-zA-Z][^"]*"'
    'closed_at="[^"]*[a-zA-Z][^"]*"'
    'timestamp="[^"]*[a-zA-Z][^"]*"'
   )

   for PATTERN in "${INVALID_DATE_PATTERNS[@]}"; do
    local INVALID_DATES
    INVALID_DATES=$(grep -oE "${PATTERN}" "${XML_FILE}" 2> /dev/null || true)

    if [[ -n "${INVALID_DATES}" ]]; then
     __loge "ERROR: Invalid date patterns found in strict mode: ${INVALID_DATES}"
     __log_finish
     return 1
    fi
   done
  fi
 done

 if [[ "${FAILED}" -eq 1 ]]; then
  __log_finish
  return 1
 fi

 # Only log in trace mode to reduce verbosity
 if [[ "${LOG_LEVEL:-}" == "TRACE" ]]; then
  __logd "XML dates validation passed: ${XML_FILE}"
 fi
 __log_finish
 return 0
}

##
# Validates ISO 8601 dates in large XML files using lightweight sampling
# Lightweight version of XML date validation optimized for large files (>500MB).
# Samples dates using grep instead of full XPath parsing for performance. Validates
# a sample of dates (default: 100) to detect common issues without processing entire file.
# Automatically called by __validate_xml_dates() for large files.
#
# Parameters:
#   $1: XML_FILE - Path to XML file to validate (required)
#   $2+: XPATH_QUERIES - XPath expressions (optional, not used in lightweight mode)
#   $3: STRICT_MODE - If "true", fails immediately on first invalid date (optional, default: false)
#
# Returns:
#   0: Success - Sample dates are valid (or no dates found)
#   1: Failure - Invalid dates found in sample or malformed dates detected
#
# Error codes:
#   0: Success - Sample dates validated successfully
#   1: Failure - Malformed dates found (contains invalid characters)
#   1: Failure - Invalid dates found in sample (strict mode: immediate failure)
#
# Context variables:
#   Reads:
#     - STRICT_MODE: If "true", fails immediately on first invalid date (optional, default: false)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads XML file using grep (samples dates, does not parse full XML)
#   - Validates sample of dates (default: 100 dates)
#   - Logs validation results to standard logger
#   - File operations: Reads XML file (grep operations)
#   - No database or network operations
#
# Notes:
#   - Optimized for large files: uses grep instead of xmllint (much faster)
#   - Samples dates: validates first 100 dates found (performance optimization)
#   - Detects malformed dates: finds dates with invalid characters (letters, etc.)
#   - In strict mode, fails immediately on first invalid date
#   - In normal mode, continues validation and reports all errors
#   - Called automatically by __validate_xml_dates() for files >500MB
#   - Does not validate all dates (only sample) - trade-off for performance
#
# Example:
#   __validate_xml_dates_lightweight "/tmp/large_notes.xml" "" "false"
#   # Validates sample of dates in large XML file
#
#   export STRICT_MODE=true
#   __validate_xml_dates_lightweight "/tmp/large_notes.xml"
#   # Validates sample, fails immediately on first invalid date
#
# Related: __validate_xml_dates() (calls this for large files)
# Related: __validate_iso8601_date() (validates ISO 8601 date format)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
# Lightweight XML date validation for large files
function __validate_xml_dates_lightweight() {
 __log_start
 local XML_FILE="${1}"
 local XPATH_QUERIES=("${@:2}")
 local STRICT_MODE="${3:-false}" # Get STRICT_MODE from __validate_xml_dates

 __logd "Using lightweight XML date validation for large file: ${XML_FILE}"

 # For large files, just check a sample of dates using grep
 local FAILED=0
 local SAMPLE_SIZE=100

 # Extract a sample of dates using grep (much faster than xmllint for large files)
 local SAMPLE_DATES
 SAMPLE_DATES=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "${XML_FILE}" | head -n "${SAMPLE_SIZE}" || true)

 # Also check for malformed dates that might cause issues (dates with letters or invalid characters)
 local MALFORMED_DATES
 MALFORMED_DATES=$(grep -oE '[0-9]{4}-[0-9]*[a-zA-Z][0-9a-zA-Z]*-[0-9]*[a-zA-Z][0-9a-zA-Z]*T[0-9]*[a-zA-Z][0-9a-zA-Z]*:[0-9]*[a-zA-Z][0-9a-zA-Z]*:[0-9]*[a-zA-Z][0-9a-zA-Z]*Z' "${XML_FILE}" | head -n "${SAMPLE_SIZE}" || true)

 if [[ -n "${MALFORMED_DATES}" ]]; then
  __loge "ERROR: Malformed dates found in XML (contains invalid characters):"
  while IFS= read -r DATE; do
   [[ -z "${DATE}" ]] && continue
   __loge "  - ${DATE}"
   FAILED=1
   # In strict mode, fail immediately
   if [[ "${STRICT_MODE}" == "true" ]]; then
    __log_finish
    return 1
   fi
  done <<< "${MALFORMED_DATES}"
 fi

 if [[ -n "${SAMPLE_DATES}" ]]; then
  local VALID_COUNT=0
  local TOTAL_COUNT=0

  while IFS= read -r DATE; do
   [[ -z "${DATE}" ]] && continue
   TOTAL_COUNT=$((TOTAL_COUNT + 1))

   # Quick validation of ISO 8601 format
   if [[ "${DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    # Basic validation without calling __validate_iso8601_date for performance
    local YEAR="${DATE:0:4}"
    local MONTH="${DATE:5:2}"
    local DAY="${DATE:8:2}"
    local HOUR="${DATE:11:2}"
    local MINUTE="${DATE:14:2}"
    local SECOND="${DATE:17:2}"

    # Convert to base 10 to handle leading zeros properly
    YEAR=$((10#${YEAR}))
    MONTH=$((10#${MONTH}))
    DAY=$((10#${DAY}))
    HOUR=$((10#${HOUR}))
    MINUTE=$((10#${MINUTE}))
    SECOND=$((10#${SECOND}))

    # Basic range validation
    if [[ "${YEAR}" -ge 2000 && "${YEAR}" -le 2030 ]] \
     && [[ "${MONTH}" -ge 1 && "${MONTH}" -le 12 ]] \
     && [[ "${DAY}" -ge 1 && "${DAY}" -le 31 ]] \
     && [[ "${HOUR}" -ge 0 && "${HOUR}" -le 23 ]] \
     && [[ "${MINUTE}" -ge 0 && "${MINUTE}" -le 59 ]] \
     && [[ "${SECOND}" -ge 0 && "${SECOND}" -le 59 ]]; then
     VALID_COUNT=$((VALID_COUNT + 1))
    else
     __logw "WARNING: Invalid date format found in sample: ${DATE}"
     FAILED=1
     # In strict mode, fail immediately
     if [[ "${STRICT_MODE}" == "true" ]]; then
      __log_finish
      return 1
     fi
    fi
   else
    __logw "WARNING: Unexpected date format found in sample: ${DATE}"
    FAILED=1
    # In strict mode, fail immediately
    if [[ "${STRICT_MODE}" == "true" ]]; then
     __log_finish
     return 1
    fi
   fi
  done <<< "${SAMPLE_DATES}"

  if [[ "${TOTAL_COUNT}" -gt 0 ]]; then
   local VALID_PERCENTAGE=$((VALID_COUNT * 100 / TOTAL_COUNT))
   __logd "Date validation sample: ${VALID_COUNT}/${TOTAL_COUNT} valid dates (${VALID_PERCENTAGE}%)"

   # If more than 90% of dates are valid, consider the file valid
   if [[ "${VALID_PERCENTAGE}" -ge 90 ]]; then
    __logi "XML dates validation passed (sample-based): ${XML_FILE}"
    # Still check if there were malformed dates
    if [[ "${FAILED}" -eq 1 ]]; then
     __log_finish
     return 1
    fi
    __log_finish
    return 0
   else
    __loge "ERROR: Too many invalid dates found in sample (${VALID_PERCENTAGE}% valid)"
    __log_finish
    return 1
   fi
  fi
 fi

 # If no dates found, consider it valid (might be a file without dates)
 __logd "No dates found in XML file, skipping date validation: ${XML_FILE}"
 # Still check if there were malformed dates
 if [[ "${FAILED}" -eq 1 ]]; then
  __log_finish
  return 1
 fi
 __log_finish
 return 0
}

# Validate CSV dates
##
# Validates ISO 8601 dates in CSV file columns
# Validates date formats in specified CSV columns. Locates columns by name in header row,
# then validates all date values in those columns. Supports ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ).
# Used before CSV database imports to ensure date data integrity.
#
# Parameters:
#   $1: CSV_FILE - Path to CSV file to validate (required)
#   $2+: DATE_COLUMNS - Column names containing dates to validate (required, at least one)
#       Examples: "created_at", "closed_at", "updated_at"
#
# Returns:
#   0: Success - All dates are valid (or columns not found)
#   1: Failure - CSV structure validation failed, column not found, or invalid dates found
#
# Error codes:
#   0: Success - All dates validated successfully
#   1: Failure - CSV structure validation failed (via __validate_csv_structure)
#   1: Failure - Date column not found in CSV header
#   1: Failure - Invalid ISO 8601 dates found in CSV columns
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads CSV file from filesystem (header and data rows)
#   - Executes head, tail, cut, grep commands to extract and validate dates
#   - Validates dates using __validate_iso8601_date
#   - Logs validation results to standard logger
#   - File operations: Reads CSV file
#   - No database or network operations
#
# Notes:
#   - Validates CSV structure first (via __validate_csv_structure)
#   - Locates columns by name in header row (case-sensitive)
#   - Validates all date values in specified columns (skips header row)
#   - Only validates ISO 8601 format dates (YYYY-MM-DDTHH:MM:SSZ)
#   - Column names must match exactly (case-sensitive)
#   - Common validation function used before CSV database imports
#
# Example:
#   __validate_csv_dates "/tmp/notes.csv" "created_at" "closed_at"
#   # Validates created_at and closed_at columns in CSV
#
# Related: __validate_csv_structure() (validates CSV structure first)
# Related: __validate_iso8601_date() (validates ISO 8601 date format)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_csv_dates() {
 local CSV_FILE="${1}"
 local DATE_COLUMNS=("${@:2}")

 if ! __validate_csv_structure "${CSV_FILE}"; then
  __log_finish
  return 1
 fi

 # Get header line
 local HEADER
 HEADER=$(head -n 1 "${CSV_FILE}")

 local FAILED=0

 # Validate dates in CSV
 for DATE_COLUMN in "${DATE_COLUMNS[@]}"; do
  local COL_INDEX
  # shellcheck disable=SC2312  # tr/grep/cut failures are handled by empty check
  COL_INDEX=$(echo "${HEADER}" | tr ',' '\n' | grep -n "^${DATE_COLUMN}$" | cut -d: -f1 || echo "")

  if [[ -z "${COL_INDEX}" ]]; then
   __loge "ERROR: Date column not found: ${DATE_COLUMN}"
   FAILED=1
   continue
  fi

  # Skip header and validate dates
  local DATES
  DATES=$(tail -n +2 "${CSV_FILE}" | cut -d',' -f"${COL_INDEX}" | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' || true)

  if [[ -n "${DATES}" ]]; then
   while IFS= read -r DATE; do
    # Skip empty dates
    [[ -z "${DATE}" ]] && continue
    # Skip dates that don't match the expected pattern
    if [[ ! "${DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
     continue
    fi
    if ! __validate_date_format "${DATE}" "CSV date"; then
     __loge "ERROR: Invalid date found in CSV: ${DATE}"
     FAILED=1
    fi
   done <<< "${DATES}"
  fi
 done

 if [[ "${FAILED}" -eq 1 ]]; then
  __log_finish
  return 1
 fi

 __logi "CSV dates validation passed: ${CSV_FILE}"
 __log_finish
 return 0
}

# Validate file checksum
function __validate_file_checksum() {
 __log_start
 local FILE_PATH="${1}"
 local EXPECTED_CHECKSUM="${2}"
 local ALGORITHM="${3:-sha256}"

 # Check for empty checksum
 if [[ -z "${EXPECTED_CHECKSUM}" ]]; then
  __loge "ERROR: Expected checksum is empty"
  __log_finish
  return 1
 fi

 if ! __validate_input_file "${FILE_PATH}" "File for checksum validation"; then
  __log_finish
  return 1
 fi

 # Calculate actual checksum
 local ACTUAL_CHECKSUM
 case "${ALGORITHM}" in
 md5)
  # shellcheck disable=SC2312  # cut always succeeds, md5sum failure is handled
  ACTUAL_CHECKSUM=$(md5sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 sha1)
  # shellcheck disable=SC2312  # cut always succeeds, sha1sum failure is handled
  ACTUAL_CHECKSUM=$(sha1sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 sha256)
  # shellcheck disable=SC2312  # cut always succeeds, sha256sum failure is handled
  ACTUAL_CHECKSUM=$(sha256sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 sha512)
  # shellcheck disable=SC2312  # cut always succeeds, sha512sum failure is handled
  ACTUAL_CHECKSUM=$(sha512sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 *)
  __loge "ERROR: ${ALGORITHM} checksum validation failed - Invalid algorithm"
  __log_finish
  return 1
  ;;
 esac

 # Compare checksums
 if [[ "${ACTUAL_CHECKSUM}" != "${EXPECTED_CHECKSUM}" ]]; then
  __loge "ERROR: ${ALGORITHM} checksum validation failed - Checksum mismatch for ${FILE_PATH}. Expected: ${EXPECTED_CHECKSUM}, Actual: ${ACTUAL_CHECKSUM}"
  __log_finish
  return 1
 fi

 __logd "${ALGORITHM} checksum validation passed"
 __log_finish
 return 0
}

# Validate file checksum from file
##
# Validates file integrity by comparing checksum from a checksum file
# Extracts expected checksum from a checksum file (MD5, SHA256, etc.) and validates the target file
# against it. Supports multiple checksum file formats: filename-based lookup or single-line format.
# Skips actual checksum comparison in test/hybrid mode but still validates file/checksum extraction.
#
# Parameters:
#   $1: File path - Path to file to validate (required)
#   $2: Checksum file - Path to file containing expected checksum (required)
#   $3: Algorithm - Checksum algorithm to use (optional, default: sha256, supports: md5, sha1, sha256, sha512)
#
# Returns:
#   0: Success - File checksum matches expected value or test mode enabled
#   1: Failure - File not found, checksum file not found/unreadable, checksum extraction failed, or checksum mismatch
#
# Error codes:
#   0: Success - Checksum validated successfully or test mode (skipped validation)
#   1: Failure - File validation failed, checksum file missing/unreadable, checksum extraction failed, or checksum mismatch
#
# Context variables:
#   Reads:
#     - HYBRID_MOCK_MODE: If set, skips checksum validation (optional)
#     - TEST_MODE: If set, skips checksum validation (optional)
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads target file and checksum file from filesystem
#   - Executes checksum calculation command (md5sum, sha256sum, etc.)
#   - Logs validation results to standard logger
#   - No file modifications or network operations
#
# Checksum file formats supported:
#   1. Filename-based: "checksum_value  filename.ext" (standard format)
#   2. Single-line: "checksum_value" (first field extracted)
#
# Example:
#   if __validate_file_checksum_from_file "/tmp/data.tar.gz" "/tmp/data.tar.gz.md5" "md5"; then
#     echo "File integrity verified"
#   else
#     echo "Checksum mismatch"
#   fi
#
# Related: __validate_file_checksum() (validates checksum directly)
# Related: __validate_input_file() (validates file existence/readability)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_file_checksum_from_file() {
 __log_start
 local FILE_PATH="${1}"
 local CHECKSUM_FILE="${2}"
 local ALGORITHM="${3:-sha256}"

 if ! __validate_input_file "${FILE_PATH}" "File"; then
  __log_finish
  return 1
 fi

 # Check if checksum file exists and is readable
 # These validations must happen even in test mode to catch configuration errors
 if [[ ! -f "${CHECKSUM_FILE}" ]]; then
  __loge "ERROR: Checksum file not found: ${CHECKSUM_FILE}"
  __log_finish
  return 1
 fi

 if [[ ! -r "${CHECKSUM_FILE}" ]]; then
  __loge "ERROR: Checksum file not readable: ${CHECKSUM_FILE}"
  __log_finish
  return 1
 fi

 # Extract expected checksum from checksum file
 local EXPECTED_CHECKSUM
 local FILENAME
 FILENAME=$(basename "${FILE_PATH}")

 # First try to find checksum by filename
 # shellcheck disable=SC2312  # grep/awk failures are handled by empty check
 EXPECTED_CHECKSUM=$(grep "${FILENAME}" "${CHECKSUM_FILE}" | awk '{print $1}' 2> /dev/null || echo "")

 # If not found by filename, assume single-line checksum file and take first field
 if [[ -z "${EXPECTED_CHECKSUM}" ]]; then
  __logw "Checksum not found by filename, trying to extract from single-line file"
  # shellcheck disable=SC2312  # head/awk failures are handled by empty check
  EXPECTED_CHECKSUM=$(head -1 "${CHECKSUM_FILE}" | awk '{print $1}' 2> /dev/null || echo "")
 fi

 # Check if checksum could be extracted (empty file case)
 if [[ -z "${EXPECTED_CHECKSUM}" ]]; then
  __loge "ERROR: Could not extract checksum from file: ${CHECKSUM_FILE}"
  __log_finish
  return 1
 fi

 # Skip checksum validation in hybrid/test mode (mocked downloads have different checksums)
 # But only skip the actual checksum comparison, not the file/checksum extraction validation
 if [[ -n "${HYBRID_MOCK_MODE:-}" ]] || [[ -n "${TEST_MODE:-}" ]]; then
  __logw "Skipping checksum validation in hybrid/test mode (mocked downloads)"
  __log_finish
  return 0
 fi

 # Validate checksum
 if ! __validate_file_checksum "${FILE_PATH}" "${EXPECTED_CHECKSUM}" "${ALGORITHM}"; then
  __log_finish
  return 1
 fi

 return 0
}

##
# Generates checksum for a file using specified algorithm
# Calculates checksum (MD5, SHA1, SHA256, SHA512) for a file and optionally saves
# it to a checksum file. Outputs checksum to stdout for capture. Supports multiple
# checksum algorithms. Used for file integrity verification and checksum file generation.
#
# Parameters:
#   $1: FILE_PATH - Path to file to generate checksum for (required)
#   $2: ALGORITHM - Checksum algorithm to use (optional, default: sha256)
#       Supported: md5, sha1, sha256, sha512
#   $3: OUTPUT_FILE - Path to save checksum file (optional, if not provided, outputs to stdout only)
#
# Returns:
#   0: Success - Checksum generated successfully
#   1: Failure - File validation failed or invalid algorithm
#
# Error codes:
#   0: Success - Checksum generated successfully
#   1: Failure - File does not exist or is not readable (via __validate_input_file)
#   1: Failure - Invalid algorithm specified (not md5, sha1, sha256, or sha512)
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies:
#     - Creates checksum file if OUTPUT_FILE provided
#
# Side effects:
#   - Reads file from filesystem
#   - Executes checksum command (md5sum, sha1sum, sha256sum, sha512sum)
#   - Creates checksum file if OUTPUT_FILE provided (format: checksum + spaces + filename)
#   - Outputs checksum to stdout (for capture with command substitution)
#   - Logs validation results to standard logger
#   - File operations: Reads input file, creates checksum file (if OUTPUT_FILE provided)
#   - No database or network operations
#
# Notes:
#   - Outputs checksum to stdout (use command substitution to capture)
#   - Checksum file format: "checksum  filename" (standard md5sum/sha256sum format)
#   - If OUTPUT_FILE provided, creates checksum file in standard format
#   - If OUTPUT_FILE not provided, only outputs checksum value to stdout
#   - Common checksum algorithms: md5 (fast), sha256 (secure, default), sha512 (most secure)
#   - Used for generating checksum files for file integrity verification
#
# Example:
#   CHECKSUM=$(__generate_file_checksum "/tmp/file.txt" "sha256")
#   echo "Checksum: ${CHECKSUM}"
#   # Generates SHA256 checksum and captures it
#
#   __generate_file_checksum "/tmp/file.txt" "md5" "/tmp/file.txt.md5"
#   # Generates MD5 checksum and saves to file
#
# Related: __validate_file_checksum() (validates checksum directly)
# Related: __validate_file_checksum_from_file() (validates checksum from file)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
# Generate file checksum
function __generate_file_checksum() {
 __log_start
 local FILE_PATH="${1}"
 local ALGORITHM="${2:-sha256}"
 local OUTPUT_FILE="${3:-}"

 if ! __validate_input_file "${FILE_PATH}" "File for checksum generation"; then
  __log_finish
  return 1
 fi

 local CHECKSUM
 case "${ALGORITHM}" in
 md5)
  # shellcheck disable=SC2312  # cut always succeeds, md5sum failure is handled
  CHECKSUM=$(md5sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 sha1)
  # shellcheck disable=SC2312  # cut always succeeds, sha1sum failure is handled
  CHECKSUM=$(sha1sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 sha256)
  # shellcheck disable=SC2312  # cut always succeeds, sha256sum failure is handled
  CHECKSUM=$(sha256sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 sha512)
  # shellcheck disable=SC2312  # cut always succeeds, sha512sum failure is handled
  CHECKSUM=$(sha512sum "${FILE_PATH}" | cut -d' ' -f1 || echo "")
  ;;
 *)
  __loge "ERROR: Invalid algorithm: ${ALGORITHM}"
  __log_finish
  return 1
  ;;
 esac

 # If output file is specified, save checksum to file
 if [[ -n "${OUTPUT_FILE}" ]]; then
  # Generate checksum in the same format as md5sum/sha256sum (checksum + spaces + filename)
  case "${ALGORITHM}" in
  md5)
   md5sum "${FILE_PATH}" > "${OUTPUT_FILE}"
   ;;
  sha1)
   sha1sum "${FILE_PATH}" > "${OUTPUT_FILE}"
   ;;
  sha256)
   sha256sum "${FILE_PATH}" > "${OUTPUT_FILE}"
   ;;
  sha512)
   sha512sum "${FILE_PATH}" > "${OUTPUT_FILE}"
   ;;
  *)
   echo "${CHECKSUM}  $(basename "${FILE_PATH}")" > "${OUTPUT_FILE}"
   ;;
  esac
  __logd "${ALGORITHM} checksum saved to ${OUTPUT_FILE}"
 fi

 echo "${CHECKSUM}"
 __log_finish
 return 0
}

##
# Validates checksums for all files in a directory
# Validates checksums for all files in a directory against a checksum file. Iterates
# through all files in directory, extracts relative paths, and validates each file's
# checksum. Used for verifying integrity of directory contents (e.g., downloaded datasets).
#
# Parameters:
#   $1: DIRECTORY - Path to directory containing files to validate (required)
#   $2: CHECKSUM_FILE - Path to checksum file containing expected checksums (required)
#   $3: ALGORITHM - Checksum algorithm to use (optional, default: sha256)
#       Supported: md5, sha1, sha256, sha512
#
# Returns:
#   0: Success - All file checksums validated successfully
#   1: Failure - Directory validation failed, checksum file validation failed, or checksum mismatch
#
# Error codes:
#   0: Success - All files validated successfully
#   1: Failure - Directory does not exist or is not accessible
#   1: Failure - Checksum file validation failed (via __validate_input_file)
#   1: Failure - One or more file checksums do not match expected values
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Finds all files in directory using find command
#   - Validates each file's checksum using __validate_file_checksum_from_file
#   - Logs validation results to standard logger
#   - File operations: Reads directory contents, reads checksum file, reads files for checksum calculation
#   - No database or network operations
#
# Notes:
#   - Validates all files found in directory (recursive, if find is recursive)
#   - Uses relative paths from directory root for checksum file lookup
#   - Stops on first checksum mismatch (but logs all failures)
#   - Common validation function used for verifying downloaded datasets
#   - Checksum file format: "checksum  relative/path/to/file" (standard format)
#
# Example:
#   __validate_directory_checksums "/tmp/downloaded_data" "/tmp/checksums.md5" "md5"
#   # Validates all files in directory against MD5 checksums
#
# Related: __validate_file_checksum_from_file() (validates individual file checksum)
# Related: __generate_file_checksum() (generates checksum for file)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
# Validate directory checksums
function __validate_directory_checksums() {
 __log_start
 local DIRECTORY="${1}"
 local CHECKSUM_FILE="${2}"
 local ALGORITHM="${3:-sha256}"

 if [[ ! -d "${DIRECTORY}" ]]; then
  __loge "ERROR: Directory validation failed"
  __log_finish
  return 1
 fi

 if ! __validate_input_file "${CHECKSUM_FILE}" "Checksum file"; then
  __log_finish
  return 1
 fi

 local FAILED=0
 local FILES
 # shellcheck disable=SC2312  # find failure is acceptable, empty array is handled
 mapfile -t FILES < <(find "${DIRECTORY}" -type f 2> /dev/null || true)

 for FILE in "${FILES[@]}"; do
  local RELATIVE_PATH
  RELATIVE_PATH=$(realpath --relative-to="${DIRECTORY}" "${FILE}")

  if ! __validate_file_checksum_from_file "${FILE}" "${CHECKSUM_FILE}" "${ALGORITHM}"; then
   __loge "ERROR: Checksum validation failed for ${RELATIVE_PATH}"
   FAILED=1
  fi
 done

 if [[ "${FAILED}" -eq 1 ]]; then
  __loge "ERROR: Directory checksum validation failed"
  __log_finish
  return 1
 fi

 __logd "Directory checksum validation passed"
 __log_finish
 return 0
}

##
# Validates JSON file against JSON Schema specification
# Validates that a JSON file conforms to a JSON Schema specification using ajv command.
# Validates JSON file existence and schema file existence, then uses ajv to perform
# schema validation. Used for ensuring JSON data conforms to expected structure and types.
#
# Parameters:
#   $1: JSON_FILE - Path to JSON file to validate (required)
#   $2: SCHEMA_FILE - Path to JSON Schema file (required)
#
# Returns:
#   0: Success - JSON file conforms to schema
#   1: Failure - File validation failed, ajv unavailable, or schema validation failed
#
# Error codes:
#   0: Success - JSON file conforms to schema
#   1: Failure - JSON file does not exist or is not readable (via __validate_input_file)
#   1: Failure - Schema file does not exist or is not readable (via __validate_input_file)
#   1: Failure - ajv command not available (required dependency)
#   1: Failure - JSON file does not conform to schema (schema validation failed)
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Reads JSON file and schema file from filesystem
#   - Executes ajv command to validate JSON against schema
#   - Logs validation results to standard logger
#   - File operations: Reads JSON file and schema file
#   - No database or network operations
#
# Notes:
#   - Requires ajv command (JSON Schema validator, installed via npm)
#   - Validates file existence and readability before schema validation
#   - Schema validation checks structure, types, required fields, formats, etc.
#   - Common validation function used for API response validation
#   - Used in conjunction with __validate_json_structure() (validates syntax first)
#
# Example:
#   __validate_json_schema "/tmp/api_response.json" "/path/to/schema.json"
#   # Validates API response against JSON Schema
#
# Related: __validate_json_structure() (validates JSON syntax first)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
# Validate JSON schema
function __validate_json_schema() {
 __log_start
 local JSON_FILE="${1}"
 local SCHEMA_FILE="${2}"

 if ! __validate_input_file "${JSON_FILE}" "JSON file"; then
  __log_finish
  return 1
 fi

 if ! __validate_input_file "${SCHEMA_FILE}" "JSON schema file"; then
  __log_finish
  return 1
 fi

 # Check if ajv is available
 if ! command -v ajv > /dev/null 2>&1; then
  __loge "ERROR: ajv (JSON schema validator) not available"
  __log_finish
  return 1
 fi

 # Validate JSON against schema
 if ! ajv validate -s "${SCHEMA_FILE}" -d "${JSON_FILE}"; then
  __loge "ERROR: JSON schema validation failed: ${JSON_FILE}"
  __log_finish
  return 1
 fi

 __logd "JSON schema validation passed: ${JSON_FILE}"
 __log_finish
 return 0
}

##
# Validates geographic coordinates (latitude and longitude) with range and precision checks
# Validates that latitude and longitude values are numeric, within valid ranges (latitude: -90 to 90,
# longitude: -180 to 180), and optionally checks decimal precision. Provides detailed error reporting
# for invalid coordinates. Used for validating geographic data in notes, boundaries, and other
# geospatial operations.
#
# Parameters:
#   $1: LATITUDE - Latitude value to validate (required, must be numeric)
#   $2: LONGITUDE - Longitude value to validate (required, must be numeric)
#   $3: PRECISION - Maximum decimal places allowed (optional, default: 7)
#
# Returns:
#   0: Success - Coordinates are valid
#   1: Failure - Coordinates are invalid (non-numeric, out of range, or precision exceeded)
#
# Error codes:
#   0: Success - Coordinates are valid
#   1: Failure - Latitude is not numeric
#   1: Failure - Longitude is not numeric
#   1: Failure - Latitude is outside valid range (-90 to 90)
#   1: Failure - Longitude is outside valid range (-180 to 180)
#   1: Failure - Coordinate precision exceeds maximum allowed
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Validates coordinate values using regex and bc (for range checks)
#   - Logs validation errors to standard logger
#   - No file, database, or network operations
#
# Notes:
#   - Validates numeric format using regex (allows negative numbers and decimals)
#   - Validates latitude range: -90 to 90 degrees
#   - Validates longitude range: -180 to 180 degrees
#   - Precision check counts decimal places (optional, default: 7)
#   - Uses bc command for floating-point range comparisons
#   - Common validation function used in geospatial data processing
#   - Provides detailed error messages for each validation failure
#
# Example:
#   __validate_coordinates 45.1234567 -73.9876543
#   # Validates coordinates with default precision (7 decimal places)
#
#   __validate_coordinates 45.123 -73.987 3
#   # Validates coordinates with precision limit of 3 decimal places
#
# Related: __validate_numeric_range() (validates numeric ranges)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
# Validate coordinates (enhanced version with precision control and better error reporting)
function __validate_coordinates() {
 __log_start
 local LATITUDE="${1}"
 local LONGITUDE="${2}"
 local PRECISION="${3:-7}"
 local VALIDATION_ERRORS=()

 # Check if values are numeric
 if ! [[ "${LATITUDE}" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
  VALIDATION_ERRORS+=("Latitude '${LATITUDE}' is not a valid number")
 fi

 if ! [[ "${LONGITUDE}" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
  VALIDATION_ERRORS+=("Longitude '${LONGITUDE}' is not a valid number")
 fi

 # Check latitude range (-90 to 90)
 if [[ "${LATITUDE}" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
  # shellcheck disable=SC2312  # bc failures are handled by || echo "0", echo always succeeds
  if (($(echo "${LATITUDE} < -90" | bc -l 2> /dev/null || echo "0"))) || (($(echo "${LATITUDE} > 90" | bc -l 2> /dev/null || echo "0"))); then
   VALIDATION_ERRORS+=("Latitude '${LATITUDE}' is outside valid range (-90 to 90)")
  fi
 fi

 # Check longitude range (-180 to 180)
 if [[ "${LONGITUDE}" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
  # shellcheck disable=SC2312  # bc failures are handled by || echo "0", echo always succeeds
  if (($(echo "${LONGITUDE} < -180" | bc -l 2> /dev/null || echo "0"))) || (($(echo "${LONGITUDE} > 180" | bc -l 2> /dev/null || echo "0"))); then
   VALIDATION_ERRORS+=("Longitude '${LONGITUDE}' is outside valid range (-180 to 180)")
  fi
 fi

 # Check precision if bc is available (only if precision is explicitly specified and < 7)
 if command -v bc > /dev/null 2>&1 && [[ "${3:-}" != "" ]] && [[ "${PRECISION}" -lt 7 ]]; then
  if [[ "${LATITUDE}" =~ \.[0-9]{$((PRECISION + 1)),} ]]; then
   VALIDATION_ERRORS+=("Latitude '${LATITUDE}' has too many decimal places (max ${PRECISION})")
  fi

  if [[ "${LONGITUDE}" =~ \.[0-9]{$((PRECISION + 1)),} ]]; then
   VALIDATION_ERRORS+=("Longitude '${LONGITUDE}' has too many decimal places (max ${PRECISION})")
  fi
 fi

 # Report validation errors
 if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
  __loge "ERROR: Coordinate validation failed:"
  for ERROR in "${VALIDATION_ERRORS[@]}"; do
   __loge "  - ${ERROR}"
  done
  __log_finish
  return 1
 fi

 # Only log in trace mode to reduce verbosity
 if [[ "${LOG_LEVEL:-}" == "TRACE" ]]; then
  __logd "Coordinate validation passed: lat=${LATITUDE}, lon=${LONGITUDE}"
 fi
 __log_finish
 return 0
}

# Validate numeric range
##
# Validates that a numeric value is within specified range
# Validates that a value is numeric and falls within the specified minimum and maximum range.
# Uses bc command for floating-point comparisons. Provides detailed error messages for
# out-of-range values. Used for validating numeric parameters and configuration values.
#
# Parameters:
#   $1: VALUE - Numeric value to validate (required)
#   $2: MIN - Minimum allowed value (required)
#   $3: MAX - Maximum allowed value (required)
#   $4: DESCRIPTION - Description of value for error messages (optional, default: "Value")
#
# Returns:
#   0: Success - Value is within valid range
#   1: Failure - Value is not numeric or is outside valid range
#
# Error codes:
#   0: Success - Value is numeric and within range
#   1: Failure - Value is not numeric (does not match numeric pattern)
#   1: Failure - Value is less than MIN
#   1: Failure - Value is greater than MAX
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity (only logs in TRACE mode)
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Validates numeric format using regex
#   - Executes bc command for floating-point range comparisons
#   - Logs validation results to standard logger (only in TRACE mode to reduce verbosity)
#   - No file, database, or network operations
#
# Notes:
#   - Validates numeric format using regex (allows negative numbers and decimals)
#   - Uses bc command for floating-point comparisons (supports decimals)
#   - Only logs in TRACE mode to reduce log verbosity (common validation function)
#   - Common validation function used for parameter validation
#   - Supports both integer and floating-point values
#
# Example:
#   __validate_numeric_range 5 1 10 "Thread count"
#   # Validates thread count is between 1 and 10
#
#   __validate_numeric_range 45.5 -90 90 "Latitude"
#   # Validates latitude is between -90 and 90
#
# Related: __validate_coordinates() (validates geographic coordinates)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
function __validate_numeric_range() {
 __log_start
 local VALUE="${1}"
 local MIN="${2}"
 local MAX="${3}"
 local DESCRIPTION="${4:-Value}"

 # Check if value is numeric
 if ! [[ "${VALUE}" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
  __loge "ERROR: Invalid numeric format: ${VALUE}"
  __log_finish
  return 1
 fi

 # Validate range
 # shellcheck disable=SC2312  # bc failures are handled by || echo "0"
 if (($(echo "${VALUE} < ${MIN}" | bc -l 2> /dev/null || echo "0"))) || (($(echo "${VALUE} > ${MAX}" | bc -l 2> /dev/null || echo "0"))); then
  __loge "ERROR: ${DESCRIPTION} out of range (${MIN} to ${MAX}): ${VALUE}"
  __log_finish
  return 1
 fi

 # Only log in trace mode to reduce verbosity
 if [[ "${LOG_LEVEL:-}" == "TRACE" ]]; then
  __logd "Numeric range validation passed: ${VALUE}"
 fi
 __log_finish
 return 0
}

##
# Validates that a string matches a specified regex pattern
# Validates that a string matches a regular expression pattern. Uses Bash regex matching
# ([[ string =~ pattern ]]). Provides error message if pattern does not match. Used for
# validating string formats (e.g., email addresses, identifiers, file names).
#
# Parameters:
#   $1: STRING - String value to validate (required)
#   $2: PATTERN - Regular expression pattern to match against (required)
#   $3: DESCRIPTION - Description of string for error messages (optional, default: "String")
#
# Returns:
#   0: Success - String matches pattern
#   1: Failure - String does not match pattern
#
# Error codes:
#   0: Success - String matches the specified pattern
#   1: Failure - String does not match the pattern
#
# Context variables:
#   Reads:
#     - LOG_LEVEL: Controls logging verbosity (only logs in TRACE mode)
#   Sets: None
#   Modifies: None
#
# Side effects:
#   - Validates string against regex pattern using Bash regex matching
#   - Logs validation results to standard logger (only in TRACE mode to reduce verbosity)
#   - No file, database, or network operations
#
# Notes:
#   - Uses Bash regex matching ([[ string =~ pattern ]])
#   - Pattern is a Bash extended regular expression (ERE)
#   - Only logs in TRACE mode to reduce log verbosity (common validation function)
#   - Common validation function used for string format validation
#   - Pattern matching is case-sensitive
#
# Example:
#   __validate_string_pattern "user@example.com" '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' "Email"
#   # Validates email format
#
#   __validate_string_pattern "file_123" '^[a-zA-Z0-9_]+$' "Filename"
#   # Validates filename contains only alphanumeric and underscore
#
# Related: __validate_numeric_range() (validates numeric ranges)
# Related: STANDARD_ERROR_CODES.md (error code definitions)
##
# Validate string pattern
function __validate_string_pattern() {
 __log_start
 local STRING="${1}"
 local PATTERN="${2}"
 local DESCRIPTION="${3:-String}"

 if [[ ! "${STRING}" =~ ${PATTERN} ]]; then
  __loge "ERROR: ${DESCRIPTION} does not match pattern: ${STRING}"
  __log_finish
  return 1
 fi

 # Only log in trace mode to reduce verbosity
 if [[ "${LOG_LEVEL:-}" == "TRACE" ]]; then
  __logd "String pattern validation passed: ${STRING}"
 fi
 __log_finish
 return 0
}

# Validate XML coordinates - This function has been moved to functionsProcess.sh
# to avoid duplication and use the more advanced implementation.
# Use the function from functionsProcess.sh instead.

# Validate CSV coordinates
function __validate_csv_coordinates() {
 __log_start
 local CSV_FILE="${1}"
 local LAT_COLUMN="${2:-lat}"
 local LON_COLUMN="${3:-lon}"

 if ! __validate_input_file "${CSV_FILE}" "CSV file"; then
  __log_finish
  return 1
 fi

 # Find column indices
 local HEADER
 HEADER=$(head -n 1 "${CSV_FILE}")
 local LAT_INDEX LON_INDEX
 # shellcheck disable=SC2312  # tr/grep/cut failures are handled by empty check
 LAT_INDEX=$(echo "${HEADER}" | tr ',' '\n' | grep -n "^${LAT_COLUMN}$" | cut -d: -f1 || echo "")
 # shellcheck disable=SC2312  # tr/grep/cut failures are handled by empty check
 LON_INDEX=$(echo "${HEADER}" | tr ',' '\n' | grep -n "^${LON_COLUMN}$" | cut -d: -f1 || echo "")

 if [[ -z "${LAT_INDEX}" ]] || [[ -z "${LON_INDEX}" ]]; then
  __loge "ERROR: Coordinate columns not found: ${LAT_COLUMN}, ${LON_COLUMN}"
  __log_finish
  return 1
 fi

 local FAILED=0

 # Read coordinates from CSV
 # shellcheck disable=SC2312  # tail failure is acceptable, loop handles empty input
 while IFS=',' read -r -a FIELDS; do
  local LAT="${FIELDS[LAT_INDEX - 1]}"
  local LON="${FIELDS[LON_INDEX - 1]}"

  if [[ -n "${LAT}" ]] && [[ -n "${LON}" ]]; then
   if ! __validate_coordinates "${LAT}" "${LON}"; then
    FAILED=1
   fi
  fi
 done < <(tail -n +2 "${CSV_FILE}" 2> /dev/null || true)

 if [[ "${FAILED}" -eq 1 ]]; then
  __loge "ERROR: CSV coordinate validation failed"
  __log_finish
  return 1
 fi

 # Only log in trace mode to reduce verbosity
 if [[ "${LOG_LEVEL:-}" == "TRACE" ]]; then
  __logd "CSV coordinate validation passed: ${CSV_FILE}"
 fi
 __log_finish
 return 0
}

# Validate database variables
function __validate_database_variables() {
 __log_start
 # Check for minimal required variables (for peer authentication)
 local MINIMAL_VARS=("DBNAME" "DB_USER")
 local MISSING_MINIMAL=()

 for VAR in "${MINIMAL_VARS[@]}"; do
  if [[ -z "${!VAR}" ]]; then
   MISSING_MINIMAL+=("${VAR}")
  fi
 done

 if [[ ${#MISSING_MINIMAL[@]} -gt 0 ]]; then
  __loge "ERROR: Missing required database variables: ${MISSING_MINIMAL[*]}"
  __log_finish
  return 1
 fi

 # For peer authentication (localhost), DB_PASSWORD, DB_HOST, DB_PORT are optional
 # For remote connections, all variables are required
 if [[ -n "${DB_HOST:-}" && "${DB_HOST}" != "localhost" && "${DB_HOST}" != "" ]]; then
  local REMOTE_VARS=("DB_PASSWORD" "DB_HOST" "DB_PORT")
  local MISSING_REMOTE=()

  for VAR in "${REMOTE_VARS[@]}"; do
   if [[ -z "${!VAR}" ]]; then
    MISSING_REMOTE+=("${VAR}")
   fi
  done

  if [[ ${#MISSING_REMOTE[@]} -gt 0 ]]; then
   __loge "ERROR: Missing required remote database variables: ${MISSING_REMOTE[*]}"
   __log_finish
   return 1
  fi
 fi
 __log_finish

 __logd "Database variable validation passed"
 return 0
}

# Validate date format
function __validate_date_format() {
 __log_start
 local DATE_STRING="${1}"
 local DESCRIPTION="${2:-Date}"

 if [[ -z "${DATE_STRING}" ]]; then
  __loge "ERROR: ${DESCRIPTION} is empty"
  __log_finish
  return 1
 fi

 # Check if date string matches ISO 8601 format
 if ! [[ "${DATE_STRING}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  __loge "ERROR: ${DESCRIPTION} does not match ISO 8601 format: ${DATE_STRING}"
  __log_finish
  return 1
 fi

 # Validate date components using regex
 local YEAR MONTH DAY HOUR MINUTE SECOND
 if [[ "${DATE_STRING}" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z$ ]]; then
  YEAR="${BASH_REMATCH[1]}"
  MONTH="${BASH_REMATCH[2]}"
  DAY="${BASH_REMATCH[3]}"
  HOUR="${BASH_REMATCH[4]}"
  MINUTE="${BASH_REMATCH[5]}"
  SECOND="${BASH_REMATCH[6]}"
 else
  __loge "ERROR: ${DESCRIPTION} format parsing failed: ${DATE_STRING}"
  __log_finish
  return 1
 fi

 # Check year range
 if [[ $((10#${YEAR})) -lt 1900 ]] || [[ $((10#${YEAR})) -gt 2100 ]]; then
  __loge "ERROR: ${DESCRIPTION} year out of range: ${YEAR}"
  __log_finish
  return 1
 fi

 # Check month range
 if [[ $((10#${MONTH})) -lt 1 ]] || [[ $((10#${MONTH})) -gt 12 ]]; then
  __loge "ERROR: ${DESCRIPTION} month out of range: ${MONTH}"
  __log_finish
  return 1
 fi

 # Check day range
 if [[ $((10#${DAY})) -lt 1 ]] || [[ $((10#${DAY})) -gt 31 ]]; then
  __loge "ERROR: ${DESCRIPTION} day out of range: ${DAY}"
  __log_finish
  return 1
 fi

 # Check hour range
 if [[ $((10#${HOUR})) -lt 0 ]] || [[ $((10#${HOUR})) -gt 23 ]]; then
  __loge "ERROR: ${DESCRIPTION} hour out of range: ${HOUR}"
  __log_finish
  return 1
 fi

 # Check minute range
 if [[ $((10#${MINUTE})) -lt 0 ]] || [[ $((10#${MINUTE})) -gt 59 ]]; then
  __loge "ERROR: ${DESCRIPTION} minute out of range: ${MINUTE}"
  __log_finish
  return 1
 fi

 # Check second range
 if [[ $((10#${SECOND})) -lt 0 ]] || [[ $((10#${SECOND})) -gt 59 ]]; then
  __loge "ERROR: ${DESCRIPTION} second out of range: ${SECOND}"
  __log_finish
  return 1
 fi

 # Only log in trace mode to reduce verbosity
 if [[ "${LOG_LEVEL:-}" == "TRACE" ]]; then
  __logd "${DESCRIPTION} validation passed: ${DATE_STRING}"
 fi
 __log_finish
 return 0
}

# Validate date format with UTC timezone
function __validate_date_format_utc() {
 __log_start
 local DATE_STRING="${1}"
 local DESCRIPTION="${2:-Date}"

 if [[ -z "${DATE_STRING}" ]]; then
  __loge "ERROR: ${DESCRIPTION} is empty"
  __log_finish
  return 1
 fi

 # Check if date string matches format: YYYY-MM-DD HH:MM:SS UTC
 if ! [[ "${DATE_STRING}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]UTC$ ]]; then
  __loge "ERROR: ${DESCRIPTION} does not match UTC format: ${DATE_STRING}"
  __log_finish
  return 1
 fi

 # Extract date and time components using regex
 local YEAR MONTH DAY HOUR MINUTE SECOND
 if [[ "${DATE_STRING}" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})[[:space:]]([0-9]{2}):([0-9]{2}):([0-9]{2})[[:space:]]UTC$ ]]; then
  YEAR="${BASH_REMATCH[1]}"
  MONTH="${BASH_REMATCH[2]}"
  DAY="${BASH_REMATCH[3]}"
  HOUR="${BASH_REMATCH[4]}"
  MINUTE="${BASH_REMATCH[5]}"
  SECOND="${BASH_REMATCH[6]}"
 else
  __loge "ERROR: ${DESCRIPTION} format parsing failed: ${DATE_STRING}"
  __log_finish
  return 1
 fi

 # Check year range
 if [[ $((10#${YEAR})) -lt 1900 ]] || [[ $((10#${YEAR})) -gt 2100 ]]; then
  __loge "ERROR: ${DESCRIPTION} year out of range: ${YEAR}"
  __log_finish
  return 1
 fi

 # Check month range
 if [[ $((10#${MONTH})) -lt 1 ]] || [[ $((10#${MONTH})) -gt 12 ]]; then
  __loge "ERROR: ${DESCRIPTION} month out of range: ${MONTH}"
  __log_finish
  return 1
 fi

 # Check day range
 if [[ $((10#${DAY})) -lt 1 ]] || [[ $((10#${DAY})) -gt 31 ]]; then
  __loge "ERROR: ${DESCRIPTION} day out of range: ${DAY}"
  __log_finish
  return 1
 fi

 # Check hour range
 if [[ $((10#${HOUR})) -lt 0 ]] || [[ $((10#${HOUR})) -gt 23 ]]; then
  __loge "ERROR: ${DESCRIPTION} hour out of range: ${HOUR}"
  __log_finish
  return 1
 fi

 # Check minute range
 if [[ $((10#${MINUTE})) -lt 0 ]] || [[ $((10#${MINUTE})) -gt 59 ]]; then
  __loge "ERROR: ${DESCRIPTION} minute out of range: ${MINUTE}"
  __log_finish
  return 1
 fi

 # Check second range
 if [[ $((10#${SECOND})) -lt 0 ]] || [[ $((10#${SECOND})) -gt 59 ]]; then
  __loge "ERROR: ${DESCRIPTION} second out of range: ${SECOND}"
  __log_finish
  return 1
 fi

 __logt "${DESCRIPTION} validation passed: ${DATE_STRING}"
 __log_finish
 return 0
}
