# Agile Learning Institute Mentor Hub

## Big Idea
A platform to connect mentors with engineers engaged in a life long learning journey.

## Development Team 
- TBD
- TBD

## Design Specifications
- [Product Description](./Specifications/product.yaml) 
- [Stakeholders](./Specifications/stakeholders.yaml)
- [Product Roadmap](./Specifications/roadmap.yaml)
- [Data Catalog](./Specifications/catalog.yaml)
- [Architecture Diagram](./Specifications/architecture_diagram.md)
- [Architecture Data](./Specifications/architecture.yaml)

## Contributing Guides
- [Developer Onboarding](./CONTRIBUTING.md) On-Boarding Process and CLI install
- [Architecture Principles](./DeveloperEdition/standards/ArchitecturePrinciples.md)
- [Data Standards](./DeveloperEdition/standards/data_standards.md)
- [API Standards](./DeveloperEdition/standards/api_standards.md)
- [UI Standards](./DeveloperEdition/standards/spa_standards.md)
- [SRE Standards](./DeveloperEdition/standards/sre_standards.md)
- [Onboarding Tour](./DeveloperEdition/standards/system_tour.md)

## Post-Launch TODOs
- Refine data structures using the Schema Configurator
- Propagate those data structure changes through API and SPA Code
- Customize SPA's to provide a more desirable user journey

- Implement a cloud container, npm, and pypi package management approach.
    - Implement Cloud provider specific registry services
    - Container Registry Service like ECR
    - Pypi/npm Package managers like CodeArtifact
    - Update(add) all CI to publish to Cloud registries
    - Update Developer CLI and docker-compose to use Cloud registries
    - Update all (package.json, Pipfile, Makefile) to use Cloud registries
    - Remove legacy CI and GitHub Packages
    
- Cloud Deployment
    - Secure a domain
    - Provision Identity Provider Services like Cognito
    - Provision MongoDB Backing Services
    - Provision Container Runtime
    - Provision Networking
    - Provision and Configure API Gateway