# Mentor Forge Mentor Hub

## Big Idea
A cloud-based platform to connect mentors with engineers engaged in a life long learning journey.

## Quick Start (for non Contributors)
See the instructions on the [Organization Page](https://github.com/mentor-forge#quick-start)

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
- [Developer Onboarding](./CONTRIBUTING.md) Set up the CLI and access GitHub-hosted packages and images.
- [Architecture Principles](./DeveloperEdition/standards/ArchitecturePrinciples.md)
- [Data Standards](./DeveloperEdition/standards/data_standards.md)
- [API Standards](./DeveloperEdition/standards/api_standards.md)
- [UI Standards](./DeveloperEdition/standards/spa_standards.md)
- [SRE Standards](./DeveloperEdition/standards/sre_standards.md)
- [AWS infrastructure](https://github.com/mentor-forge/mentorhub_cloudformation)
- [Onboarding Tour](./DeveloperEdition/standards/system_tour.md) 

## Welcome container base updates

The Welcome image uses Nginx 1.30.7 on Alpine. For the next update, check the
[stable release](https://nginx.org/en/download.html) and
[security advisories](https://nginx.org/en/security_advisories.html). Inspect
the official Alpine tag with `docker buildx imagetools inspect` and update
the Dockerfile with its version and multi-platform index digest.

Run `make test` and `make container`. Build both published architectures
locally and verify each image with `nginx -v`, `nginx -V`, and a current
image scan. Start Developer Edition with the local Welcome image and check
the landing page, login assets, and journey redirects and API routes.
After merge, verify the published multi-platform digest and binaries.
Promote that same application digest through test, staging, and production.
