# Contributing to OSM-Notes-Common

Thank you for your interest in contributing to the OSM-Notes-Common project! This document
provides comprehensive guidelines for contributing to this OpenStreetMap notes analysis system.

## Table of Contents

- [Code Standards](#code-standards)
- [Development Workflow](#development-workflow)
- [Testing Requirements](#testing-requirements)
- [File Organization](#file-organization)
- [Naming Conventions](#naming-conventions)
- [Documentation](#documentation)
- [Quality Assurance](#quality-assurance)
- [Pull Request Process](#pull-request-process)

## Code Standards

### Bash Script Standards

All bash scripts must follow these standards:

#### Required Header Structure

```bash
#!/bin/bash

# Brief description of the script functionality
#
# This script [describe what it does]
# * [key feature 1]
# * [key feature 2]
# * [key feature 3]
#
# These are some examples to call this script:
# * [example 1]
# * [example 2]
#
# This is the list of error codes:
# [list all error codes with descriptions]
#
# For contributing, please execute these commands before submitting:
# * shellcheck -x -o all [SCRIPT_NAME].sh
# * shfmt -w -i 1 -sr -bn [SCRIPT_NAME].sh
#
# Author: Andres Gomez (AngocA)
# Version: [YYYY-MM-DD]
VERSION="[YYYY-MM-DD]"
```

#### Required Script Settings

```bash
#set -xv
# Fails when a variable is not initialized.
set -u
# Fails with a non-zero return code.
set -e
# Fails if the commands of a pipe return non-zero.
set -o pipefail
# Fails if an internal function fails.
set -E
```

#### Variable Declaration Standards

- **Global variables**: Use `declare -r` for readonly variables
- **Local variables**: Use `local` declaration
- **Integer variables**: Use `declare -i`
- **Arrays**: Use `declare -a`
- **All variables must be braced**: `${VAR}` instead of `$VAR`

#### Function Naming Convention

- **All functions must start with double underscore**: `__function_name`
- **Use descriptive names**: `__download_planet_notes`, `__validate_xml_file`
- **Include function documentation**:

```bash
# Downloads the planet notes file from OSM servers.
# Parameters: None
# Returns: 0 on success, non-zero on failure
function __download_planet_notes {
  # Function implementation
}
```

#### Error Handling

- **Define error codes at the top**:

```bash
# Error codes.
# 1: Help message.
declare -r ERROR_HELP_MESSAGE=1
# 241: Library or utility missing.
declare -r ERROR_MISSING_LIBRARY=241
# 242: Invalid argument for script invocation.
declare -r ERROR_INVALID_ARGUMENT=242
```

### SQL Standards

#### File Naming Convention

- **Process files**: `processAPINotes_21_createApiTables.sql`
> **Note:** ETL files are maintained in [OSM-Notes-Analytics](https://github.com/OSM-Notes/OSM-Notes-Analytics).
- **Function files**: `functionsProcess_21_createFunctionToGetCountry.sql`
- **Drop files**: `processAPINotes_12_dropApiTables.sql`

#### SQL Code Standards

- **Keywords in UPPERCASE**: `SELECT`, `INSERT`, `UPDATE`, `DELETE`
- **Identifiers in lowercase**: `table_name`, `column_name`
- **Use proper indentation**: 2 spaces
- **Include comments for complex queries**
- **Use parameterized queries when possible**

## Development Workflow

### 1. Environment Setup

Before contributing, ensure you have the required tools:

```bash
# Install development tools
sudo apt-get install shellcheck shfmt bats

# Install database tools
sudo apt-get install postgresql postgis

# Install XML processing tools
sudo apt-get install libxml2-utils

# Install geographic tools
sudo apt-get install gdal-bin ogr2ogr
```

### 2. Project Structure Understanding

Familiarize yourself with the osm-common submodule structure:

- **`*.sh`**: Bash function libraries (commonFunctions, validationFunctions, bash_logger, etc.)
- **`schemas/`**: JSON schema definitions for data validation
- **`README.md`**: Overview and usage guide

### 3. Development Process

1. **Create a feature branch**:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Follow the established patterns**:
   - Use existing function names and patterns
   - Follow the error code numbering system
   - Maintain the logging structure
   - Use the established variable naming

3. **Test your changes**:

   Tests for osm-common functions are located in the repositories that use this submodule
   (OSM-Notes-Ingestion and OSM-Notes-Analytics). Ensure tests pass in those repositories
   before submitting changes.

## Testing Requirements

### Overview

All contributions must include comprehensive testing. Since this is a shared library,
tests should be added to the repositories that use this submodule (OSM-Notes-Ingestion
or OSM-Notes-Analytics).

### Test Categories

#### Unit Tests

- **Bash Functions**: Test individual functions from the library
- **Validation Functions**: Test validation logic
- **Error Handling**: Test error handling and recovery

#### Integration Tests

- **Function Integration**: Test how functions work together
- **Cross-Repository**: Test compatibility with dependent projects

#### Quality Tests

- **Code Quality**: Linting, formatting, conventions
- **Security**: Vulnerability scanning, best practices

### Running Tests

Tests for osm-common functions are located in the repositories that use this submodule.
See the testing documentation in those repositories for details on running tests.

### Test Documentation

All new tests must be documented appropriately in the repositories that use this submodule.

### CI/CD Integration

Tests are automatically run in GitHub Actions in the repositories that use this submodule.

### Test Quality Standards

#### Code Coverage

- **Minimum 85%** code coverage for new features
- **100% coverage** for critical functions
- **Integration testing** for all workflows

#### Test Quality

- **Descriptive test names** that explain the scenario
- **Comprehensive assertions** that validate all aspects
- **Error case testing** for edge cases and failures
- **Performance testing** for time-sensitive operations

#### Documentation

- **Test descriptions** that explain the purpose
- **Setup instructions** for test environment
- **Expected results** clearly documented
- **Troubleshooting guides** for common issues

## File Organization

### Directory Structure Standards

```text
lib/osm-common/
├── commonFunctions.sh              # Common utility functions
├── validationFunctions.sh          # Validation functions
├── consolidatedValidationFunctions.sh # Consolidated validation
├── errorHandlingFunctions.sh        # Error handling functions
├── bash_logger.sh                  # Logging library
├── alertFunctions.sh               # Alert functions
├── schemas/                        # JSON schemas
│   ├── country-index.schema.json
│   ├── country-profile.schema.json
│   ├── user-index.schema.json
│   └── user-profile.schema.json
├── docs/                           # Documentation
└── README.md                       # This file
```

### File Naming Conventions

#### Script Files

- **Main scripts**: `processAPINotes.sh`, `processPlanetNotes.sh`
- **Utility scripts**: `updateCountries.sh`, `cleanupAll.sh`
- **Test scripts**: `test_[component].sh`

#### SQL Files

- **Creation scripts**: `[component]_21_create[Object].sql`
- **Drop scripts**: `[component]_11_drop[Object].sql`
- **Data scripts**: `[component]_31_load[Data].sql`

#### Test Files

- **Unit tests**: `[component].test.bats`
- **Integration tests**: `[feature]_integration.test.bats`
- **SQL tests**: `[component].test.sql`

## Naming Conventions

### Variables

- **Global variables**: `UPPERCASE_WITH_UNDERSCORES`
- **Local variables**: `lowercase_with_underscores`
- **Constants**: `UPPERCASE_WITH_UNDERSCORES`
- **Environment variables**: `UPPERCASE_WITH_UNDERSCORES`

### Functions

- **All functions**: `__function_name_with_underscores`
- **Private functions**: `__private_function_name`
- **Public functions**: `__public_function_name`

### Database Objects

- **Tables**: `lowercase_with_underscores`
- **Columns**: `lowercase_with_underscores`
- **Functions**: `function_name_with_underscores`
- **Procedures**: `procedure_name_with_underscores`

## Consolidated Functions

### Function Consolidation Strategy

The project uses a consolidation strategy to eliminate code duplication and improve maintainability:

#### 1. Parallel Processing Functions (`bin/parallelProcessingFunctions.sh`)

- **Purpose**: Centralizes all XML parallel processing functions
- **Functions**: `__processXmlPartsParallel`, `__splitXmlForParallelSafe`, `__processApiXmlPart`,
  `__processPlanetXmlPart`
- **Usage**: All scripts that need parallel processing should source this file
- **Fallback**: Legacy scripts maintain compatibility through wrapper functions

#### 2. Validation Functions (`bin/consolidatedValidationFunctions.sh`)

- **Purpose**: Centralizes all validation functions for XML, CSV, coordinates, and databases
- **Functions**: `__validate_xml_with_enhanced_error_handling`, `__validate_csv_structure`,
  `__validate_coordinates`
- **Usage**: All validation operations should use these consolidated functions
- **Fallback**: Legacy scripts maintain compatibility through wrapper functions

#### 3. Implementation Guidelines

- **New Functions**: Add to appropriate consolidated file rather than duplicating across scripts
- **Legacy Support**: Always provide fallback mechanisms for backward compatibility
- **Testing**: Include tests for both consolidated functions and legacy compatibility

## Documentation

### Required Documentation

1. **Script Headers**: Every script must have a comprehensive header
2. **Function Documentation**: All functions must be documented
3. **README Files**: Each directory should have a README.md
4. **API Documentation**: Document any new APIs or interfaces
5. **Configuration Documentation**: Document configuration options
6. **Consolidated Functions**: Document any new consolidated function files

### Documentation Standards

#### Script Documentation

```bash
# Brief description of what the script does
#
# Detailed explanation of functionality
# * Key feature 1
# * Key feature 2
# * Key feature 3
#
# Usage examples:
# * Example 1
# * Example 2
#
# Error codes:
# 1: Help message
# 241: Library missing
# 242: Invalid argument
#
# Author: [Your Name]
# Version: [YYYY-MM-DD]
```

#### Function Documentation

```bash
# Brief description of what the function does
# Parameters: [list of parameters]
# Returns: [return value description]
# Side effects: [any side effects]
function __function_name {
  # Implementation
}
```

## Quality Assurance

### Pre-Submission Checklist

Before submitting your contribution, ensure:

- [ ] **Code formatting**: Run `shfmt -w -i 1 -sr -bn` on all bash scripts
- [ ] **Linting**: Run `shellcheck -x -o all` on all bash scripts
- [ ] **Tests**: All tests pass in dependent repositories
- [ ] **Documentation**: All new code is documented
- [ ] **Error handling**: Proper error codes and handling
- [ ] **Logging**: Appropriate logging levels and messages
- [ ] **Performance**: No performance regressions
- [ ] **Security**: No security vulnerabilities

### Code Quality Tools

#### Required Tools

```bash
# Format bash scripts
shfmt -w -i 1 -sr -bn script.sh

# Lint bash scripts
shellcheck -x -o all script.sh
```

#### Quality Standards

- **ShellCheck**: No warnings or errors
- **shfmt**: Consistent formatting
- **Test Coverage**: Minimum 80% coverage
- **Performance**: No significant performance degradation
- **Security**: No security vulnerabilities

## Pull Request Process

### 1. Preparation

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature`
3. **Make your changes following the standards above**
4. **Test thoroughly**: Run all test suites
5. **Update documentation**: Add/update relevant documentation

### 2. Submission

1. **Commit your changes**:

   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

2. **Push to your fork**:

   ```bash
   git push origin feature/your-feature
   ```

3. **Create a Pull Request** with:
   - **Clear title**: Describe the feature/fix
   - **Detailed description**: Explain what and why
   - **Test results**: Include test output
   - **Screenshots**: If applicable

### 3. Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Test verification** by maintainers
4. **Documentation review** for completeness
5. **Final approval** and merge

### 4. Commit Message Standards

Use conventional commit messages:

```text
type(scope): description

[optional body]

[optional footer]
```

**Types**:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

**Examples**:

```text
feat(process): add parallel processing for large datasets
fix(sql): correct country boundary import for Austria
docs(readme): update installation instructions
test(api): add integration tests for new endpoints
```

## Getting Help

### Resources

- **Project README**: Main project documentation
- **Directory READMEs**: Specific component documentation
- **Test Examples**: See existing tests for patterns
- **Code Examples**: Study existing scripts for patterns

### Contact

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Pull Requests**: For code contributions

### Development Environment

For local development, consider using Docker:

```bash
# Run tests in Docker
./tests/docker/run_integration_tests.sh

# Debug in Docker
./tests/docker/debug_postgres.sh
```

### Local Configuration

Configuration files are managed in the repositories that use this submodule, not in the
submodule itself.

## Version Control

### Branch Strategy

- **main**: Production-ready code
- **develop**: Integration branch
- **feature/\***: New features
- **bugfix/\***: Bug fixes
- **hotfix/\***: Critical fixes

### Release Process

1. **Feature complete**: All features implemented and tested
2. **Documentation complete**: All documentation updated
3. **Tests passing**: All test suites pass
4. **Code review**: All changes reviewed
5. **Release**: Tag and release

---

**Thank you for contributing to OSM-Notes-Common!**

Your contributions help make OpenStreetMap notes analysis more accessible and powerful for the
community.
