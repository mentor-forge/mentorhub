# Solution Architecture

Product and local/cloud DEV diagrams live here. AWS platform architecture, CloudFormation templates, platform config, and deployment planning live in [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation).

Cloud DEV diagrams are **work in progress**. Use [ArchitectureDiagram.dev.guide.md](./ArchitectureDiagram.dev.guide.md) for the box-by-box finish guide. For AWS platform context, see the cloudformation [platform overview](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/README.md), [architecture review](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/ARCHITECTURE.md), and [platform config](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/config/aws-platform.yaml).

| Environment | Diagram | Status |
|---------------|---------|--------|
| Local | [ArchitectureDiagram.local.svg](./ArchitectureDiagram.local.svg) | Complete |
| Platform (accounts) | [InfrastructureDiagram.svg](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/InfrastructureDiagram.svg) | WIP |
| Cloud DEV | [ArchitectureDiagram.dev.svg](./ArchitectureDiagram.dev.svg) | WIP |
| Staging | *Not created* | Planned |
| Production | *Not created* | Planned |

## Local Dev Environment
![DrawIO Render](./ArchitectureDiagram.local.svg)

## Platform Infrastructure (Shared-Services + environments)
![DrawIO Render](https://github.com/mentor-forge/mentorhub_cloudformation/raw/main/docs/InfrastructureDiagram.svg)

## Cloud Dev Environment
![DrawIO Render](./ArchitectureDiagram.dev.svg)

## drawio plugin 
    Name: Draw.io Integration
    Id: hediet.vscode-drawio
    Description: This unofficial extension integrates Draw.io into VS Code.
    Version: 1.6.6
    Publisher: hediet
    VS Marketplace Link: https://marketplace.cursorapi.com/items/?itemName=hediet.vscode-drawio