# Mentor Forge Mentor Hub

## Big Idea
A cloud-based platform to connect mentors with engineers engaged in a life long learning journey.

## Quick Start (for non Contributors)
If you have [Docker Desktop](https://docs.docker.com/get-started/get-docker/) installed, you can simply run these commands in a terminal window.
```
cd ~/ &&
mkdir -p mentorhub &&
cd mentorhub &&
docker compose --profile all down || true &&
rm ./docker-compose.yaml || true &&
URL=https://raw.githubusercontent.com/mentor-forge/mentorhub/refs/heads/main &&
curl $URL/DeveloperEdition/docker-compose.yaml > docker-compose.yaml &&
docker compose --profile all pull &&
docker compose --profile all up --detach &&
open -a Safari "http://localhost:8080" || open -a 'Google Chrome' 'http://localhost:8080'
```
Then visit http://localhost:8080

## Development Team 
- Mary Anderson: Data Engineering
- Jillian Pennewell: Intern
- Candice Beasley: Intern
- Ashley Carroll: Intern

## Additional Contributors
- Daniel Dissler: SPA Engineer
- Luther (Luke) Still: SRE
- Curtis (Lucky) Minyard: API Engineer

## Design Specifications
- [Product Description](./Specifications/product.yaml) 
- [Stakeholders](./Specifications/stakeholders.yaml)
- [Data Catalog](./Specifications/catalog.yaml)
- [Architecture Diagram](./Specifications/ArchitectureDiagram.md)
- [Product Architecture Data](./Specifications/architecture.yaml)

## Contributing Guides
- [Developer Onboarding](./CONTRIBUTING.md) On-Boarding Process and CLI install (GitHub token + **CodeArtifact** via `make aws-setup`)
- **AWS infrastructure (SRE):** [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) — platform overview, architecture rationale, CloudFormation, platform config, IaC tasks
- [Architecture Principles](./DeveloperEdition/standards/ArchitecturePrinciples.md)
- [Data Standards](./DeveloperEdition/standards/data_standards.md)
- [API Standards](./DeveloperEdition/standards/api_standards.md)
- [UI Standards](./DeveloperEdition/standards/spa_standards.md)
- [SRE Standards](./DeveloperEdition/standards/sre_standards.md)
- [Onboarding Tour](./DeveloperEdition/standards/system_tour.md)
