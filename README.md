# Mentor Forge Mentor Hub

## Current State

**Pre-release.** Backward compatibility is not required. Limit version changes to internal `api_utils` and `spa_utils` dependencies — features may be added, changed, or removed without notice.

**Test local, harvest global:** develop and validate here first; promote reusable API services and SPA components into shared utils when they are stable.

**Platform / cloud Dev:** [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) — roadmap and IaC tasks live there, not in this repo.

## Big Idea
A platform to connect mentors with engineers engaged in a life long learning journey.

## Quick Start (for non Contributors)
- Install [Docker Desktop](https://docs.docker.com/get-started/introduction/get-docker-desktop/)
- Download [docker-compose.yaml](./DeveloperEdition/docker-compose.yaml)
- Run the command ``docker compose --profile=all up -d``
- Visit [http://localhost:8080](http://localhost:8080)
- To Shutdown (all data lost) ``docker compose --profile=all down``
NOTE: Uses ports: 8080, 27017, 8383-8394

## Development Team 
- Daniel Dissler: Primary SPA Engineering, Secondary SPA Engineering
- Mary Anderson: Primary Data Engineering, Secondary SPA Engineering
- Luther (Luke) Still: Primary SRE Engineering, Secondary API Engineering
- Curtis (Lucky) Minyard: Primary API Engineering, Secondary SRE Engineering

## Design Specifications
- [Product Description](./Specifications/product.yaml) 
- [Stakeholders](./Specifications/stakeholders.yaml)
- [Product Roadmap](./Specifications/roadmap.yaml)
- [Data Catalog](./Specifications/catalog.yaml)
- [Architecture Diagram](./Specifications/architecture_diagram.md)
- [Architecture Data](./Specifications/architecture.yaml)

## Contributing Guides
- [Developer Onboarding](./CONTRIBUTING.md) On-Boarding Process and CLI install (GitHub token + **CodeArtifact** via `make aws-setup`)
- **AWS infrastructure (SRE):** [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) — CloudFormation, platform specs, IaC tasks
- [Architecture Principles](./DeveloperEdition/standards/ArchitecturePrinciples.md)
- [Data Standards](./DeveloperEdition/standards/data_standards.md)
- [API Standards](./DeveloperEdition/standards/api_standards.md)
- [UI Standards](./DeveloperEdition/standards/spa_standards.md)
- [SRE Standards](./DeveloperEdition/standards/sre_standards.md)
- [Onboarding Tour](./DeveloperEdition/standards/system_tour.md)
