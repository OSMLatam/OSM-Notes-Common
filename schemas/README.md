# JSON Schema Validation

This directory contains JSON Schema definitions for validating data structure between the OSM-Notes-Analytics (producer) and OSM-Notes-Viewer (consumer) repositories.

## Purpose

These schemas define the contract for JSON data exchange, ensuring:
- **Producer** generates valid JSON files
- **Consumer** receives expected data structure
- **Type safety** across repository boundaries
- **Documentation** of data structure

## Files

- `metadata.schema.json` - Metadata export information
- `user-index.schema.json` - User index entries
- `user-profile.schema.json` - Complete user profile data
- `country-index.schema.json` - Country index entries
- `country-profile.schema.json` - Complete country profile data

## Usage

### Validate Using AJV CLI

```bash
# Install AJV CLI globally
npm install -g ajv-cli

# Validate a single file
ajv -s metadata.schema.json -d src/data/metadata.json

# Validate all user profiles
ajv -s user-profile.schema.json -d src/data/users/*.json

# Validate all country profiles
ajv -s country-profile.schema.json -d src/data/countries/*.json
```

### Validate Using Node.js

```javascript
import Ajv from 'ajv';
import addFormats from 'ajv-formats';

const ajv = new Ajv({ allErrors: true });
addFormats(ajv);

// Load schema
const schema = JSON.parse(fs.readFileSync('schemas/user-profile.schema.json'));

// Validate data
const validate = ajv.compile(schema);
const valid = validate(userData);

if (!valid) {
  console.error('Validation errors:', validate.errors);
}
```

### Add to CI/CD Pipeline

```yaml
# .github/workflows/validate-data.yml
name: Validate Data Schemas

on:
  pull_request:
    paths:
      - 'src/data/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Install AJV
        run: npm install -g ajv-cli
      
      - name: Validate metadata
        run: ajv -s schemas/metadata.schema.json -d src/data/metadata.json
      
      - name: Validate user profiles
        run: ajv -s schemas/user-profile.schema.json -d src/data/users/*.json
```

## Schema Evolution

When updating schemas:

1. **Version changes** - Increment version in schema metadata
2. **Breaking changes** - Update major version
3. **New fields** - Update minor version
4. **Bug fixes** - Update patch version

## References

- [JSON Schema Specification](https://json-schema.org/)
- [Understanding JSON Schema](https://json-schema.org/understanding-json-schema/)
- [AJV Validator](https://ajv.js.org/)

