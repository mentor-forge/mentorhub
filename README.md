# Mentor Forge Mentor Hub

## Current State

**Pre-release.** Backward compatibility is not required. Limit version changes to internal `api_utils` and `spa_utils` dependencies — features may be added, changed, or removed without notice.

**Test local, harvest global:** develop and validate here first; promote reusable API services and SPA components into shared utils when they are stable.

**Platform / cloud Dev:** [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) — AWS architecture, CloudFormation templates, platform config, and IaC tasks live there, not in this repo.

## Big Idea
A platform to connect mentors with engineers engaged in a life long learning journey.

## Quick Start (for non Contributors)
- Install [Docker Desktop](https://docs.docker.com/get-started/introduction/get-docker-desktop/)
- Download [docker-compose.yaml](./DeveloperEdition/docker-compose.yaml)
- Run the command ``docker compose --profile=all up -d``
- **Portal (front door):** [http://localhost:8080](http://localhost:8080)
- **Sign in:** [http://localhost:8080/login.html](http://localhost:8080/login.html) — default post-login app is [http://localhost:8080/discovery/](http://localhost:8080/discovery/)
- To Shutdown (all data lost) ``docker compose --profile=all down``

NOTE: Uses ports **8080** (portal), **8081** (Stage0 Launch), **27017** (MongoDB), **8383–8398** (APIs/SPAs — e.g. Discovery API **8397**, Discovery SPA **8398**), **9229** (cognito-local), **1025/8025** (MailHog), **12111** (stripe-mock). Journey SPAs behind `/discovery/`, `/customer/`, `/admin/`, `/mentor/`, and `/mentee/` on **8080** share one origin and JWT `localStorage`; direct service ports remain for OpenAPI explorers, Cypress, and mock UIs.

## Development Team 
- Daniel Dissler: Primary SPA Engineering, Secondary SPA Engineering
- Mary Anderson: Primary Data Engineering, Secondary SPA Engineering
- Luther (Luke) Still: Primary SRE Engineering, Secondary API Engineering
- Curtis (Lucky) Minyard: Primary API Engineering, Secondary SRE Engineering

## Design Specifications
- [Product Description](./Specifications/product.yaml) 
- [Stakeholders](./Specifications/stakeholders.yaml)
- [Data Catalog](./Specifications/catalog.yaml)
- [Architecture Diagram](./Specifications/ArchitectureDiagram.md)
- [Product Architecture Data](./Specifications/architecture.yaml)
- [AWS Platform Architecture](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/ARCHITECTURE.md)

## Contributing Guides
- [Developer Onboarding](./CONTRIBUTING.md) On-Boarding Process and CLI install (GitHub token + **CodeArtifact** via `make aws-setup`)
- **AWS infrastructure (SRE):** [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) — platform overview, architecture rationale, CloudFormation, platform config, IaC tasks
- [Architecture Principles](./DeveloperEdition/standards/ArchitecturePrinciples.md)
- [Data Standards](./DeveloperEdition/standards/data_standards.md)
- [API Standards](./DeveloperEdition/standards/api_standards.md)
- [UI Standards](./DeveloperEdition/standards/spa_standards.md)
- [SRE Standards](./DeveloperEdition/standards/sre_standards.md)
- [Onboarding Tour](./DeveloperEdition/standards/system_tour.md)
