# Mentor journey

## SPA Features 
Before executing tasks, you should make sure the backing services are running with ``npm run api``. Each feature prompt should start with @mentions of the following context files, and identification of the API Endpoints used in the feature. 
- spa_standards.md
- repo README.md
- repo/tasks/README.md
- curl localhost:<port>/docs/openapi.yaml

- [x] Profiles List page (the dashboard), Medium, Depends on profile API features
- [x] Profile detail page, Medium, Depends on profile and mentee API features
- [x] Update navigation, Small, depends on nothing 
	- 🤖Prompt: Review Context and create a task to refactor the Navigation drawer as follows:
		- Dashboard (link to list profiles page)
		- Resources (link to list resources page)
		- Learning Paths (link to list paths page)
		- Encounter Plans (link to list plans page)
		- Admin (link to admin when role contains "admin")
		- Logout (redirect to idp login)
- [ ] Encounter detail page, Large, Depends on Encounter and Plan API features
	- 🤖 Prompt: Review @Context and create tasks that build a new Encounter detail page, and wire it to the "New" encounter button on the Profile Detail page. The new Encounter needs the mentor_id, mentee_id from the Profile detail page, and should prompt for the Plan to use. This is a rough outline of the page. Headings are show, `>` indicates a show/hide section
	```md
	# {Mentee} - {Date}
	> ## Profile
	- Profile Data, goals, interests, 
	- Journey Data, resources completed since last meeting, resources in Now (Read Only)
	- Mentor Notes from Mentee (editable)
	> ## Checklist (Copy of steps in a Plan)
	- [ ] List Item
	- [ ] List Item
	- [ ] List Item
	> ## Encounter
	- TLDR Once sentence summary
	> ## Summary
	- Large Markdown Editor
	- ## Transcript
	- Large Markdown Editor
	```	
- [X] Plan List page, Small, Depends on Plan API features
	- 🤖 Prompt: Review @Context and one task that builds a new Plan list page. Change to a card interface, show Plan Name and Description on the card, along with a count of steps in the plan. Add a "New" PLan button that prompts for a plan name and creates the plan and opens it in the Plan Detail page.
- [ ] Plan Detail page, Small, Depends on Plan API features
	- 🤖 Prompt: Review @Context and a set of tasks that build a simple Plan editor. A Plan is just a list of steps. There should be buttons to add a new item to the list and to delete an item from the list.
- [ ] Resource List page, Medium, Depends on Resource API features
	- 🤖 Prompt: Review @Context and create a list of tasks that adds advanced search options to the search feature that allow the user to search by full name, interests, technology, description key words. There should also be a "New" Resource button that prompts for the URL and creates the resource and opens the resource detail page.
- [ ] Resource Details page, Medium, Depends on Resource API features
	- 🤖 Prompt: Review @Context and create a list of tasks that update the Resource Detail page. The page should allow the mentor to update the resource. All of the resource data should be show, with a read only resource Aggregations section. There should be an Add To Path button on the resource.
- [ ] Path List page, Small, Depends on Path API features
	- 🤖 Prompt: Review @Context and a task that updates the Path List page to cards interface that shows name and description on the card. There should be a "New Path" button that prompts for a path name and opens the Path Detail page
- [ ] Path Detail Page, Large, Depends on Path, Resource, Aggregation API features
	- 🤖 Prompt: Review @Context and a set of tasks that build the Path Detail (edit) page. It should have show/hide toggles on Module and Topic sections (name, description). There should be add-delete buttons at all levels. The Resource Chooser dialog should be similar to the Resource List page. 

## API Features 
Before executing tasks, you should make sure the backing database services are running with ``pipenv run db``. All features should start by updating the @openapi.yaml specifications, then move to implement the specifications. Each feature prompt should start with @mentions of the following context files
- api_standards.md
- repo README.md
- repo/tasks/README.md
Tasks can get the latest JSON Schema with ``curl -X GET "http://localhost:8383/api/configurations/json_schema/{Collection}.yaml/latest/" -H "accept: application/json"``

- [x] Profile, Large, depend depends on Profile, Mentee, and Encounter data features
- [x] Mentee, Small, Depends on Mentee data features
- [ ] Plan, Small, Depends on Plan data features
	- 🤖 Prompt: Review @Context and create a task to update Plan endpoints to latest schema.
- [ ] Encounter, Small, depends on Encounter data features
	- 🤖 Prompt: Review @Context and create tasks to update Encounter end points. Get Encounters should Be deprecated, get profile addresses that need. POST Encounter should require Mentor/Mentee ID's and Plan ID and should populate the checklist from the plan. GET Encounter should require Mentor or Admin role. PATCH Encounter should require Admin, or Token User -> Profile_ID should match Mentor_ID
