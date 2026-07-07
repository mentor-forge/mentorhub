# Specifications

Product and application specifications for Mentor Hub. YAML files here provide context for AI assistants and Stage0 merge utilities. See [Stage0 Specification Schemas](https://github.com/agile-learning-institute/stage0/tree/main/Schemas).

**Scope:** this folder owns product architecture: journeys, repositories, ports, data domains, stakeholders, catalog, and product diagrams.

**AWS platform architecture** (accounts, infrastructure services, tenancy, CI/CD, CloudFormation templates, and as-built values) lives in **[mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation)**:

- [Platform overview](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/README.md)
- [Architecture rationale and SA review](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/ARCHITECTURE.md)
- [Canonical platform config](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/config/aws-platform.yaml)

How authoritative `*.yaml` files get here after a merge is described in the [root README](../README.md#specifications-yaml-after-merge).
