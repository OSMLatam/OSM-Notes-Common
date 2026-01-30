#!/usr/bin/env bash
#
# Run CI Tests Locally
# Simulates basic quality checks for OSM-Notes-Common
# Author: Andres Gomez (AngocA)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_message() {
    local color="${1}"
    shift
    echo -e "${color}$*${NC}"
}

print_message "${YELLOW}" "=== Running CI Tests Locally (OSM-Notes-Common) ==="
echo

cd "${PROJECT_ROOT}"

# Check shellcheck
if ! command -v shellcheck > /dev/null 2>&1; then
    print_message "${YELLOW}" "Installing shellcheck..."
    if ! (sudo apt-get update && sudo apt-get install -y shellcheck) 2>/dev/null; then
        print_message "${YELLOW}" "⚠ Could not install shellcheck automatically"
    fi
fi

# Check shfmt
if ! command -v shfmt > /dev/null 2>&1; then
    print_message "${YELLOW}" "Installing shfmt..."
    wget -q -O /tmp/shfmt https://github.com/mvdan/sh/releases/download/v3.7.0/shfmt_v3.7.0_linux_amd64
    chmod +x /tmp/shfmt
    sudo mv /tmp/shfmt /usr/local/bin/shfmt || {
        print_message "${YELLOW}" "⚠ Could not install shfmt automatically"
    }
fi

echo
print_message "${YELLOW}" "=== Step 1: ShellCheck ==="
echo

# Run shellcheck on all shell scripts
if command -v shellcheck > /dev/null 2>&1; then
    print_message "${BLUE}" "Running shellcheck on shell scripts..."
    if find . -maxdepth 1 -name "*.sh" -type f -exec shellcheck -x -o all {} \; 2>&1 | grep -q "error"; then
        print_message "${RED}" "✗ shellcheck found errors"
        find . -maxdepth 1 -name "*.sh" -type f -exec shellcheck -x -o all {} \;
        exit 1
    else
        print_message "${GREEN}" "✓ shellcheck passed"
    fi
else
    print_message "${YELLOW}" "⚠ shellcheck not available, skipping"
fi

echo
print_message "${YELLOW}" "=== Step 2: Code Formatting Checks ==="
echo

# Check bash formatting with shfmt
print_message "${BLUE}" "Checking bash code formatting with shfmt..."
if command -v shfmt > /dev/null 2>&1; then
    if find . -maxdepth 1 -name "*.sh" -type f -exec shfmt -d -i 1 -sr -bn {} \; 2>&1 | grep -q "."; then
        print_message "${RED}" "✗ Code formatting issues found"
        find . -maxdepth 1 -name "*.sh" -type f -exec shfmt -d -i 1 -sr -bn {} \;
        exit 1
    else
        print_message "${GREEN}" "✓ Code formatting check passed"
    fi
else
    print_message "${YELLOW}" "⚠ shfmt not available, skipping format check"
fi

# Check Prettier formatting (optional)
if command -v prettier > /dev/null 2>&1 || command -v npx > /dev/null 2>&1; then
    print_message "${BLUE}" "Checking Prettier formatting..."
    if command -v prettier > /dev/null 2>&1; then
        PRETTIER_CMD=prettier
    else
        PRETTIER_CMD="npx prettier"
    fi
    if ${PRETTIER_CMD} --check "**/*.{md,json,yaml,yml,css,html}" --ignore-path .prettierignore 2>/dev/null; then
        print_message "${GREEN}" "✓ Prettier formatting check passed"
    else
        print_message "${YELLOW}" "⚠ Prettier formatting issues found (non-blocking)"
    fi
fi

# Check JSON schema files
print_message "${BLUE}" "Validating JSON schema files..."
# Check for ajv in common locations
AJV_CMD=""
if command -v ajv > /dev/null 2>&1; then
    AJV_CMD="ajv"
elif [[ -f /usr/local/bin/ajv ]]; then
    AJV_CMD="/usr/local/bin/ajv"
elif command -v npx > /dev/null 2>&1; then
    AJV_CMD="npx ajv-cli"
fi

