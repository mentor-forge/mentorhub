# Mentor Forge Mentor Hub

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

## Roadmap — Cloud Dev (Now / Next / Later)

**Goal:** MentorHub deployed and reachable in **AWS MentorHub-Dev** (sign-in + at least one journey end-to-end).

We use a lightweight **Now → Next → Later** rhythm — one feature at a time, promoted when shipped. **Now** is automated via task files in [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation/tree/main/tasks) and [Tasks](./Tasks/README.md).

| | Feature |
|---|---------|
| **Now** | ECR provisioning + GHCR ↔ ECR dual-push ([R030](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/RUNNING.R030.ecr_ghcr_connection.md)) |
| **Next** | Dev infrastructure (VPC, DocumentDB, ECS, edge) → coordinator pilot → CI/CD → all journeys |
| **Later** | Test envs in Dev account · staging · production |

Full map (current state → live Dev): **[Specifications/CloudDevRoadmap.md](./Specifications/CloudDevRoadmap.md)**

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