- [ ] Path, Small, Depends on path, Resource, and aggregation data features
	- 🤖 Prompt: Review @Context and create tasks to update Path endpoints. Get Paths should always return all paths, remove pagination and scroll support. GET Path should be just an openapi change. PATCH Path should require Mentor or Admin role
- [ ] Resource, Medium, Depends on Resource and aggregation data features
	- 🤖 Prompt: Review @Context and create tasks to update Resource endpoints. GET Resources should have minimal changes to support advanced search and existing scroll. GET Resource should include Aggregation and Notes data. POST/PATCH should require role of mentor or admin.
- [ ] Aggregation, Large, Depends on Aggregation data features
	- 🤖 Prompt: Review @Context and create tasks to create GET Aggregation/{resource_id} endpoint. This endpoint should return the Aggregation data, as well as the Notes about the resource. 

# Mentee Journey

## SPA Features
Before executing tasks, you should make sure the backing services are running with ``npm run api``. Each feature prompt should start with @mentions of the following context files
- spa_standards.md
- repo README.md
- repo/tasks/README.md
- curl localhost:<port>/docs/openapi.yaml

- [ ] Update Navigation, Small, depends on nothing
	- 🤖 Prompt: Review @Context and create a tasks that implements an updated navigation drawer. It should have only the following items: 
		- Journey - journeyEditPage (default)
		- Paths - paths list page (cards)
		- Resources - resources list with search
		- Admin - Only visible when role contains admin
- [ ] Journey Detail page view, X-Large, depends on Journey, Aggregation API
	- 🤖 Prompt: Review @Context and create a tasks that build a Journey detail page. This is a rough outline of the page. Headings are show, `>` indicates a show/hide section
	```md
	# {Mentee Name} - {Date}
	> ## Library
		- List of completed resources. 
		- Link can be followed (should POST Event)
		- Note can be added (api will create Event)
	> ## Now
		- List of current resources
		- Button to Start (changes to link when started, POST event started, and linked)
		- Button to Finish (prompts for rating (required) and Notes (optional) and moves resource to Library)
	> ## Next
		- Module/Topic/Resource list with Resource Name
		- Resource has a click to get Aggregations that shows aggregations in-line
		- Resource has a link to open the Resource Detail page
		- Has a task level promote button that move the task to Now
	> ## Later
		- List of Paths that may be added to Next
		- Has a Path level "Promote" button that moves the Path into Next
	```
- [ ] Resource List page, Large, depends on Resource API
	- 🤖 Prompt: Review @Context and create a list of tasks that adds advanced search options to the search feature that allow the user to search by name, interests, technology, description key words
- [ ] Resource Detail page, Medium, Depends on Resource API
	- 🤖 Prompt: Review @Context and create a list of tasks that update the viewResource page. The page should a read-only display of the updated Resource data, with a show/hide click to get aggregations. There should be an "Add to Now" button to add the resource to the mentees journey.
- [ ] Path List page, Small, Depends on nothing
	- 🤖 Prompt: Review @Context and create a task that Refactors the List Paths page to be a cards based page. 
- [ ] Path Detail page, Small, Depend depends on Path and Aggregations API
	- 🤖 Prompt: Review @Context and create a list of tasks that implement the View Path page with the following functionality. An outline with show-hide sections of Modules -> Topics -> Resources that shows just resource name, with a click to expand button that then shows some resource information, and aggregation data. There should be a way to open a resource details page, and add buttons for Modules, Topics, and Resources. Adding a resource should prompt for a url, create a new resource, and then open the Resource details page.

## API features
Before executing tasks, you should make sure the backing database services are running with ``pipenv run db``. All features should start by updating the @openapi.yaml specifications, then move to implement the specifications. Each feature prompt should start with @mentions of the following context files
- api_standards.md
- repo README.md
- repo/tasks/README.md
Tasks can get the latest JSON Schema with ``curl -X GET "http://localhost:8383/api/configurations/json_schema/{Collection}.yaml/latest/" -H "accept: application/json"``

- [ ] utils, Small, depends on events schema update
	- 🤖 Prompt: Review @Context and create two tasks that Update the config to include new Resource_Aggregations collection name with the default value of "Resource_Aggregation", and then add more constants to the config object to represent the Event Type values from the event_types from @enumerations.0.yaml. 
