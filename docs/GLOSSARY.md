---
title: "Global Glossary of OSM Notes Ecosystem"
description: "Consistent definitions of terms used throughout the ecosystem"
version: "1.0.0"
last_updated: "2026-01-25"
author: "AngocA"
tags:
  - "glossary"
  - "definitions"
  - "ecosystem"
audience:
  - "all"
status: "active"
---

# Global Glossary of OSM Notes Ecosystem

This document provides consistent definitions of common terms used throughout the OSM Notes ecosystem.

---

## 📋 Index

- [Data Warehouse](#data-warehouse)
- [ETL](#etl)
- [Datamart](#datamart)
- [Star Schema](#star-schema)
- [Fact Table](#fact-table)
- [Dimension Table](#dimension-table)
- [WMS](#wms)
- [Planet Dump](#planet-dump)
- [API Sync](#api-sync)
- [Submodule](#submodule)
- [GitHub Pages](#github-pages)
- [Other Terms](#other-terms)

---

## Data Warehouse

**Also known as:** DWH, Data Warehouse

**Definition:** Database optimized for analysis and analytical queries. In the OSM Notes ecosystem, the data warehouse is in the `dwh` schema of the PostgreSQL database.

**Characteristics:**
- Star schema
- Fact and dimension tables
- Optimized for analytical queries
- Pre-computed datamarts

**Location:** `OSM-Notes-Analytics` - `dwh` schema in PostgreSQL

**Example:**
```sql
-- Access the data warehouse
SELECT * FROM dwh.facts LIMIT 10;
```

**References:**
- [OSM-Notes-Analytics DWH Documentation](https://github.com/OSM-Notes/OSM-Notes-Analytics/blob/main/docs/DWH_Star_Schema_ERD.md)

---

## ETL

**Also known as:** Extract, Transform, Load

**Definition:** Process of extracting, transforming, and loading data. In OSM Notes, the ETL process transforms data from base tables (from Ingestion) to the data warehouse.

**Stages:**
1. **Extract:** Reads data from base tables (`notes`, `note_comments`, etc.)
2. **Transform:** Applies transformations and creates star schema
3. **Load:** Loads data into fact and dimension tables

**Location:** `OSM-Notes-Analytics` - Script `bin/dwh/ETL.sh`

**Example:**
```bash
# Run ETL
cd OSM-Notes-Analytics
./bin/dwh/ETL.sh
```

**References:**
- [ETL Enhanced Features](https://github.com/OSM-Notes/OSM-Notes-Analytics/blob/main/docs/ETL_Enhanced_Features.md)

---

## Datamart

**Also known as:** Data Mart, Datamart

**Definition:** Pre-computed tables with aggregated metrics for fast access. In OSM Notes there are three main datamarts:
- `datamartCountries`: 77+ metrics per country
- `datamartUsers`: 78+ metrics per user
- `datamartGlobal`: Global metrics

**Characteristics:**
- Pre-computed (not calculated in real-time)
- Optimized for fast queries
- Automatically updated during ETL

**Location:** `OSM-Notes-Analytics` - `dwh` schema

**Example:**
```sql
-- Query country datamart
SELECT country_name_en, history_whole_open, history_whole_closed
FROM dwh.datamartcountries
ORDER BY history_whole_open DESC
LIMIT 10;
```

**References:**
- [Metric Definitions](https://github.com/OSM-Notes/OSM-Notes-Analytics/blob/main/docs/Metric_Definitions.md)

---

## Star Schema

**Also known as:** Star Schema

**Definition:** Dimensional data model where a central fact table is surrounded by dimension tables. The OSM Notes data warehouse uses this model.

**Structure:**
- **Central table:** `dwh.facts` (facts/events)
- **Dimensions:** `dimension_users`, `dimension_countries`, `dimension_days`, etc.

**Advantages:**
- Fast queries
- Easy to understand
- Optimized for analysis

**Location:** `OSM-Notes-Analytics` - `dwh` schema

**References:**
- [DWH Star Schema ERD](https://github.com/OSM-Notes/OSM-Notes-Analytics/blob/main/docs/DWH_Star_Schema_ERD.md)

---

## Fact Table

**Also known as:** Facts Table

**Definition:** Central table in a star schema that contains events or transactions. In OSM Notes, the `dwh.facts` table contains each action on a note (creation, comment, closure, etc.).

**Characteristics:**
- Contains measurable metrics (counts, dates)
- Related to dimensions via foreign keys
- Partitioned by year for optimization

**Location:** `OSM-Notes-Analytics` - `dwh.facts`

**Example:**
```sql
-- Query facts
SELECT COUNT(*) 
FROM dwh.facts 
WHERE action_at >= '2025-01-01';
```

---

## Dimension Table

**Also known as:** Dimension Table

**Definition:** Tables that contain descriptive attributes. In OSM Notes there are multiple dimension tables: users, countries, dates, applications, etc.

**Examples in OSM Notes:**
- `dimension_users`: User information
- `dimension_countries`: Country information
- `dimension_days`: Date attributes
- `dimension_applications`: Applications used

**Location:** `OSM-Notes-Analytics` - `dwh` schema

---

## WMS

**Also known as:** Web Map Service

**Definition:** OGC standard for serving georeferenced maps. OSM-Notes-WMS provides WMS layers that show note locations in mapping applications like JOSM or Vespucci.

**Characteristics:**
- OGC WMS 1.3.0 standard
- Differentiated layers (open/closed notes)
- Accessible from mapping applications

**Location:** `OSM-Notes-WMS`

**Example URL:**
```
https://geoserver.osm.lat/geoserver/osm_notes/wms
```

**References:**
- [WMS User Guide](https://github.com/OSM-Notes/OSM-Notes-WMS/blob/main/docs/WMS_User_Guide.md)

---

## Planet Dump

**Also known as:** Planet File, Planet Dump

**Definition:** Daily XML file containing all OpenStreetMap notes. OSM-Notes-Ingestion downloads this file for initial load and synchronization.

**Characteristics:**
- Published daily
- XML format
- Contains all notes and comments
- Size: several hundred MB compressed

**Location:** `planet.openstreetmap.org`

**Usage in OSM Notes:**
- Initial load of historical data
- Synchronization when there are many changes

**References:**
- [Process Planet Documentation](https://github.com/OSM-Notes/OSM-Notes-Ingestion/blob/main/docs/Process_Planet.md)

---

## API Sync

**Also known as:** API Synchronization

**Definition:** Real-time synchronization process using OSM API. OSM-Notes-Ingestion queries the API periodically to get new or modified notes.

**Characteristics:**
- Incremental synchronization
- Low latency (30-60 seconds with daemon)
- Uses OSM API 0.6

**Location:** `OSM-Notes-Ingestion` - Script `bin/process/processAPINotes.sh`

**Frecuencia:**
- Daemon mode: Every minute
- Cron mode: Every 15 minutes

**References:**
- [Process API Documentation](https://github.com/OSM-Notes/OSM-Notes-Ingestion/blob/main/docs/Process_API.md)

---

## Submodule

**Also known as:** Git Submodule

**Definition:** Git repository included within another repository. OSM-Notes-Common is used as a submodule in several ecosystem projects.

**Projects that use Common as submodule:**
- OSM-Notes-Ingestion
- OSM-Notes-Analytics
- OSM-Notes-WMS
- OSM-Notes-Monitoring

**Location in projects:** `lib/osm-common/`

**Initialize submodule:**
```bash
git submodule update --init --recursive
```

---

## GitHub Pages

**Also known as:** GitHub Pages, Pages

**Definition:** GitHub's static hosting service. OSM-Notes-Data uses GitHub Pages to serve JSON files publicly.

**Characteristics:**
- Free hosting
- CDN included
- Public access
- Automatic update with push

**Example URLs:**
- Data: `https://osm-notes.github.io/OSM-Notes-Data/`
- Viewer: `https://osm-Notes.github.io/OSM-Notes-Viewer/`

**Location:** `OSM-Notes-Data`, `OSM-Notes-Viewer`

---

## Other Terms

### Base Project
**Definition:** Base project of the ecosystem. OSM-Notes-Ingestion is the base project because it was the first created and provides the database for other projects.

### Base Tables
**Definition:** Tables in PostgreSQL `public` schema populated by OSM-Notes-Ingestion. Include: `notes`, `note_comments`, `users`, `countries`.

### JSON Export
**Definition:** Process of exporting datamarts to JSON files. Performed by OSM-Notes-Analytics and published in OSM-Notes-Data.

### Rate Limiting
**Definition:** Request limitation to prevent abuse. Implemented in OSM-Notes-API and OSM-Notes-Monitoring.

### Monitoring
**Definition:** Centralized monitoring system that observes all ecosystem components. Provided by OSM-Notes-Monitoring.

---

## 🔗 Cross References

- [OSM Notes Ecosystem Landing Page](https://github.com/OSM-Notes/OSM-Notes)
- [Data Flow Documentation](./DATA_FLOW.md)
- [Installation Guide](./INSTALLATION.md)

---

**Last updated:** 2026-01-25  
**Maintained by:** OSM Notes Community
