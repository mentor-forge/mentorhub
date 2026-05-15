# Architecture Principles

## Microservice Architecture
We use a Microservices Architecture with services that are designed within **Bounded Domains**, implemented as **API Driven**, **Backend For Frontend** applications, using **Poly-Repo** Change Management automation. 

### Bounded Domains
Bounded domains are defined based on a User Centered view of the data and experiences supported by the system. Data domains are defined in data dictionaries. Service domains Control, Create, or Consume data within data domains. Controlled data domains can be managed by only one service, but any service can consume data from any domain or create immutable data in any domain.

### API Driven
A Service domain is implemented as an API Server that supports one browser based Single Page App. Open API Specifications document the contract between the API and SPA engineers. Following Backend for Frontend patterns, the purpose of the API is to make the SPA Engineers job easy.

### Poly Repo
We maintain a 1-to-1 relationship between a git repository and a deployable unit. Database configurations, API's, and SPA's are packaged as Docker Containers. Container images are then deployed to different environments. Shared code used across multiple API or SPA code bases are published to private dependency management libraries (npm /pypi). 

## Separation of Concerns

### Data Engineering
Responsible for data quality, query performance, and analytics. See [data standards](./data_standards.md) for details. 

### API Engineering
Responsible for Restful API Services within a Service Domain. This code is responsible for Business logic and Bearer Token RBAC. See [API Standards](./api_standards.md) for details.

### UI Engineering
Responsible for Human Interaction, backed by a single API, secured by commercial Authentication and Authorization Services. See [SPA Standards](./spa_standards.md) for details.

### Site Reliability Engineering
Responsible for the developer experience, continuous integration/deployment of new code, and service management in the different runtime environments. See [SRE Standards](./sre_standards.md) for details.