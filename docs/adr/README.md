---
title: "Architecture Decision Records (ADRs)"
description: "Central index of Architecture Decision Records across all OSM Notes projects"
version: "1.0.0"
last_updated: "2026-01-26"
author: "AngocA"
tags:
  - "architecture"
  - "decisions"
  - "adr"
audience:
  - "developers"
  - "architects"
project: "OSM-Notes-Common"
status: "active"
---

# Architecture Decision Records (ADRs)

This document provides a central index of Architecture Decision Records (ADRs) across all OSM Notes ecosystem projects.

## What are ADRs?

Architecture Decision Records are documents that capture important architectural decisions made during the project. They help:

- **Track why decisions were made**: Understand the reasoning behind architectural choices
- **Understand context and alternatives**: See what options were considered and why they were rejected
- **Share knowledge**: Help team members understand the architecture
- **Avoid revisiting decisions**: Prevent re-discussing already-made decisions
- **Onboard new team members**: Provide context for architectural choices

## ADR Format

Each ADR follows this structure:

- **Status**: Proposed | Accepted | Rejected | Deprecated | Superseded
- **Context**: The issue motivating the decision
- **Decision**: The decision made
- **Consequences**: Positive and negative impacts
- **Alternatives Considered**: Other options that were evaluated

## Template

A common template is available at [Template.md](Template.md) for creating new ADRs.

## ADRs by Project

### OSM-Notes-Ingestion

[View ADRs](https://github.com/OSM-Notes/OSM-Notes-Ingestion/tree/main/docs/adr)

- **Status**: 4 ADRs documented
- **Key Decisions**: 
  - ADR-0001: Record Architecture Decisions
  - ADR-0002: Use PostgreSQL with PostGIS
  - ADR-0003: Use Bash for Processing Scripts
  - ADR-0004: Use Git Submodule for Common Libraries

### OSM-Notes-Analytics

[View ADRs](https://github.com/OSM-Notes/OSM-Notes-Analytics/tree/main/docs/adr)

- **Status**: 4 ADRs documented
- **Key Decisions**: 
  - ADR-0001: Record Architecture Decisions
  - ADR-0002: Use Star Schema Data Warehouse
  - ADR-0003: Use Partitioned Facts Table
  - ADR-0004: Use Bash for ETL Orchestration

### OSM-Notes-API

[View ADRs](https://github.com/OSM-Notes/OSM-Notes-API/tree/main/docs/adr)

- **Status**: 5 ADRs documented
- **Key Decisions**: 
  - ADR-0001: Record Architecture Decisions
  - ADR-0002: Use Node.js + Express
  - ADR-0003: Use Redis for Cache
  - ADR-0004: Hybrid OAuth Approach
  - ADR-0005: Restrictive Rate Limiting

### OSM-Notes-Viewer

[View ADRs](https://github.com/OSM-Notes/OSM-Notes-Viewer/tree/main/docs/adr)

- **Status**: 3 ADRs documented
- **Key Decisions**: 
  - ADR-0001: Record Architecture Decisions
  - ADR-0002: Use Static Web Application
  - ADR-0003: Consume JSON from Separate Repository

### OSM-Notes-WMS

[View ADRs](https://github.com/OSM-Notes/OSM-Notes-WMS/tree/main/docs/adr)

- **Status**: 3 ADRs documented
- **Key Decisions**: 
  - ADR-0001: Record Architecture Decisions
  - ADR-0002: Use GeoServer for WMS
  - ADR-0003: Use Same Database as Ingestion

### OSM-Notes-Monitoring

[View ADRs](https://github.com/OSM-Notes/OSM-Notes-Monitoring/tree/main/docs/adr)

- **Status**: 3 ADRs documented
- **Key Decisions**: 
  - ADR-0001: Record Architecture Decisions
  - ADR-0002: Centralized Monitoring Repository
  - ADR-0003: Use Bash for Monitoring Scripts

## Creating a New ADR

1. **Choose the project**: Determine which project the decision affects
2. **Use the template**: Copy `Template.md` from this repository or the project's `docs/adr/` directory
3. **Number the ADR**: Use the next sequential number (e.g., `0001`, `0002`)
4. **Name the file**: `XXXX_short_title.md` (e.g., `0001_use_postgresql.md`)
5. **Fill in the template**: Complete all sections
6. **Update README**: Add the new ADR to the project's ADR README
7. **Commit**: Use message format: `docs(adr): add ADR-XXXX for [decision]`

## Cross-Project Decisions

Some decisions affect multiple projects. In these cases:

- Create the ADR in the **primary project** affected
- Reference it from other affected projects
- Add cross-references in the ADR itself

## References

- [ADR GitHub](https://adr.github.io/) - ADR community and resources
- [Michael Nygard's Article](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions) - Original ADR concept
- [Nat Pryce's adr-tools](https://github.com/npryce/adr-tools) - Lightweight ADR toolset