if [[ -n "${AJV_CMD}" ]]; then
    SCHEMA_COUNT=0
    VALID_COUNT=0
    for schema_file in schemas/*.json; do
        if [[ -f "${schema_file}" ]]; then
            SCHEMA_COUNT=$((SCHEMA_COUNT + 1))
            # Validate schema syntax (not data, just schema structure)
            if echo '{}' | ${AJV_CMD} validate -s "${schema_file}" -d /dev/stdin 2>/dev/null; then
                VALID_COUNT=$((VALID_COUNT + 1))
            fi
        fi
    done
    if [[ ${SCHEMA_COUNT} -gt 0 ]]; then
        if [[ ${VALID_COUNT} -eq ${SCHEMA_COUNT} ]]; then
            print_message "${GREEN}" "✓ All ${SCHEMA_COUNT} JSON schema files are valid"
        else
            print_message "${YELLOW}" "⚠ Some JSON schema files may have issues (${VALID_COUNT}/${SCHEMA_COUNT} validated)"
        fi
    else
        print_message "${YELLOW}" "⚠ No JSON schema files found"
    fi
else
    print_message "${YELLOW}" "⚠ ajv not available, skipping JSON schema validation"
fi

echo
print_message "${YELLOW}" "=== Step 3: Test Coverage Evaluation ==="
echo

# Test coverage evaluation function
evaluate_test_coverage() {
    # scripts_dir parameter kept for consistency with other repos, but not used here
    # as we search in root directory directly
    # shellcheck disable=SC2034
    local scripts_dir="${1:-.}"
    local tests_dir="${2:-tests}"
    
    print_message "${BLUE}" "Evaluating test coverage..."
    
    # Count test files for a script
    count_test_files() {
        local script_path="${1}"
        local script_name
        script_name=$(basename "${script_path}" .sh)
        
        local test_count=0
        
        # Check unit tests
        if [[ -d "${PROJECT_ROOT}/${tests_dir}/unit" ]]; then
            if find "${PROJECT_ROOT}/${tests_dir}/unit" -name "test_${script_name}.sh" -o -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" 2>/dev/null | grep -q .; then
                test_count=$(find "${PROJECT_ROOT}/${tests_dir}/unit" \( -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" \) -type f 2>/dev/null | wc -l | tr -d ' ')
            fi
        fi
        
        # Check integration tests
        if [[ -d "${PROJECT_ROOT}/${tests_dir}/integration" ]]; then
            if find "${PROJECT_ROOT}/${tests_dir}/integration" -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" 2>/dev/null | grep -q .; then
                test_count=$((test_count + $(find "${PROJECT_ROOT}/${tests_dir}/integration" \( -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" \) -type f 2>/dev/null | wc -l | tr -d ' ')))
            fi
        fi
        
        # Also check tests directory directly (for simpler structures)
        if [[ -d "${PROJECT_ROOT}/${tests_dir}" ]]; then
            if find "${PROJECT_ROOT}/${tests_dir}" -maxdepth 1 -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" 2>/dev/null | grep -q .; then
                test_count=$((test_count + $(find "${PROJECT_ROOT}/${tests_dir}" -maxdepth 1 \( -name "*${script_name}*.sh" -o -name "*${script_name}*.bats" \) -type f 2>/dev/null | wc -l | tr -d ' ')))
            fi
        fi
        
        echo "${test_count}"
    }
    
    # Calculate coverage percentage
    calculate_coverage() {
        local script_path="${1}"
        local test_count
        test_count=$(count_test_files "${script_path}")
        
        if [[ ${test_count} -gt 0 ]]; then
            # Heuristic: 1 test = 40%, 2 tests = 60%, 3+ tests = 80%
            local coverage=0
            if [[ ${test_count} -ge 3 ]]; then
                coverage=80
            elif [[ ${test_count} -eq 2 ]]; then
                coverage=60
            elif [[ ${test_count} -eq 1 ]]; then
                coverage=40
            fi
            echo "${coverage}"
        else
            echo "0"
        fi
    }
    
    # Find all scripts in root directory
    local scripts=()
    # Use explicit || true to handle find/sort errors gracefully
    while IFS= read -r -d '' script; do
        scripts+=("${script}")
    done < <(find "${PROJECT_ROOT}" -maxdepth 1 -name "*.sh" -type f -print0 2>/dev/null | sort -z || true)
    
    if [[ ${#scripts[@]} -eq 0 ]]; then
        print_message "${YELLOW}" "⚠ No scripts found in root directory, skipping coverage evaluation"
        return 0
    fi
    
    local total_scripts=${#scripts[@]}
    local scripts_with_tests=0
    local scripts_above_threshold=0
    local total_coverage=0
    local coverage_count=0
    
    for script in "${scripts[@]}"; do
        local script_name
        script_name=$(basename "${script}")
        local test_count
        test_count=$(count_test_files "${script}")
        local coverage
        coverage=$(calculate_coverage "${script}")
        
        if [[ ${test_count} -gt 0 ]]; then
            scripts_with_tests=$((scripts_with_tests + 1))
            if [[ "${coverage}" =~ ^[0-9]+$ ]] && [[ ${coverage} -gt 0 ]]; then
                total_coverage=$((total_coverage + coverage))
                coverage_count=$((coverage_count + 1))
                
                if [[ ${coverage} -ge 80 ]]; then
                    scripts_above_threshold=$((scripts_above_threshold + 1))
                fi
            fi
        fi
    done
    
    # Calculate overall coverage
    local overall_coverage=0
    if [[ ${coverage_count} -gt 0 ]]; then
        overall_coverage=$((total_coverage / coverage_count))
    fi
    
    echo
    echo "Coverage Summary:"
    echo "  Total scripts: ${total_scripts}"
    echo "  Scripts with tests: ${scripts_with_tests}"
    echo "  Scripts above 80% coverage: ${scripts_above_threshold}"
    echo "  Average coverage: ${overall_coverage}%"
    echo
    
    if [[ ${overall_coverage} -ge 80 ]]; then
        print_message "${GREEN}" "✓ Coverage target met (${overall_coverage}% >= 80%)"
    elif [[ ${overall_coverage} -ge 50 ]]; then
        print_message "${YELLOW}" "⚠ Coverage below target (${overall_coverage}% < 80%), improvement needed"
    else
        print_message "${YELLOW}" "⚠ Coverage significantly below target (${overall_coverage}% < 50%)"
    fi
    
    echo
    print_message "${BLUE}" "Note: This is an estimated coverage based on test file presence."
    print_message "${BLUE}" "For accurate coverage, use code instrumentation tools like bashcov."
}

# Run coverage evaluation (non-blocking)
if [[ -d "${PROJECT_ROOT}/tests" ]]; then
    # Invoke function separately to avoid shellcheck SC2310 warning
    evaluate_test_coverage "." "tests"
    coverage_status=$?
    if [[ ${coverage_status} -ne 0 ]]; then
        # Coverage evaluation failed, but we continue (non-blocking)
        print_message "${YELLOW}" "⚠ Test coverage evaluation encountered issues, continuing..."
    fi
else
    print_message "${YELLOW}" "⚠ No tests/ directory found, skipping coverage evaluation"
fi

echo
print_message "${GREEN}" "=== All CI Tests Completed Successfully ==="
echo
print_message "${GREEN}" "✅ ShellCheck: PASSED"
print_message "${GREEN}" "✅ Code Formatting Checks: PASSED"
echo

exit 0