- [ ] Aggregation, Medium, depends on utils and aggregation data
	- 🤖 Prompt: Review @Context and create a task to add a GET aggregation/{resource_id} endpoint with an aggregation service that invokes a Notes service to get related notes that are added to the return value.
- [ ] Events, Small, depend depends on utils and event data
	- 🤖 Prompt: Review @Context and update the POST /event schema. 
- [ ] Journey, X-Large, depends on utils and all data updates
	- 🤖 Prompt: Review @Context and Create a series of tasks to implement the following endpoint changes:	
		- GET journey defaults to token owners journey (get Profile, get Journey). The endpoint should create a document if one does not exist using the template Journey $oid()"000000000000000000000001")
		- Implement PATCH journey RBAC - requires ownership
		- Implement PATCH journey/advance/<url> that is used to move resources from from next to now. Successful execution should also create an advance event.
		- Implement PATCH journey/complete/<url> endpoint to record a rating, add notes if provided as well as moving the resource to the library. Successful execution should creates the appropriate events. 
		- Remove GET journeys as no list-journeys page will exist.
- [ ] Paths, Medium, depends on utils and path, resource, and aggregation data
	- 🤖 Prompt: Review @Context and create two tasks that Update the GET Paths to returns all paths sorted by name. Remove pagination and scrolling support. Then update the GET Path endpoint to include minimal Resource data (name, description). Start by updating the @openapi.yaml specifications, then move to implement the specifications. 
- [ ] Resources, Medium, depends on utils and resource, notes, and aggregation data features
	- 🤖 Prompt: Review @Context and create a task to Update the GET resource by id endpoint to add aggregation, and notes data to the reply. 

# Data features
- [x] Profile
	- [x] 👤 Schema audit
	- [x] 👤 Index audit
	- [x] 🤖 Test Data
- [x] Mentee
	- [x] 👤 Schema audit
	- [x] 👤 Index audit
	- [x] 🤖 Test Data
- [x] Encounter, Small, depends on Plan and Profile
	- [x] 👤 Schema audit
	- [x] 👤 Index audit
	- [x] 🤖 Prompt: Create a task to replace the existing Encounter test data from the Obsidian markdown files from Mikes Encounter collection for the team.
- [X] Plan, Small, depends on nothing
	- [x] 👤 Schema audit
	- [x] 👤 Index audit
	- [x] 👤 Create test data for two Plan's - Mikes normal plan, and a first encounter plan.
- [X] Path, Small, depends on nothing
	- [x] 👤 Schema audit
	- [x] 👤 Index audit
- [X] Resource, Large, depends on Path
	- [x] 👤 Updates to resource schema (cost, level, .....) 
	- [x] 👤 Index audit
	- [X] 🤖 Prompt: Create tasks to delete existing Path and Resource test data, and then import Paths/Topics from Mikes Obsidian vault. Then add some Course and Membership resources for Real Python, Cantrill.io, MTC (More than Certified) - and a Path for "Practitioner SRE" with these resources. Also create a "Practitioner UI/UX Engineer" path with Vue Mastery and other appropriate resources.
	- [x] 👤 Audit Enums -types, cost - add meaningful skills, technology, interests
- [ ] Journey, Medium, depends on Path, Resource
	- [x] 👤 Schema audit 
	- [x] 👤 Index Audit
	- [ ] 🤖 Prompt: Create tasks to Update existing test data based on new Path, Resource test data and Journey schema changes and to Create a Template for a new Journey -
		- oid of "000000000000000000000001" with no profile_id
		- Now - Agile Home
		- Next 
			- Introduction (t-shaped, specialities, expertness)
			- Mindset (Manifestos, EDT)
		- Later
			- Odin
			- EK
- [ ] Event, Small, depends on Journey
	- [x] 👤 Schema audit
	- [x] 👤 Index audit
	- [ ] 🤖 Prompt: Create a series of events related to resource aggregation, driven by journey test data
- [ ] Rating, Small, depends on Journey, Resource, Profile
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create a series of Ratings based on Journey Completed tasks.
- [ ] Note, Small, depends on Journey, Resource, Profile
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create a series of Notes related to Journey test data, library resources
- [ ] Aggregation, Medium, depends on Resources, Notes, Ratings, and Events
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create tasks to build test data
- [ ] Customer
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create tasks to build test data
- [ ] Subscription
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create tasks to build test data
- [ ] Dashboard
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create tasks to build test data
- [ ] Card
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create tasks to build test data
- [ ] Identity
	- [ ] 👤 Schema audit
	- [ ] 👤 Index audit
	- [ ] 🤖 Prompt: Create tasks to build test data
